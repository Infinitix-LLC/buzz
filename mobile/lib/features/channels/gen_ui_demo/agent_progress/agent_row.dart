part of '../agent_progress_widget.dart';

class _AgentRow extends StatelessWidget {
  const _AgentRow({required this.agent, required this.snapshot});

  final BoardAgent agent;
  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = snapshot.progressFor(agent);
    final active = snapshot.activeFor(agent);

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: agent.color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Text(
            agent.name.substring(0, 1).toUpperCase(),
            style: context.textTheme.labelSmall?.copyWith(
              color: agent.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: Grid.xxs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    agent.name,
                    style: context.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      active > 0 ? agent.role : 'idle · ${agent.role}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      // Tabular figures so the percentage does not jitter
                      // sideways every time it ticks.
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Grid.half),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.full),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 4,
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(agent.color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
