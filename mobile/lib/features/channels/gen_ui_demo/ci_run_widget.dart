import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/grid.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'agent_board_models.dart';
import 'pulsing_dot.dart';
import 'use_demo_workspace.dart';

part 'ci_run/job_row.dart';
part 'ci_run/flake_history.dart';

/// Outcome of one CI job.
enum JobStatus {
  passed(Color(0xFF3FC08B), Icons.check_rounded),
  failed(Color(0xFFE05252), Icons.close_rounded),
  running(Color(0xFFE0A33E), Icons.autorenew_rounded);

  const JobStatus(this.color, this.icon);

  final Color color;
  final IconData icon;
}

/// One job in the run's matrix.
class CiJob {
  const CiJob({
    required this.name,
    required this.status,
    required this.duration,
  });

  final String name;
  final JobStatus status;
  final String duration;
}

/// A CI run, rendered from a `genui{"ci_run": …}` directive.
///
/// ```text
/// genui{"ci_run": {"board": "release-cut", "run": "4812"}}
/// ```
///
/// The point of this one is that "why is CI red?" has a *shape* — a matrix,
/// one red cell, a failing assertion, and a flake rate — and prose is the
/// worst possible container for it. Reading the matrix takes about a second;
/// reading the same thing written out takes a paragraph and still leaves the
/// reader unsure which job failed.
class CiRunWidget extends HookWidget {
  const CiRunWidget({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final snapshot = useDemoWorkspace(attributes);
    final run = attributes['run'];

    // Once sentry finishes its task the run is green. Before that the reader
    // is looking at the failure the board says sentry is working on — the two
    // messages have to agree about that.
    final task = snapshot.taskById('huddle-reconnect');
    final fixed =
        task != null && snapshot.stepFor(task).column != BoardColumn.inProgress;

    return _RunFrame(
      runId: run is String ? run : '4812',
      fixed: fixed,
      elapsed: snapshot.elapsed,
    );
  }
}

/// The run's job matrix.
///
/// Top-level so the model briefing reads the same list the widget draws. Two
/// copies of a job matrix drift, and the drift shows up as an agent describing
/// a green build beside a red one.
///
/// [elapsed] is what stops this reading as a screenshot. For the first stretch
/// the last job is still running, so a reader who opens the card watches it
/// resolve rather than arriving after everything already happened.
List<CiJob> demoCiJobs({
  required bool fixed,
  Duration elapsed = const Duration(seconds: 30),
}) => [
  const CiJob(name: 'Rust Lint', status: JobStatus.passed, duration: '1m12s'),
  const CiJob(name: 'Unit Tests', status: JobStatus.passed, duration: '3m48s'),
  const CiJob(
    name: 'Backend Integration',
    status: JobStatus.passed,
    duration: '6m02s',
  ),
  const CiJob(
    name: 'Desktop Core',
    status: JobStatus.passed,
    duration: '2m31s',
  ),
  const CiJob(name: 'Mobile', status: JobStatus.passed, duration: '1m54s'),
  if (elapsed < ciSettleAt)
    CiJob(
      name: 'Relay E2E',
      status: JobStatus.running,
      duration: _runningFor(elapsed),
    )
  else
    CiJob(
      name: 'Relay E2E',
      status: fixed ? JobStatus.passed : JobStatus.failed,
      duration: '4m10s',
    ),
];

/// When the last job stops running and reports.
const ciSettleAt = Duration(seconds: 12);

/// A duration that climbs while the job is in flight.
String _runningFor(Duration elapsed) {
  final seconds = 190 + elapsed.inSeconds * 4;
  return '${seconds ~/ 60}m${(seconds % 60).toString().padLeft(2, '0')}s';
}

/// The assertion the failing job reports.
const demoFailingTest = 'e2e_relay::test_huddle_rejoin_is_idempotent';

/// The last twenty runs of that job, oldest last.
const demoFlakeHistory = <bool>[
  true, true, true, true, false, true, true, true, true, true, //
  true, true, true, false, true, true, true, true, true, true, //
];

class _RunFrame extends StatelessWidget {
  const _RunFrame({
    required this.runId,
    required this.fixed,
    required this.elapsed,
  });

  final String runId;
  final bool fixed;
  final Duration elapsed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final jobs = demoCiJobs(fixed: fixed, elapsed: elapsed);
    final running = jobs.any((j) => j.status == JobStatus.running);
    final failed = jobs.where((j) => j.status == JobStatus.failed).length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Grid.xxs),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(Grid.twelve),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CI run #$runId',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Grid.quarter),
                      Text(
                        running
                            ? 'main · 214 tests · running'
                            : 'main · 214 tests · 19m37s',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Grid.xxs,
                    vertical: Grid.half,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (running
                                ? JobStatus.running.color
                                : (failed == 0
                                      ? boardGreen
                                      : JobStatus.failed.color))
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                  child: Text(
                    running
                        ? 'running'
                        : (failed == 0 ? 'green' : '$failed failing'),
                    style: context.textTheme.labelSmall?.copyWith(
                      color: running
                          ? JobStatus.running.color
                          : (failed == 0 ? boardGreen : JobStatus.failed.color),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Grid.twelve,
              vertical: Grid.half,
            ),
            child: Column(
              children: [for (final job in jobs) _JobRow(job: job)],
            ),
          ),
          if (!fixed && !running) ...[
            Divider(height: 1, color: colors.outlineVariant),
            const _FailureDetail(),
          ],
          Divider(height: 1, color: colors.outlineVariant),
          const _FlakeHistory(),
        ],
      ),
    );
  }
}
