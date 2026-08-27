/// The scripted answers, and what each one is triggered by.
///
/// Kept apart from the send-path wiring so the content can be read and edited
/// without going near the plumbing — the wording is the part most likely to
/// change between one demo and the next.
library;

import 'package:gpt_markdown/gpt_markdown.dart'
    show genUiCloseMarker, genUiOpenMarker;

String _g(String payload) => '\u{E200}genui\u{E202}$payload\u{E201}';

const _board = 'release-cut';

/// One thing an agent can be asked, and how it answers.
class DemoReply {
  const DemoReply({
    required this.name,
    required this.triggers,
    required this.body,
  });

  final String name;

  /// Substrings that select this answer. Matched against a lower-cased message.
  final List<String> triggers;

  final String body;

  /// Just the directives from [body], with the prose stripped.
  ///
  /// Used to give a live answer a view when the model returned prose alone.
  String get view => RegExp(
    '$genUiOpenMarker.*?$genUiCloseMarker',
    dotAll: true,
  ).allMatches(body).map((m) => m.group(0)).join('\n\n');
}

/// Ordered most specific first: "are we ready to ship?" mentions the release
/// *and* reads like a status question, and the checklist is the better answer.
/// A question that matches nothing falls through to the board.
final demoReplies = <DemoReply>[
  DemoReply(
    name: 'code review',
    triggers: const [
      'review',
      'patch',
      'diff',
      'typing',
      'pr',
      'changed',
      'approve',
    ],
    body:
        '''
scout finished reviewing patch's typing fix. Two notes, neither blocking.

${_g('{"code_review": {"board": "$_board", "task": "relay-typing"}}')}

Your call — approving takes it into the release cut.''',
  ),
  DemoReply(
    name: 'ci run',
    triggers: const [
      'ci',
      'build',
      'red',
      'failing',
      'flaky',
      'flake',
      'broken',
      'tests',
    ],
    body:
        '''
One job is red. sentry is already on it.

${_g('{"ci_run": {"board": "$_board", "run": "4812"}}')}

It's the rejoin race on reconnect — 2 of the last 20 runs, so a flake rather than a break. sentry has reproduced it and the fix is in review.''',
  ),
  DemoReply(
    name: 'release readiness',
    triggers: const [
      'ship',
      'release',
      'ready',
      '0.6',
      'cut',
      'launch',
      'go live',
    ],
    body:
        '''
Not yet — one blocker, and two gates still moving.

${_g('{"release_readiness": {"board": "$_board", "version": "0.6.0"}}')}

The NIP-42 scope question is the only one that needs a person. The rest land on their own.''',
  ),
  DemoReply(
    name: 'nip42 animation',
    triggers: const [
      'nip-42',
      'nip42',
      'handshake',
      'authenticate',
      'authentication',
      'auth flow',
      'how does auth',
      'sign in',
    ],
    body:
        '''
Easier to watch than to read.

${_g('{"val_scene": {"name": "How Buzz knows it is really you", "frame": "landscape"}}')}

It runs on the device — the script ships in the app and the engine draws every frame here.''',
  ),
  DemoReply(
    name: 'agent board',
    triggers: const [
      'working on',
      'going on',
      'status',
      'progress',
      'board',
      'tasks',
      'where are we',
      'update',
      'standup',
      'stand-up',
      'blocked',
      'everyone',
      'doing',
    ],
    body:
        '''
Here's where the release cut stands right now.

${_g('{"agent_board": {"board": "$_board", "title": "Release cut · 0.6.0"}}')}

${_g('{"agent_progress": {"board": "$_board"}}')}

Everything is moving except **NIP-42 scope check on channel join** — scout needs a decision on whether private channels re-verify scope per join.''',
  ),
];

/// Whether [text] contains [trigger] as a word rather than as a fragment.
///
/// A bare `contains` is what makes short triggers dangerous: "ci" appears
/// inside "decision" and "specific", so "what's the decision?" would have been
/// answered with a CI run. Word boundaries keep the short triggers usable
/// without hand-tuning every one of them.
bool _mentions(String text, String trigger) {
  final pattern = RegExp(
    r'(?<![a-z0-9])' + RegExp.escape(trigger.trim()) + r'(?![a-z0-9])',
  );
  return pattern.hasMatch(text);
}

/// The scripted answer that best fits [message].
///
/// Never null for anything worth answering: an unmatched message falls through
/// to the board, which is a reasonable reply to almost any question about the
/// workspace. Matching only picks *which* scripted answer to fall back to when
/// the model is unavailable — it no longer decides *whether* to answer.
DemoReply replyFor(String message) {
  final text = message.toLowerCase().trim();
  for (final reply in demoReplies) {
    if (reply.triggers.any((t) => _mentions(text, t))) {
      return reply;
    }
  }
  return demoReplies.last;
}

/// Whether [message] is worth answering at all.
///
/// Deliberately almost everything. An earlier version required a trigger word
/// or a question mark, and measured against questions nobody had scripted it
/// dropped 15 of 18 — "summarise the week", "explain the blocker to me",
/// "hows it going" all got silence. The model answered every one of them well
/// when it was actually asked. A demo someone else drives cannot have a
/// keyword gate in front of it.
///
/// What is left out is only what would make the agent look broken: bare
/// acknowledgements, and reactions with no words in them.
bool isWorthAnswering(String message) {
  final text = message.trim();
  if (text.length < 2) {
    return false;
  }
  const acknowledgements = {
    'ok',
    'okay',
    'k',
    'kk',
    'yes',
    'no',
    'yep',
    'nope',
    'sure',
    'thanks',
    'thank you',
    'ty',
    'thx',
    'cool',
    'nice',
    'great',
    'lol',
    'haha',
    'hmm',
    'got it',
    'gotcha',
    'sounds good',
    'agreed',
    '+1',
    'done',
    'np',
  };
  final normalised = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 +]'), '');
  if (acknowledgements.contains(normalised)) {
    return false;
  }
  // Emoji-only or punctuation-only messages carry no question.
  return RegExp(r'[a-z0-9]', caseSensitive: false).hasMatch(text);
}

/// The reply to post, given what the model returned and the routed fallback.
///
/// Guarantees a view. The model draws one for essentially every workspace
/// question — measured at 20 of 22 against questions nobody had scripted — but
/// "essentially" is not a property to discover in front of someone. A live
/// answer that comes back as prose alone keeps its wording and gains the
/// routed view; an answer that never arrived falls back to the script whole.
String answerWithView(String? live, DemoReply scripted) {
  if (live == null || live.trim().isEmpty) {
    return scripted.body;
  }
  if (live.contains(genUiOpenMarker)) {
    return live;
  }
  return '${live.trimRight()}\n\n${scripted.view}';
}
