part of '../ci_run_widget.dart';

/// The last twenty runs of this job, oldest to newest.
///
/// This is the line that turns "CI is red" into a decision. Two failures in
/// twenty is a flake to chase; twenty in twenty is a broken build. The same
/// sentence in prose — "it fails sometimes" — supports neither call.
class _FlakeHistory extends StatelessWidget {
  const _FlakeHistory();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final failures = demoFlakeHistory.where((ok) => !ok).length;

    return Padding(
      padding: const EdgeInsets.all(Grid.twelve),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Relay E2E · last 20 runs',
                style: context.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                '$failures failed',
                style: context.textTheme.labelSmall?.copyWith(
                  color: JobStatus.failed.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < demoFlakeHistory.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: demoFlakeHistory[i]
                          ? boardGreen.withValues(alpha: 0.45)
                          : JobStatus.failed.color,
                      borderRadius: BorderRadius.circular(Radii.xs / 2),
                    ),
                  ),
                ),
                if (i < demoFlakeHistory.length - 1) const SizedBox(width: 2),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
