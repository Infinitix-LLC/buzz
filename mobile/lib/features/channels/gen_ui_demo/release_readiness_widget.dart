import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/grid.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'agent_board_models.dart';
import 'demo_workspace.dart';
import 'use_demo_workspace.dart';

part 'release_readiness/gate_row.dart';

/// Whether a release gate is satisfied.
enum GateStatus {
  // Read as "<gate> · <label>": "Migrations · clear", "Docs · not yet",
  // "Blockers · blocked". Words that work as a verdict beside a subject, not
  // as a state of their own.
  pass('clear', Color(0xFF3FC08B), Icons.check_circle_rounded),
  pending('not yet', Color(0xFFE0A33E), Icons.hourglass_top_rounded),
  blocked('blocked', Color(0xFFE05252), Icons.block_rounded);

  const GateStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

/// One thing that has to be true before a release goes out.
class ReleaseGate {
  const ReleaseGate({
    required this.name,
    required this.status,
    required this.detail,
  });

  final String name;
  final GateStatus status;

  /// Why it is in that state. A gate that reports only pass or fail makes the
  /// reader go and look somewhere else, which is the habit this replaces.
  final String detail;
}

/// A release checklist, rendered from a `genui{"release_readiness": …}`
/// directive.
///
/// ```text
/// genui{"release_readiness": {"board": "release-cut", "version": "0.6.0"}}
/// ```
///
/// Every gate is derived from the same workspace the board reads, so this is
/// not a second copy of the truth that can drift from it. Approving the patch
/// in the review message clears the sign-off gate here, in a message that was
/// posted before the approval happened.
class ReleaseReadinessWidget extends HookWidget {
  const ReleaseReadinessWidget({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final snapshot = useDemoWorkspace(attributes);
    final version = attributes['version'];

    return _ReadinessFrame(
      version: version is String ? version : '0.6.0',
      gates: _gatesFor(snapshot),
      snapshot: snapshot,
    );
  }
}

/// Reads the workspace and turns it into gates.
///
/// Deliberately derived rather than scripted: a checklist that told a
/// different story from the board next to it would be the one thing a reader
/// cannot forgive, and hand-written gates drift the moment the board does.
List<ReleaseGate> _gatesFor(BoardSnapshot snapshot) {
  final reviewOutstanding = snapshot.reviewCount;
  final blocked = snapshot.blockedCount;
  final docs = snapshot.taskById('key-rotation');
  final docsStep = docs == null ? null : snapshot.stepFor(docs);
  final docsDone = docsStep?.column == BoardColumn.done;
  final notes = snapshot.taskById('release-notes');
  final notesStep = notes == null ? null : snapshot.stepFor(notes);
  final notesDone = notesStep?.column == BoardColumn.done;

  // Read from the same task the CI directive reads. Hard-coding this gate as
  // green while the CI message beside it showed a red job would be the
  // workspace contradicting itself, which costs more than the gate is worth.
  final ci = snapshot.taskById('huddle-reconnect');
  final ciStep = ci == null ? null : snapshot.stepFor(ci);
  final ciGreen = ciStep != null && ciStep.column != BoardColumn.inProgress;

  return [
    ReleaseGate(
      name: 'CI on main',
      status: ciGreen ? GateStatus.pass : GateStatus.pending,
      detail: ciGreen
          ? 'run #4812 · 214 tests · huddle rejoin flake fixed'
          : 'run #4812 · Relay E2E failing · sentry has a fix in review',
    ),
    ReleaseGate(
      name: 'Patch review',
      status: reviewOutstanding == 0 ? GateStatus.pass : GateStatus.pending,
      detail: reviewOutstanding == 0
          ? 'every patch in this cut has a sign-off'
          : '$reviewOutstanding awaiting sign-off',
    ),
    ReleaseGate(
      name: 'Migrations',
      status: GateStatus.pass,
      detail: '0 new migrations since 0.5.18',
    ),
    ReleaseGate(
      name: 'Docs',
      status: docsDone ? GateStatus.pass : GateStatus.pending,
      detail: docsDone
          ? 'agent key rotation guide merged'
          : 'scribe is still on the key rotation guide',
    ),
    ReleaseGate(
      name: 'Release notes',
      status: notesDone ? GateStatus.pass : GateStatus.pending,
      detail: notesDone ? 'written and merged' : 'scribe drafting',
    ),
    ReleaseGate(
      name: 'Blockers',
      status: blocked == 0 ? GateStatus.pass : GateStatus.blocked,
      detail: blocked == 0
          ? 'none open'
          : '$blocked open · NIP-42 scope check needs a human call',
    ),
  ];
}

class _ReadinessFrame extends StatelessWidget {
  const _ReadinessFrame({
    required this.version,
    required this.gates,
    required this.snapshot,
  });

  final String version;
  final List<ReleaseGate> gates;
  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final blocked = gates.where((g) => g.status == GateStatus.blocked).length;
    final pending = gates.where((g) => g.status == GateStatus.pending).length;
    final passed = gates.where((g) => g.status == GateStatus.pass).length;

    final (verdict, verdictColor) = switch ((blocked, pending)) {
      (> 0, _) => ('Not ready', GateStatus.blocked.color),
      (_, > 0) => ('Almost there', GateStatus.pending.color),
      _ => ('Ready to ship', GateStatus.pass.color),
    };

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
                        'Release $version',
                        style: context.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Grid.quarter),
                      Text(
                        '$passed of ${gates.length} gates clear',
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
                    color: verdictColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                  child: Text(
                    verdict,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: verdictColor,
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
              children: [for (final gate in gates) _GateRow(gate: gate)],
            ),
          ),
        ],
      ),
    );
  }
}
