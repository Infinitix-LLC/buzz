import 'dart:async';

import 'package:flutter/foundation.dart';

import 'agent_board_models.dart';

/// The state one demo workspace shares across every gen-UI directive that
/// names it.
///
/// Two things move here, and they are deliberately different in kind:
///
/// * **Elapsed time** — agents working. Scripted, one-way, settles.
/// * **Actions** — the reader acting. A tapped Approve is recorded here and
///   changes what every widget reports from that moment on.
///
/// Sharing them is the whole point of the demo. Approving a patch in one
/// message moves a card on the board in another and flips a gate in a third,
/// because all three are views of one workspace rather than three pictures.
/// Widgets that each held their own copy could only ever disagree.
class DemoWorkspace extends ChangeNotifier {
  DemoWorkspace._() {
    _timer = Timer.periodic(tickInterval, (_) {
      final next = elapsed + tickInterval;
      // Freeze at the end. The run settles rather than looping: a board that
      // visibly restarts announces itself as a canned loop.
      if (next >= demoRunLength) {
        elapsed = demoRunLength;
        _timer?.cancel();
        _timer = null;
      } else {
        elapsed = next;
      }
      notifyListeners();
    });
  }

  /// Elapsed time is accumulated per tick rather than read from a [Stopwatch].
  /// A stopwatch reads the wall clock, which `tester.pump` cannot advance —
  /// the widgets would be untestable, and an untested demo is one that breaks
  /// in the room rather than in CI.
  static const tickInterval = Duration(milliseconds: 500);

  Duration elapsed = Duration.zero;

  final Set<String> _actions = {};
  Timer? _timer;
  int _refs = 0;

  static final Map<String, DemoWorkspace> _instances = {};

  /// The live workspace for [id], or null when nothing is rendering it.
  ///
  /// Read-only and does not start a clock. Used to brief the model on what the
  /// widgets are about to show, without a lookup being the thing that starts
  /// time running.
  static DemoWorkspace? peek(String id) => _instances[id];

  factory DemoWorkspace.acquire(String id) {
    final workspace = _instances.putIfAbsent(id, () => DemoWorkspace._());
    workspace._refs++;
    return workspace;
  }

  void release(String id) {
    _refs--;
    if (_refs > 0) {
      return;
    }
    _timer?.cancel();
    _timer = null;
    _instances.remove(id);
    dispose();
  }

  /// Records a reader's action and tells every widget in the workspace.
  void apply(String action) {
    if (_actions.add(action)) {
      notifyListeners();
    }
  }

  bool has(String action) => _actions.contains(action);

  /// The reader approved [taskId]'s patch.
  static String approved(String taskId) => 'approved:$taskId';

  /// The reader asked for changes on [taskId]'s patch.
  static String changesRequested(String taskId) => 'changes:$taskId';

  BoardSnapshot get snapshot =>
      BoardSnapshot(elapsed, Set.unmodifiable(_actions));

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// What the workspace looks like at one instant, derived from elapsed time and
/// the actions taken so far.
class BoardSnapshot {
  BoardSnapshot(this.elapsed, [this.actions = const {}])
    : _states = {for (final task in demoTasks) task.id: task.stateAt(elapsed)};

  final Duration elapsed;
  final Set<String> actions;
  final Map<String, BoardStep> _states;

  /// The step in effect, with the reader's actions layered over the script.
  ///
  /// An approval outranks the timeline: once someone approves a patch, the
  /// board saying it is still in review would be the workspace contradicting
  /// the person using it.
  BoardStep stepFor(BoardTask task) {
    final scripted = _states[task.id] ?? task.steps.first;
    if (actions.contains(DemoWorkspace.approved(task.id))) {
      return BoardStep(
        at: scripted.at,
        column: BoardColumn.done,
        note: 'approved by you',
      );
    }
    if (actions.contains(DemoWorkspace.changesRequested(task.id))) {
      return BoardStep(
        at: scripted.at,
        column: BoardColumn.inProgress,
        progress: 0.6,
        note: 'changes requested by you',
      );
    }
    return scripted;
  }

  List<BoardTask> inColumn(BoardColumn column) => [
    for (final task in demoTasks)
      if (stepFor(task).column == column) task,
  ];

  BoardTask? taskById(String id) {
    for (final task in demoTasks) {
      if (task.id == id) {
        return task;
      }
    }
    return null;
  }

  /// Tasks [agent] currently has in flight.
  int activeFor(BoardAgent agent) => [
    for (final task in demoTasks)
      if (task.agentId == agent.id &&
          stepFor(task).column == BoardColumn.inProgress)
        task,
  ].length;

  /// How far [agent] is through everything assigned to it, counting a finished
  /// task as whole and an in-flight one by its reported progress.
  double progressFor(BoardAgent agent) {
    final assigned = demoTasks.where((t) => t.agentId == agent.id).toList();
    if (assigned.isEmpty) {
      return 0;
    }
    var total = 0.0;
    for (final task in assigned) {
      final step = stepFor(task);
      total += switch (step.column) {
        BoardColumn.done => 1.0,
        BoardColumn.review => 0.9,
        BoardColumn.inProgress => (step.progress ?? 0.5).clamp(0.05, 0.85),
        BoardColumn.backlog => 0.0,
      };
    }
    return total / assigned.length;
  }

  int get doneCount => inColumn(BoardColumn.done).length;
  int get inFlightCount => inColumn(BoardColumn.inProgress).length;
  int get reviewCount => inColumn(BoardColumn.review).length;
  int get blockedCount => [
    for (final task in demoTasks)
      if (task.blocked && stepFor(task).column != BoardColumn.done) task,
  ].length;

  /// The most recent note across the board, for the tracker's activity line.
  ({BoardTask task, BoardStep step})? get latestActivity {
    ({BoardTask task, BoardStep step})? latest;
    var latestAt = Duration.zero;
    for (final task in demoTasks) {
      final at = task.lastChangeAt(elapsed);
      final step = stepFor(task);
      if (step.note == null) {
        continue;
      }
      if (latest == null || at >= latestAt) {
        latest = (task: task, step: step);
        latestAt = at;
      }
    }
    return latest;
  }
}

/// Formats a duration as the relative timestamps a reader expects on a card.
String formatAgo(Duration since) {
  if (since.inSeconds < 10) {
    return 'just now';
  }
  if (since.inSeconds < 60) {
    return '${since.inSeconds}s ago';
  }
  return '${since.inMinutes}m ago';
}
