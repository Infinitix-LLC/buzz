part of '../code_review_widget.dart';

/// Approve / request changes, and what the workspace did about it.
///
/// The confirmation names the consequence rather than just acknowledging the
/// tap. "Approved" tells the reader their press registered; "the board moved
/// this to Done" tells them the workspace changed — which is the claim the
/// whole demo is making, and it is worth saying out loud in the UI.
class _ReviewActions extends StatelessWidget {
  const _ReviewActions({required this.review, required this.workspace});

  final CodeReview review;
  final DemoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final approved = workspace.has(DemoWorkspace.approved(review.taskId));
    final changes = workspace.has(
      DemoWorkspace.changesRequested(review.taskId),
    );

    return Padding(
      padding: const EdgeInsets.all(Grid.twelve),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: Alignment.topLeft,
        child: approved || changes
            ? _Outcome(approved: approved)
            : _Buttons(review: review, workspace: workspace),
      ),
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({required this.review, required this.workspace});

  final CodeReview review;
  final DemoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () =>
                workspace.apply(DemoWorkspace.approved(review.taskId)),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Approve'),
            style: FilledButton.styleFrom(
              backgroundColor: boardGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: Grid.xxs),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
          ),
        ),
        const SizedBox(width: Grid.xxs),
        Expanded(
          child: OutlinedButton(
            onPressed: () =>
                workspace.apply(DemoWorkspace.changesRequested(review.taskId)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              side: BorderSide(color: colors.outlineVariant),
              padding: const EdgeInsets.symmetric(vertical: Grid.xxs),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
            child: const Text('Request changes'),
          ),
        ),
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.approved});

  final bool approved;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = approved ? boardGreen : const Color(0xFFE0A33E);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Grid.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            approved ? Icons.check_circle_rounded : Icons.history_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: Grid.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approved ? 'You approved this patch' : 'Changes requested',
                  style: context.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  approved
                      ? 'The board moved it to Done, and the release '
                            'checklist cleared its review gate.'
                      : 'patch picked it back up — the board moved it back '
                            'to In progress.',
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
