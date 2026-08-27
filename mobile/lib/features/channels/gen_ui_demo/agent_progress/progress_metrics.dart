part of '../agent_progress_widget.dart';

class _ProgressMetrics extends StatelessWidget {
  const _ProgressMetrics({required this.snapshot});

  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        _Metric(
          value: '${snapshot.doneCount}',
          label: 'done',
          color: boardGreen,
        ),
        _Metric(
          value: '${snapshot.inFlightCount}',
          label: 'in flight',
          color: colors.primary,
        ),
        _Metric(
          value: '${snapshot.reviewCount}',
          label: 'in review',
          color: const Color(0xFFE0A33E),
        ),
        _Metric(
          value: '${snapshot.blockedCount}',
          label: 'blocked',
          // A zero here should not shout. Colouring it like the others would
          // make "nothing is blocked" look like an alert.
          color: snapshot.blockedCount > 0
              ? colors.error
              : colors.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
