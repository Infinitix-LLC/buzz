import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'agent_llm_prompt.dart';

/// Asks a model to answer as the demo agent.
///
/// The key is read with `String.fromEnvironment`, matching how the relay URL is
/// configured (`shared/relay/relay_provider.dart`). Supply it the way this repo
/// already supplies secrets:
///
/// ```bash
/// # .env.json — already gitignored
/// { "OPENAI_API_KEY": "sk-…" }
///
/// flutter run --dart-define-from-file=.env.json
/// ```
///
/// > A `--dart-define` value is compiled into the binary. It stays out of git
/// > and off anyone else's machine, which is what matters for a demo you run
/// > yourself, but it is not secret from someone holding the built app.
class AgentLlmService {
  AgentLlmService({http.Client? client, String? apiKeyOverride})
    : _client = client ?? http.Client(),
      _key = apiKeyOverride ?? apiKey;

  final http.Client _client;

  /// The key in use. Overridable so the fallback paths — the ones that decide
  /// whether the demo survives a bad network — can be tested without one.
  final String _key;

  static const apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const model = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-5.4',
  );

  /// Whether a live answer is possible at all.
  static bool get isConfigured => apiKey.isNotEmpty;

  /// Long enough for a considered answer, short enough that a stalled network
  /// falls back to the scripted reply before anyone in the room notices.
  static const _timeout = Duration(seconds: 12);

  /// Any endpoint speaking OpenAI's Responses API. Overridable so the same
  /// code can point at a proxy or a gateway rather than at OpenAI directly —
  /// which is also how the key stays off the device entirely, if you ever want
  /// that.
  static const baseUrl = String.fromEnvironment(
    'OPENAI_BASE_URL',
    defaultValue: 'https://api.openai.com/v1',
  );

  static Uri get _endpoint => Uri.parse('$baseUrl/responses');

  /// Answers [question], or returns null so the caller can fall back.
  ///
  /// Never throws. On stage the only acceptable failure is a quiet one: a
  /// scripted answer nobody can tell from a live one beats an error bubble.
  Future<String?> answer({
    required String question,
    List<({bool fromUser, String text})> history = const [],
    String? briefing,
  }) async {
    if (_key.isEmpty) {
      return null;
    }

    try {
      final response = await _client
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $_key',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              // The briefing is appended rather than sent as a turn: it is
              // not something anybody said, it is what the agent can see when
              // it looks up. Putting it in the conversation would have the
              // model reply to it.
              'instructions': briefing == null
                  ? agentSystemPrompt
                  : '$agentSystemPrompt\n\n$briefing',
              'input': [
                for (final turn in history)
                  {
                    'role': turn.fromUser ? 'user' : 'assistant',
                    'content': turn.text,
                  },
                {'role': 'user', 'content': question},
              ],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode >= 400) {
        debugPrint(
          '[AgentLlmService] ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final text = _outputText(jsonDecode(utf8.decode(response.bodyBytes)));
      if (text == null || text.trim().isEmpty) {
        return null;
      }
      return unfenceGenUi(text);
    } catch (error) {
      debugPrint('[AgentLlmService] $error');
      return null;
    }
  }

  /// Pulls the assistant text out of a Responses payload.
  ///
  /// There are no `choices` here: the response carries an `output` array of
  /// items, each with `content` parts, and the text lives on the parts typed
  /// `output_text`.
  static String? _outputText(Object? json) {
    if (json is! Map<String, dynamic>) {
      return null;
    }
    final output = json['output'];
    if (output is! List) {
      return null;
    }
    final buffer = StringBuffer();
    for (final item in output.whereType<Map<String, dynamic>>()) {
      final content = item['content'];
      if (content is! List) {
        continue;
      }
      for (final part in content.whereType<Map<String, dynamic>>()) {
        if (part['type'] == 'output_text') {
          buffer.write(part['text'] as String? ?? '');
        }
      }
    }
    return buffer.toString();
  }

  void dispose() => _client.close();
}

/// Rewrites ```genui fenced blocks into the private-use markers the renderer
/// scans for.
///
/// The model is asked for a fenced block rather than the markers themselves.
/// `\u{E200}` and friends are invisible private-use code points; a model asked
/// to emit them gets it wrong often enough to matter, and the failure is
/// silent — the directive renders as literal text. A fence is something models
/// produce reliably, and this converts it once, here.
String unfenceGenUi(String text) {
  final fence = RegExp(
    r'```genui\s*\n(.*?)\n?```',
    multiLine: true,
    dotAll: true,
  );
  return text.replaceAllMapped(fence, (match) {
    final payload = match.group(1)?.trim() ?? '';
    if (payload.isEmpty) {
      return '';
    }
    return '\u{E200}genui\u{E202}$payload\u{E201}';
  });
}
