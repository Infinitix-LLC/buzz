import 'dart:async';
import 'dart:math';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../shared/relay/relay.dart';
import '../channel_management_provider.dart';
import '../channel_messages_provider.dart';
import 'agent_llm_service.dart';
import 'demo_workspace_briefing.dart';
import 'gen_ui_demo_replies.dart';

/// Answers a question in a channel with a live gen-UI board.
///
/// This is a demo surface, and it is deliberately local: the reply is added
/// with `addLocalMessage`, the same path an optimistic outgoing message takes,
/// so nothing is signed, nothing is published, and no other member of the
/// community sees it. Turning the demo off is deleting this file and its one
/// call site.
///
/// What it is standing in for is an agent that answers with structured output
/// instead of prose. Everything downstream of the reply — parsing, rendering,
/// the live board — is the real path a real agent's message would take.
class GenUiDemoResponder {
  GenUiDemoResponder(this._ref);

  final Ref _ref;
  final AgentLlmService _llm = AgentLlmService();

  /// Set false to take the demo out of the send path without unwiring it.
  static const enabled = true;

  /// How long the agent appears to think before answering.
  ///
  /// An instant reply is the single clearest tell that a response was canned;
  /// no agent that has to go and look at something answers in zero
  /// milliseconds.
  static const _thinkingDelay = Duration(milliseconds: 1400);

  static final _random = Random();

  /// Answers anything worth answering.
  ///
  /// Not a keyword match: someone else will be driving this, and they will not
  /// use our words. Everything except bare acknowledgements goes to the model,
  /// and the keyword table only chooses which scripted answer to fall back to
  /// if the model cannot be reached.
  void maybeRespond(String channelId, String content) {
    if (!enabled) {
      return;
    }
    if (!isWorthAnswering(content)) {
      return;
    }
    unawaited(_answer(channelId, content, replyFor(content)));
  }

  /// Asks the model, and falls back to the scripted answer.
  ///
  /// The fallback is not a nicety. Venue wi-fi is the likeliest way this dies,
  /// and a scripted reply nobody can distinguish from a live one is infinitely
  /// better than an error in front of the person being shown the demo.
  Future<void> _answer(
    String channelId,
    String question,
    DemoReply scripted,
  ) async {
    final started = DateTime.now();
    final live = await _llm.answer(
      question: question,
      history: _recentTurns(channelId),
      // Read at answer time, so the agent describes the board as it is when it
      // replies rather than as it was when the question was asked.
      briefing: workspaceBriefing(),
    );

    // A model that answers in 300ms reads as canned even when it is not, so
    // hold the reply until it has been on screen long enough to have thought
    // about it. Real latency past that point is left alone — it is the most
    // convincing part of a live answer.
    final elapsed = DateTime.now().difference(started);
    final remaining = _thinkingDelay - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    await _respondWith(channelId, answerWithView(live, scripted));
  }

  /// The last few messages, so a follow-up like "what about the other one?"
  /// lands. Without history every question is the first question, which is the
  /// fastest way to break the feeling of talking to a teammate.
  List<({bool fromUser, String text})> _recentTurns(String channelId) {
    try {
      final messages =
          _ref.read(channelMessagesProvider(channelId)).asData?.value ??
          const [];
      final recent = messages.length <= _historyDepth
          ? messages
          : messages.sublist(messages.length - _historyDepth);
      return [
        for (final event in recent)
          if (event.content.trim().isNotEmpty)
            (
              fromUser: event.pubkey != _fallbackAgentPubkey,
              text: event.content,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static const _historyDepth = 8;

  Future<void> _respondWith(String channelId, String body) async {
    final pubkey = await _agentPubkey(channelId);

    final event = NostrEvent(
      id: _syntheticId(),
      pubkey: pubkey,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      kind: EventKind.streamMessage,
      tags: [
        ['h', channelId],
      ],
      content: body,
      // Never signed and never published — a local demo event only.
      sig: '',
    );

    _ref
        .read(channelMessagesProvider(channelId).notifier)
        .addLocalMessage(event);
  }

  /// Prefers a bot that is genuinely a member of this channel, so the reply
  /// carries a real agent's name and avatar rather than an unknown key.
  Future<String> _agentPubkey(String channelId) async {
    try {
      final members = await _ref.read(channelMembersProvider(channelId).future);
      for (final member in members) {
        if (member.isBot) {
          return member.pubkey;
        }
      }
    } catch (_) {
      // Membership is not worth failing the demo over.
    }
    return _fallbackAgentPubkey;
  }

  static String _syntheticId() {
    const hex = '0123456789abcdef';
    return List.generate(64, (_) => hex[_random.nextInt(16)]).join();
  }

  /// Used when the channel has no bot member to attribute the reply to.
  static const _fallbackAgentPubkey =
      'a9e0d17f5b3c4482a1f6e8d0c7b25931fe4406a8d2b7c1e5930af62d84c17b05';
}

final genUiDemoResponderProvider = Provider<GenUiDemoResponder>(
  GenUiDemoResponder.new,
);
