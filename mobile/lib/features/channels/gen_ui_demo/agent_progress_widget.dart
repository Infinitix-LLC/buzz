import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/grid.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'demo_workspace.dart';
import 'agent_board_models.dart';
import 'use_demo_workspace.dart';

part 'agent_progress/progress_metrics.dart';
part 'agent_progress/agent_row.dart';

/// Per-agent progress for a board, rendered from a
/// `genui{"agent_progress": …}` directive.
///
/// Shares [DemoBoardClock] with the board widget, so the two directives in one
/// message always agree. A tracker counting a task as in-flight while the board
/// beside it shows that same task in review would read as a bug in the
/// workspace, not as live data.
class AgentProgressWidget extends HookWidget {
  const AgentProgressWidget({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    return _ProgressFrame(snapshot: useDemoWorkspace(attributes));
  }
}

class _ProgressFrame extends StatelessWidget {
  const _ProgressFrame({required this.snapshot});

  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final latest = snapshot.latestActivity;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Grid.xxs),
      padding: const EdgeInsets.all(Grid.twelve),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProgressMetrics(snapshot: snapshot),
          const SizedBox(height: Grid.twelve),
          for (final agent in demoAgents) ...[
            _AgentRow(agent: agent, snapshot: snapshot),
            if (agent != demoAgents.last) const SizedBox(height: Grid.xxs),
          ],
          if (latest != null) ...[
            const SizedBox(height: Grid.twelve),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 6),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${agentById(latest.task.agentId).name} · '
                    '${latest.step.note}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
