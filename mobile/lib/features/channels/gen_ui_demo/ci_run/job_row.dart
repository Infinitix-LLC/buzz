part of '../ci_run_widget.dart';

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job});

  final CiJob job;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final failed = job.status == JobStatus.failed;
    final running = job.status == JobStatus.running;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: job.status.color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(Radii.xs),
            ),
            // A static "running" icon is the same thing as a screenshot of a
            // running job. The dot is what says the number beside it is still
            // climbing.
            child: job.status == JobStatus.running
                ? PulsingDot(color: job.status.color, size: 6)
                : Icon(job.status.icon, size: 11, color: job.status.color),
          ),
          const SizedBox(width: Grid.xxs),
          Expanded(
            child: Text(
              job.name,
              style: context.textTheme.labelMedium?.copyWith(
                // The failing row is the one the reader came for; everything
                // else is context and should not compete with it.
                fontWeight: failed || running
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: failed || running ? job.status.color : colors.onSurface,
              ),
            ),
          ),
          Text(
            job.duration,
            style: context.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The assertion that failed, verbatim.
///
/// A stack trace would be longer without being more useful in a chat message;
/// the assertion and its location are what let a reader decide whether they
/// recognise the failure.
class _FailureDetail extends StatelessWidget {
  const _FailureDetail();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.all(Grid.twelve),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            demoFailingTest,
            style: context.textTheme.labelSmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Grid.xxs),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Text(
              'assertion failed: peer.state == Connected\n'
              '  left:  Reconnecting\n'
              '  right: Connected',
              style: context.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
