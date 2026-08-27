import 'agent_board_models.dart';
import 'ci_run_widget.dart'
    show JobStatus, demoCiJobs, demoFailingTest, demoFlakeHistory;
import 'code_review_models.dart';
import 'demo_workspace.dart';

/// Renders the workspace as text the model can read before it answers.
///
/// This exists because of a mistake worth naming. The first version of the
/// prompt forbade the model from stating any figure about the release, on the
/// grounds that the widgets owned the data and the model should not be able to
/// contradict them. It could not contradict them — and it could not say
/// anything useful either. Every answer hedged: "looks like a failing job",
/// "if the gates are green". It read exactly like someone who had not looked.
///
/// Handing it the same state the widgets render fixes both halves at once. It
/// can be specific because it knows, and its prose agrees with the widget
/// beside it because both were built from this snapshot.
String workspaceBriefing({String board = 'release-cut'}) {
  final snapshot =
      DemoWorkspace.peek(board)?.snapshot ?? BoardSnapshot(Duration.zero);
  final buffer = StringBuffer()
    ..writeln('# Current workspace state')
    ..writeln()
    ..writeln(
      'This is what the views will render if you show them. It is live and '
      'moves while you read it. Speak from it — be specific, name the tasks '
      'and the agents. Anything you say must agree with what is here.',
    )
    ..writeln();

  buffer.writeln('## Board "$board" — release 0.6.0');
  for (final column in BoardColumn.values) {
    final tasks = snapshot.inColumn(column);
    if (tasks.isEmpty) {
      continue;
    }
    buffer.writeln();
    buffer.writeln('${column.label}:');
    for (final task in tasks) {
      final step = snapshot.stepFor(task);
      final agent = agentById(task.agentId);
      final parts = <String>[
        '${task.title} — ${agent.name}',
        if (step.progress != null && column == BoardColumn.inProgress)
          '${(step.progress! * 100).round()}%',
        if (step.note != null) step.note!,
        if (task.blocked && column != BoardColumn.done) 'BLOCKED',
      ];
      buffer.writeln('- ${parts.join(' · ')}');
    }
  }

  buffer
    ..writeln()
    ..writeln('## Agents');
  for (final agent in demoAgents) {
    buffer.writeln(
      '- ${agent.name} (${agent.role}): '
      '${(snapshot.progressFor(agent) * 100).round()}% through its work, '
      '${snapshot.activeFor(agent)} in flight',
    );
  }

  final review = demoReviews.values.first;
  final reviewTask = snapshot.taskById(review.taskId);
  final reviewStep = reviewTask == null ? null : snapshot.stepFor(reviewTask);
  buffer
    ..writeln()
    ..writeln('## The one patch under review')
    ..writeln('- "${review.title}" on branch ${review.branch}')
    ..writeln(
      '- ${review.agentId} wrote it, ${review.reviewerId} reviewed it · '
      '${review.files.length} files, +${review.added} −${review.removed}',
    );
  for (final file in review.files) {
    buffer.writeln('  - ${file.path} (+${file.added} −${file.removed})');
  }
  for (final finding in review.findings) {
    buffer.writeln(
      '  - ${finding.severity.label} at ${finding.file}:${finding.line} — '
      '${finding.message}',
    );
  }
  buffer.writeln(
    '- Status: ${reviewStep?.column.label ?? 'unknown'}'
    '${reviewStep?.note == null ? '' : ' (${reviewStep!.note})'}',
  );

  final ciTask = snapshot.taskById('huddle-reconnect');
  final ciFixed =
      ciTask != null &&
      snapshot.stepFor(ciTask).column != BoardColumn.inProgress;
  final jobs = demoCiJobs(fixed: ciFixed, elapsed: snapshot.elapsed);
  final ciRunning = jobs.any((j) => j.status == JobStatus.running);
  buffer
    ..writeln()
    ..writeln(
      '## CI run #4812 on main — 214 tests'
      '${ciRunning ? ', still running' : ', 19m37s'}',
    );
  for (final job in jobs) {
    final state = switch (job.status) {
      JobStatus.failed => 'FAILING',
      JobStatus.running => 'STILL RUNNING',
      JobStatus.passed => 'passed',
    };
    buffer.writeln('- ${job.name}: $state (${job.duration})');
  }
  if (ciRunning) {
    buffer.writeln(
      '- The run has not finished. Do not describe its outcome yet — say it '
      'is still going.',
    );
  }
  if (!ciFixed && !ciRunning) {
    buffer
      ..writeln('- Failing test: $demoFailingTest')
      ..writeln('- Assertion: peer state was Reconnecting, expected Connected')
      ..writeln(
        '- Flake rate: ${demoFlakeHistory.where((ok) => !ok).length} of '
        '${demoFlakeHistory.length} recent runs — a flake, not a break',
      );
  }

  buffer
    ..writeln()
    ..writeln('## Release 0.6.0 gates')
    ..writeln('- ${snapshot.reviewCount} patch(es) still awaiting sign-off')
    ..writeln('- ${snapshot.blockedCount} open blocker(s)')
    ..writeln('- 0 new migrations since 0.5.18')
    ..writeln(
      '- The blocker is "Relay: NIP-42 scope check on channel join" — scout '
      'needs a human decision on whether private channels re-verify scope on '
      'every join. Nothing else needs a person.',
    );

  return buffer.toString();
}
