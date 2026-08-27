part of '../code_review_widget.dart';

/// The size of the patch, and where it lands.
class _DiffStat extends StatelessWidget {
  const _DiffStat({required this.review});

  final CodeReview review;

  static const _added = Color(0xFF3FC08B);
  static const _removed = Color(0xFFE05252);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = review.added + review.removed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${review.files.length} '
              '${review.files.length == 1 ? 'file' : 'files'}',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Grid.xxs),
            Text(
              '+${review.added}',
              style: context.textTheme.labelSmall?.copyWith(
                color: _added,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '−${review.removed}',
              style: context.textTheme.labelSmall?.copyWith(
                color: _removed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Proportional, not decorative: the bar says at a glance whether this
        // is an addition, a deletion, or a rewrite.
        ClipRRect(
          borderRadius: BorderRadius.circular(Radii.full),
          // Explicit width: the parent Column aligns to start, which hands
          // children loose constraints — a SizedBox with only a height
          // collapses to zero width and the bar silently vanishes.
          child: SizedBox(
            width: double.infinity,
            height: 4,
            child: Row(
              // Stretch, not the default centre: a Row centres its children
              // with loose cross-axis constraints, and a ColoredBox with no
              // child then sizes to zero height and paints nothing.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: total == 0 ? 1 : review.added,
                  child: const ColoredBox(color: _added),
                ),
                Expanded(
                  flex: total == 0 ? 1 : review.removed,
                  child: const ColoredBox(color: _removed),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Grid.xxs),
        for (final file in review.files)
          Padding(
            padding: const EdgeInsets.only(bottom: Grid.half),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.shortPath,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurface,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: Grid.xxs),
                Text(
                  '+${file.added}',
                  style: context.textTheme.labelSmall?.copyWith(color: _added),
                ),
                const SizedBox(width: Grid.half),
                Text(
                  '−${file.removed}',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: _removed,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
