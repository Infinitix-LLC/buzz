part of '../code_review_widget.dart';

/// One thing the reviewing agent noticed.
class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});

  final ReviewFinding finding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 5, right: Grid.xxs),
            decoration: BoxDecoration(
              color: finding.severity.color,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${finding.file}:${finding.line}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.onSurface,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      finding.severity.label,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: finding.severity.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  finding.message,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.35,
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
