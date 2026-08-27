import 'dart:convert';

import 'package:buzz/features/channels/gen_ui_demo/agent_llm_prompt.dart';
import 'package:buzz/features/channels/gen_ui_demo/agent_llm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A Responses payload carrying [text].
String _responseBody(String text) => jsonEncode({
  'status': 'completed',
  'output': [
    {
      'type': 'message',
      'content': [
        {'type': 'output_text', 'text': text},
      ],
    },
  ],
});

void main() {
  group('unfenceGenUi', () {
    test('rewrites a fenced block into the renderer markers', () {
      const fenced =
          'Before\n\n'
          '```genui\n{"agent_board": {"board": "b"}}\n```\n\n'
          'After';

      final out = unfenceGenUi(fenced);

      expect(out, contains('\u{E200}genui\u{E202}'));
      expect(out, contains('\u{E201}'));
      expect(out, contains('{"agent_board": {"board": "b"}}'));
      expect(out, isNot(contains('```')));
      expect(out, contains('Before'));
      expect(out, contains('After'));
    });

    test('handles more than one block in a reply', () {
      const fenced = '```genui\n{"a": {}}\n```\n\n```genui\n{"b": {}}\n```';

      expect(
        RegExp(r'\u{E200}', unicode: true).allMatches(unfenceGenUi(fenced)),
        hasLength(2),
      );
    });

    test('leaves ordinary code fences alone', () {
      // A model explaining Rust must still be able to show Rust.
      const text = '```rust\nfn main() {}\n```';

      expect(unfenceGenUi(text), text);
    });

    test('drops an empty block rather than emitting an empty directive', () {
      expect(unfenceGenUi('```genui\n\n```').trim(), isEmpty);
    });
  });

  group('AgentLlmService', () {
    test('sends the system prompt and returns unfenced text', () async {
      Map<String, dynamic>? sent;
      final service = AgentLlmService(
        apiKeyOverride: 'test-key',
        client: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            _responseBody('Hi\n\n```genui\n{"agent_board": {}}\n```'),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );

      final answer = await service.answer(question: 'status?');

      expect(sent?['instructions'], agentSystemPrompt);
      expect(answer, contains('\u{E200}genui\u{E202}'));
    });

    test('sends the key in the Authorization header', () async {
      // Regression: the header was built with an escaped `\$`, so every
      // request went out with the literal text "Bearer \$_key" and the API
      // answered 401. Asserting the request was made is not enough — the
      // header has to be read.
      String? auth;
      final service = AgentLlmService(
        apiKeyOverride: 'sk-secret',
        client: MockClient((request) async {
          auth = request.headers['Authorization'];
          return http.Response(_responseBody('ok'), 200);
        }),
      );

      await service.answer(question: 'status?');

      expect(auth, 'Bearer sk-secret');
      expect(auth, isNot(contains(r'$')));
    });

    test('carries history so a follow-up has something to follow', () async {
      Map<String, dynamic>? sent;
      final service = AgentLlmService(
        apiKeyOverride: 'test-key',
        client: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(_responseBody('ok'), 200);
        }),
      );

      await service.answer(
        question: 'what about the other one?',
        history: [
          (fromUser: true, text: 'why is CI red?'),
          (fromUser: false, text: 'one job is failing'),
        ],
      );

      final input = sent?['input'] as List<dynamic>;
      expect(input, hasLength(3));
      expect((input.first as Map)['role'], 'user');
      expect((input[1] as Map)['role'], 'assistant');
    });

    test(
      'returns null on an error status so the caller can fall back',
      () async {
        final service = AgentLlmService(
          client: MockClient((_) async => http.Response('{"error":{}}', 500)),
        );

        expect(await service.answer(question: 'status?'), isNull);
      },
    );

    test('returns null when the network fails', () async {
      // The likeliest failure on stage. It has to be quiet.
      final service = AgentLlmService(
        apiKeyOverride: 'test-key',
        client: MockClient((_) async => throw const SocketExceptionStub()),
      );

      expect(await service.answer(question: 'status?'), isNull);
    });

    test('is inert without a key, so the demo falls back to the script', () {
      expect(
        AgentLlmService.isConfigured,
        const String.fromEnvironment('OPENAI_API_KEY').isNotEmpty,
      );
    });
  });
}

/// Stands in for a socket failure without importing dart:io into a test that
/// otherwise does not need it.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
