part of '../agent_board_widget.dart';

class _Column extends StatelessWidget {
  const _Column({required this.column, required this.snapshot});

  final BoardColumn column;
  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tasks = snapshot.inColumn(column);

    // Narrow enough that a phone shows two whole columns and the edge of a
    // third. A wider column fits more text but cuts the next one mid-card,
    // which reads as a layout bug rather than as a scrollable board.
    return SizedBox(
      width: 176,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: Grid.half,
              right: Grid.half,
              bottom: Grid.xxs,
            ),
            child: Row(
              children: [
                Text(
                  column.label,
                  style: context.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(Radii.full),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: tasks.isEmpty
                  ? const SizedBox.expand()
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: tasks.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) => _TaskCard(
                        key: ValueKey(tasks[index].id),
                        task: tasks[index],
                        snapshot: snapshot,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
