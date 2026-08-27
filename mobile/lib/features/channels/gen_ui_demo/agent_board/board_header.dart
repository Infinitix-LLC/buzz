part of '../agent_board_widget.dart';

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.title, required this.snapshot});

  final String title;
  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Grid.twelve,
        Grid.twelve,
        Grid.twelve,
        Grid.xxs,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Grid.quarter),
                Text.rich(
                  TextSpan(
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text:
                            '${demoAgents.length} agents · '
                            '${snapshot.inFlightCount} in flight · '
                            '${snapshot.doneCount} done',
                      ),
                      // The checklist counts blockers, so the board has to as
                      // well — two summaries of one workspace that disagree
                      // are read as one of them being wrong.
                      if (snapshot.blockedCount > 0)
                        TextSpan(
                          text: ' · ${snapshot.blockedCount} blocked',
                          style: TextStyle(
                            color: colors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _LiveChip(settled: snapshot.elapsed >= demoRunLength),
        ],
      ),
    );
  }
}

/// The "live" affordance, and the one thing on the board that must not lie:
/// once the run settles it stops claiming to be live.
class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.settled});

  final bool settled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = settled ? colors.onSurfaceVariant : boardGreen;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Grid.xxs,
        vertical: Grid.half,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (settled)
            Icon(Icons.check_rounded, size: 11, color: color)
          else
            PulsingDot(color: color),
          const SizedBox(width: 6),
          Text(
            settled ? 'settled' : 'live',
            style: context.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
