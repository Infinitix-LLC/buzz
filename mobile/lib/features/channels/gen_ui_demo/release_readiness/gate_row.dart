part of '../release_readiness_widget.dart';

class _GateRow extends StatelessWidget {
  const _GateRow({required this.gate});

  final ReleaseGate gate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated so a gate clearing is something the reader sees happen,
          // rather than something they notice later.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              gate.status.icon,
              key: ValueKey(gate.status),
              size: 15,
              color: gate.status.color,
            ),
          ),
          const SizedBox(width: Grid.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        gate.name,
                        style: context.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // The verdict, said out loud. An icon alone leaves the
                    // reader inferring it from a colour, and the gate name is
                    // the subject — not the answer.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: gate.status.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(Radii.xs),
                      ),
                      child: Text(
                        gate.status.label,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: gate.status.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  gate.detail,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
