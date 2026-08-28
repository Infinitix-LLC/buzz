/// A fully hardcoded channel that plays back a scripted conversation showing
/// every generative-UI widget the app can render.
///
/// Nothing here touches the relay. The channel is spliced into the channel
/// list and its messages are returned directly, so the thread reads identically
/// on any device, offline, with no seeding and no agent running. It exists to
/// be shown to someone, not to be used.
///
/// Two speakers: the signed-in user asks, and `scout` answers. Every answer
/// carries **exactly one** widget, because the point is to show what each one
/// looks like on its own rather than to build a dashboard.
library;

import 'dart:io';

import '../../../shared/relay/nostr_models.dart';
import '../channel.dart';

/// Channel id. Not a relay id — nothing will ever resolve it there.
const String showcaseChannelId = 'showcase-genui-thread';

/// Whether to splice the showcase channel into the channel list.
///
/// Off under `flutter test`. The channel-list tests assert their exact
/// contents, and a demo channel appearing in all of them fails nine of those
/// tests for a reason that has nothing to do with what they cover. Gating here
/// keeps the suite honest about the filtering logic it is actually testing.
bool get showcaseEnabled => !Platform.environment.containsKey('FLUTTER_TEST');

/// The bot's pubkey. Fixed so its avatar colour and initials stay put.
const String showcaseBotPubkey =
    'scout00000000000000000000000000000000000000000000000000000000bot';

const String _board = 'release-cut';

/// Wraps a widget payload in the private-use markers the renderer scans for.
String _g(String payload) => '\u{E200}genui\u{E202}$payload\u{E201}';

/// One scripted turn.
class _Turn {
  const _Turn.ask(this.text) : fromBot = false;
  const _Turn.answer(this.text) : fromBot = true;

  final String text;
  final bool fromBot;
}

/// The script, in order. Each bot turn holds one widget and a sentence of
/// context, so the thread reads as a conversation rather than a gallery.
final List<_Turn> _script = [
  const _Turn.ask('Morning scout. Where does the release cut stand?'),
  _Turn.answer('''
Here is the board as it stands.

${_g('{"agent_board": {"board": "$_board", "title": "Release cut · 0.6.0"}}')}

Four agents are working. `relay-typing` is the one to watch.'''),

  const _Turn.ask('How far along is everyone?'),
  _Turn.answer(
    '''
${_g('{"agent_progress": {"board": "$_board"}}')}

Nothing is stalled, but the NIP-42 scope check still needs a decision from you.''',
  ),

  const _Turn.ask('Show me the review on relay-typing.'),
  _Turn.answer('''
${_g('{"code_review": {"board": "$_board", "task": "relay-typing"}}')}

Two comments are blocking. The rest are nits I can fold in myself.'''),

  const _Turn.ask('Did CI go green?'),
  _Turn.answer('''
${_g('{"ci_run": {"board": "$_board", "run": "4812"}}')}

The relay suite is the slow one, as always.'''),

  const _Turn.ask('Are we clear to ship 0.6.0?'),
  _Turn.answer('''
${_g('{"release_readiness": {"board": "$_board", "version": "0.6.0"}}')}

Everything is clear except the scope check. Your call.'''),

  const _Turn.ask('Explain NIP-42 to someone non-technical.'),
  _Turn.answer(
    '''
Easier to watch than to read.

${_g('{"val_scene": {"scene": "handshake", "name": "How Buzz knows it is really you", "frame": "landscape"}}')}

That runs on the device — the script ships in the app and the engine draws every frame here.''',
  ),

  const _Turn.ask('How does an agent actually pick up work?'),
  _Turn.answer(
    '''
${_g('{"val_scene": {"scene": "agent_lifecycle", "name": "How an agent picks up work", "frame": "landscape"}}')}

That is the whole loop. An agent is a member of the channel, not a service behind a dashboard.''',
  ),

  const _Turn.ask('What happens when I hit send?'),
  _Turn.answer(
    '''
${_g('{"val_scene": {"scene": "message_fanout", "name": "Where your message goes", "frame": "landscape"}}')}

One signed event in, a copy to each member out — and the same path whether the sender is a person or an agent.''',
  ),

  const _Turn.ask('What actually is a message here?'),
  _Turn.answer('''
${_g('{"val_scene": {"scene": "event_anatomy", "name": "What a message really is", "frame": "landscape"}}')}

Five fields and a signature. That is the whole unit Buzz moves around.'''),

  const _Turn.ask('Why does a bigger channel cost more to run?'),
  _Turn.answer(
    '''
${_g('{"val_scene": {"scene": "latency_curve", "name": "Why a big channel costs more", "frame": "landscape"}}')}

The axis, the curve and the formula are all drawn on the device — none of it is an image.''',
  ),

  const _Turn.ask('How has message volume been trending?'),
  _Turn.answer('''
${_g('{"line_chart": {"title": "Messages per day", "labels": ["Mon", "Tue", "Wed", "Thu", "Fri"], "points": [1840, 2120, 1990, 2680, 3110], "color": "#4C9AFF", "curved": true, "height": 240}}')}

Friday is the huddle pilot landing.'''),

  const _Turn.ask('And where is that volume coming from?'),
  _Turn.answer('''
${_g('{"bar_chart": {"title": "Messages by surface", "values": [{"label": "Desktop", "value": 1420, "color": "#4C9AFF"}, {"label": "Mobile", "value": 980, "color": "#B78CFF"}, {"label": "CLI", "value": 410}, {"label": "Agents", "value": 300}], "height": 240}}')}

Agent traffic tripled this week.'''),

  const _Turn.ask('What share of that is agents versus people?'),
  _Turn.answer('''
${_g('{"pie_chart": {"title": "Who is talking", "values": [{"label": "People", "value": 62, "color": "#4C9AFF"}, {"label": "Agents", "value": 28, "color": "#35D07F"}, {"label": "Webhooks", "value": 20, "color": "#FFA62B"}], "height": 260}}')}

More than four in ten messages are now non-human.'''),

  const _Turn.ask('How close are the release blockers to done?'),
  _Turn.answer('''
${_g('{"progress_list": {"title": "Blockers to zero", "values": [{"label": "NIP-42 scope check", "value": 40, "color": "#FFA62B"}, {"label": "Typing indicator flush", "value": 85, "color": "#4C9AFF"}, {"label": "Huddle reconnect", "value": 100, "color": "#35D07F"}]}}')}

One of the three is genuinely done.'''),

  const _Turn.ask('How do we compare against the targets we set?'),
  _Turn.answer('''
${_g('{"comparison_chart": {"title": "Now vs 0.6.0 target", "currentLabel": "Now", "targetLabel": "Target", "currentColor": "#4C9AFF", "targetColor": "#35D07F", "values": [{"label": "Latency", "current": 84, "target": 70}, {"label": "Coverage", "current": 71, "target": 80}, {"label": "Uptime", "current": 99, "target": 100}], "height": 280}}')}

Coverage is the one we are furthest from.'''),

  const _Turn.ask('Has test coverage been climbing?'),
  _Turn.answer('''
${_g('{"area_chart": {"title": "Coverage over the last five cuts", "labels": ["0.2", "0.3", "0.4", "0.5", "0.6"], "points": [48, 55, 61, 66, 71], "color": "#35D07F", "curved": true, "height": 240}}')}

Steady, and roughly five points a cut.'''),

  const _Turn.ask('Walk me through what happens when a device pairs.'),
  _Turn.answer('''
${_g('{"timeline_flow": {"title": "Pairing a second device", "subtitle": "What NIP-AB does, end to end", "items": [{"time": "Step 1", "title": "Show the code", "description": "The signed-in device displays a short-lived pairing code.", "takeaway": "The code expires in sixty seconds.", "color": "#4C9AFF"}, {"time": "Step 2", "title": "Scan it", "description": "The new device scans the code and opens a private sidecar relay.", "takeaway": "Nothing crosses the main relay yet.", "color": "#B78CFF"}, {"time": "Step 3", "title": "Hand over the key", "description": "The key is passed directly between the two devices and never stored.", "takeaway": "Only your devices ever hold it.", "color": "#35D07F"}]}}')}

Three steps, and the middle one is where most people stop worrying.'''),

  const _Turn.ask('What does our relay latency curve look like under load?'),
  _Turn.answer('''
${_g('{"plot_latex": {"title": "Queue delay", "equation": "x^2"}}')}

Delay grows with the square of queue depth, which is why we shed early.'''),

  const _Turn.ask('Can you show fan-out cost across channel size and members?'),
  _Turn.answer(
    '''
${_g('{"surface_3d": {"title": "Fan-out cost", "equation": "z = a * (x^2 - y^2)", "constants": [{"name": "a", "label": "Fan-out factor", "value": 0.24, "min": 0.05, "max": 0.6, "step": 0.01}], "xMin": -1.8, "xMax": 1.8, "yMin": -1.8, "yMax": 1.8, "uSteps": 34, "vSteps": 34, "wireframe": "overlay", "height": 320}}')}

Drag it. The saddle is why very large, very chatty channels are the expensive case.''',
  ),

  const _Turn.ask('One more — convert the relay budget into SI for the paper.'),
  _Turn.answer(
    '''
${_g('{"unit_converter": {"title": "Latency budget", "subtitle": "Our budget expressed however you need it", "value": 84, "fromUnit": "ms", "toUnit": "s", "min": 0, "max": 500, "divisions": 20, "precision": 3, "note": "The 0.6.0 budget is 100 ms end to end."}}')}

That is the whole set. Every one of those is a widget this app registered itself — the renderer ships none of them.''',
  ),
];

/// The channel row. `lastMessageAt` is pinned into the future so the thread
/// sorts to the top of the list where a demo can be found without scrolling.
Channel showcaseChannel(String ownerPubkey) {
  final now = DateTime.now();
  return Channel(
    id: showcaseChannelId,
    name: 'showcase',
    channelType: 'stream',
    visibility: 'open',
    description: 'Every generative UI widget, in one conversation',
    topic: 'Generative UI showcase',
    createdBy: ownerPubkey,
    createdAt: now.subtract(const Duration(days: 2)),
    memberCount: 2,
    lastMessageAt: now,
    participants: const ['you', 'scout'],
    participantPubkeys: [ownerPubkey, showcaseBotPubkey],
    isMember: true,
  );
}

/// The scripted messages, oldest first.
///
/// Timestamps are laid out backwards from now at a fixed spacing so the thread
/// always looks like it happened over the last hour, whenever it is opened.
List<NostrEvent> showcaseMessages(String ownerPubkey) {
  final base = DateTime.now().subtract(Duration(minutes: 3 * _script.length));
  return [
    for (final (index, turn) in _script.indexed)
      NostrEvent(
        // Deterministic, so a rebuild does not look like a new message.
        id: 'showcase-${index.toString().padLeft(3, '0')}',
        pubkey: turn.fromBot ? showcaseBotPubkey : ownerPubkey,
        createdAt:
            base.add(Duration(minutes: 3 * index)).millisecondsSinceEpoch ~/
            1000,
        kind: EventKind.streamMessageV2,
        tags: [
          ['h', showcaseChannelId],
        ],
        content: turn.text,
        sig: '',
      ),
  ];
}
