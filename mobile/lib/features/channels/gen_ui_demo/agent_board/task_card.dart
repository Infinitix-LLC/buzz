part of '../agent_board_widget.dart';

class _TaskCard extends StatelessWidget {
  const _TaskCard({super.key, required this.task, required this.snapshot});

  final BoardTask task;
  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final step = snapshot.stepFor(task);
    final agent = agentById(task.agentId);
    final blocked = task.blocked && step.column != BoardColumn.done;
    final since = snapshot.elapsed - task.lastChangeAt(snapshot.elapsed);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(Grid.xxs),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: blocked
              ? colors.error.withValues(alpha: 0.5)
              : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blocked is a status, not a shade of border. A reader scanning four
          // columns will not notice a tinted outline, and a blocker nobody
          // notices reads as a board that is not reporting.
          if (blocked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Radii.xs),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block_rounded, size: 10, color: colors.error),
                  const SizedBox(width: 4),
                  Text(
                    'Blocked',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 3,
                height: 26,
                margin: const EdgeInsets.only(right: 6, top: 1),
                decoration: BoxDecoration(
                  color: agent.color,
                  borderRadius: BorderRadius.circular(Radii.xs / 2),
                ),
              ),
              Expanded(
                child: Text(
                  task.title,
                  style: context.textTheme.labelMedium?.copyWith(height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (step.progress != null &&
              step.column == BoardColumn.inProgress) ...[
            const SizedBox(height: Grid.xxs),
            // Tweened rather than set: a bar that jumps between two scripted
            // values is exactly what reads as canned, and interpolating it
            // costs nothing.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: step.progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(Radii.full),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 3,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(agent.color),
                ),
              ),
            ),
          ],
          if (step.note != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (blocked)
                  Padding(
                    padding: const EdgeInsets.only(right: Grid.half, top: 1),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 11,
                      color: colors.error,
                    ),
                  ),
                Expanded(
                  child: Text(
                    step.note!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: blocked ? colors.error : colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                    // One line normally, so cards stay a predictable height.
                    // A blocked card is the exception: its note is the reason
                    // it is blocked, and half a reason is no reason.
                    maxLines: blocked ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              if (step.column == BoardColumn.inProgress && !blocked) ...[
                PulsingDot(color: agent.color, size: 5),
                const SizedBox(width: 5),
              ],
              // Expanded, not fixed: at column width an agent name and a
              // relative timestamp together can exceed the card, and the name
              // is the half that can afford to ellipsise. Expanding it also
              // holds the timestamp against the right edge.
              Expanded(
                child: Text(
                  agent.name,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: agent.color,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Grid.xxs),
              Text(
                formatAgo(since),
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
