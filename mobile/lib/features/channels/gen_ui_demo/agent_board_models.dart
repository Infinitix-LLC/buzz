/// Data behind the gen-UI agent board demo.
///
/// The board is driven by a scripted timeline rather than a live relay: this
/// is a demo surface, and a scripted run is deterministic on stage, works with
/// no backend, and cannot stall halfway through a sentence.
///
/// The shape here deliberately mirrors what the observer relay already streams
/// — `agent_activity/observer_models.dart` carries the same notion of an agent,
/// a unit of work, and a status that moves `executing → completed | failed`.
/// Binding this board to that stream is a change of source, not of model.
library;

import 'package:flutter/material.dart';

/// Where a task sits on the board.
enum BoardColumn {
  backlog('Backlog'),
  inProgress('In progress'),
  review('Review'),
  done('Done');

  const BoardColumn(this.label);

  final String label;
}

/// An agent working the board. [role] is what a reader needs to know about it
/// at a glance; the name alone does not carry that.
class BoardAgent {
  const BoardAgent({
    required this.id,
    required this.name,
    required this.role,
    required this.color,
  });

  final String id;
  final String name;
  final String role;
  final Color color;
}

/// One transition in a task's scripted life: at [at] seconds into the run it
/// moves to [column], optionally reporting [progress] and a [note].
class BoardStep {
  const BoardStep({
    required this.at,
    required this.column,
    this.progress,
    this.note,
  });

  final Duration at;
  final BoardColumn column;

  /// 0–1, shown as a bar on an in-progress card. Null leaves the bar off.
  final double? progress;

  /// What the agent is doing right now — the line that makes a card read as
  /// work rather than as a label.
  final String? note;
}

/// A unit of work, with the whole of its scripted life attached.
///
/// State is derived from elapsed time rather than mutated on a tick, so the
/// board cannot drift out of sync with itself and a late-joining widget shows
/// the same thing as one that has been mounted the whole time.
class BoardTask {
  const BoardTask({
    required this.id,
    required this.title,
    required this.agentId,
    required this.steps,
    this.blocked = false,
  });

  final String id;
  final String title;
  final String agentId;
  final List<BoardStep> steps;

  /// Drawn with a warning treatment. One blocked task is worth more than a
  /// board where everything succeeds — it shows the board is reporting, not
  /// decorating.
  final bool blocked;

  /// The step in effect at [elapsed].
  BoardStep stateAt(Duration elapsed) {
    var current = steps.first;
    for (final step in steps) {
      if (step.at <= elapsed) {
        current = step;
      } else {
        break;
      }
    }
    return current;
  }

  /// When this task last changed, for the relative timestamp on its card.
  Duration lastChangeAt(Duration elapsed) {
    var last = steps.first.at;
    for (final step in steps) {
      if (step.at <= elapsed) {
        last = step.at;
      } else {
        break;
      }
    }
    return last;
  }
}

/// Board accent, used for the live chip and the "done" metric. Not from the
/// colour scheme: it has to read as a status, not as a brand colour, in both
/// Latte and Macchiato.
const boardGreen = Color(0xFF3FC08B);

/// The agents on the demo board.
const demoAgents = <BoardAgent>[
  BoardAgent(
    id: 'scout',
    name: 'scout',
    role: 'triage & search',
    color: Color(0xFF6E8BFF),
  ),
  BoardAgent(
    id: 'patch',
    name: 'patch',
    role: 'code changes',
    color: Color(0xFF3FC08B),
  ),
  BoardAgent(
    id: 'sentry',
    name: 'sentry',
    role: 'CI & tests',
    color: Color(0xFFE0A33E),
  ),
  BoardAgent(
    id: 'scribe',
    name: 'scribe',
    role: 'docs & release notes',
    color: Color(0xFFB57EDC),
  ),
];

BoardAgent agentById(String id) =>
    demoAgents.firstWhere((a) => a.id == id, orElse: () => demoAgents.first);

Duration _s(int seconds) => Duration(seconds: seconds);

/// The scripted run: a release cut, in this project's own vocabulary.
///
/// Every task moves forward and the run settles — nothing loops. A board that
/// visibly restarts announces itself as a canned loop, which is the one thing
/// that would cost the demo its credibility.
final demoTasks = <BoardTask>[
  // Already finished when the board is first asked for. A release cut with an
  // empty Done column reads as a project that started the moment you looked at
  // it; real work has history behind it.
  BoardTask(
    id: 'huddle-ice',
    title: 'Relay: ICE candidate trickle for huddles',
    agentId: 'patch',
    steps: [
      BoardStep(at: _s(0), column: BoardColumn.done, note: 'merged yesterday'),
    ],
  ),
  BoardTask(
    id: 'search-nip50',
    title: 'Search: NIP-50 filter routing',
    agentId: 'scout',
    steps: [
      BoardStep(at: _s(0), column: BoardColumn.done, note: 'shipped in 0.5.18'),
    ],
  ),
  BoardTask(
    id: 'relay-typing',
    title: 'Relay: collapse kind:20002 typing storms',
    agentId: 'patch',
    steps: [
      BoardStep(
        at: _s(0),
        column: BoardColumn.review,
        note: 'scout reviewed · 2 files, +64 −31',
      ),
    ],
  ),
  BoardTask(
    id: 'huddle-reconnect',
    title: 'CI: flaky huddle reconnect test',
    agentId: 'sentry',
    steps: [
      BoardStep(
        at: _s(0),
        column: BoardColumn.inProgress,
        progress: 0.5,
        note: 'run #4812 · 3 retries',
      ),
      BoardStep(
        at: _s(18),
        column: BoardColumn.inProgress,
        progress: 0.88,
        note: 'reproduced on 2 of 20 runs',
      ),
      BoardStep(
        at: _s(34),
        column: BoardColumn.review,
        note: 'root cause: rejoin race on reconnect',
      ),
      BoardStep(at: _s(72), column: BoardColumn.done, note: 'fix merged'),
    ],
  ),
  BoardTask(
    id: 'search-backfill',
    title: 'Search: reindex 6-month backfill',
    agentId: 'scout',
    steps: [
      BoardStep(
        at: _s(0),
        column: BoardColumn.inProgress,
        progress: 0.22,
        note: '184k / 840k events',
      ),
      BoardStep(
        at: _s(12),
        column: BoardColumn.inProgress,
        progress: 0.46,
        note: '389k / 840k events',
      ),
      BoardStep(
        at: _s(24),
        column: BoardColumn.inProgress,
        progress: 0.71,
        note: '598k / 840k events',
      ),
      BoardStep(
        at: _s(40),
        column: BoardColumn.inProgress,
        progress: 0.94,
        note: '790k / 840k events',
      ),
      BoardStep(at: _s(52), column: BoardColumn.done, note: 'index swapped'),
    ],
  ),
  BoardTask(
    id: 'ime-tail',
    title: 'Mobile: thread tail settle on IME resize',
    agentId: 'patch',
    steps: [
      BoardStep(at: _s(0), column: BoardColumn.backlog),
      BoardStep(
        at: _s(30),
        column: BoardColumn.inProgress,
        progress: 0.3,
        note: 'reading thread tail settle',
      ),
      BoardStep(
        at: _s(50),
        column: BoardColumn.inProgress,
        progress: 0.66,
        note: 'two-frame settle on resize',
      ),
      BoardStep(
        at: _s(78),
        column: BoardColumn.review,
        note: 'patch sent · 1 file, +23 −9',
      ),
    ],
  ),
  BoardTask(
    id: 'key-rotation',
    title: 'Docs: agent key rotation guide',
    agentId: 'scribe',
    steps: [
      BoardStep(at: _s(0), column: BoardColumn.backlog),
      BoardStep(
        at: _s(22),
        column: BoardColumn.inProgress,
        progress: 0.4,
        note: 'drafting VISION_AGENT.md §4',
      ),
      BoardStep(
        at: _s(46),
        column: BoardColumn.inProgress,
        progress: 0.8,
        note: 'adding rotation worked example',
      ),
      BoardStep(at: _s(66), column: BoardColumn.review, note: 'ready to read'),
      BoardStep(at: _s(92), column: BoardColumn.done, note: 'merged'),
    ],
  ),
  BoardTask(
    id: 'nip42-scope',
    title: 'Relay: NIP-42 scope check on channel join',
    agentId: 'scout',
    // Blocked from the first frame, and visibly so. This sat in Backlog with
    // no note for the first 38 seconds, which is exactly when a demo starts:
    // the checklist reported a blocker, the agent said a blocker, and the
    // board showed a quiet card with nothing wrong with it. A blocker the
    // reader cannot find is worse than no blocker at all.
    steps: [
      BoardStep(
        at: _s(0),
        column: BoardColumn.inProgress,
        note: 'needs a call: re-verify scope per join?',
      ),
      BoardStep(
        at: _s(44),
        column: BoardColumn.inProgress,
        note: 'waiting on a call · asked in #relay-design',
      ),
    ],
    blocked: true,
  ),
  BoardTask(
    id: 'release-notes',
    title: 'Release notes for 0.6.0',
    agentId: 'scribe',
    steps: [
      BoardStep(at: _s(0), column: BoardColumn.backlog),
      BoardStep(
        at: _s(84),
        column: BoardColumn.inProgress,
        progress: 0.45,
        note: 'collecting PRs since 0.5.18',
      ),
    ],
  ),
];

/// How long the scripted run takes to settle.
const demoRunLength = Duration(seconds: 100);
