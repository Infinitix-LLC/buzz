import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/grid.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'agent_board_models.dart';
import 'code_review_models.dart';
import 'demo_workspace.dart';
import 'use_demo_workspace.dart';

part 'code_review/diff_stat.dart';
part 'code_review/finding_row.dart';
part 'code_review/review_actions.dart';

/// A patch under review, rendered from a `genui{"code_review": …}` directive.
///
/// ```text
/// genui{"code_review": {"board": "release-cut", "task": "relay-typing"}}
/// ```
///
/// This is the directive that makes the point the others cannot: it is not a
/// report, it is a control. Approving here writes to the shared workspace, so
/// the board in an earlier message moves the card to Done and the readiness
/// checklist in a later one flips its review gate — without leaving the
/// conversation, and without anything being re-sent.
class CodeReviewWidget extends HookWidget {
  const CodeReviewWidget({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final workspace = useDemoWorkspaceRef(attributes);
    final taskId = attributes['task'];
    final review = taskId is String ? demoReviews[taskId] : null;

    if (review == null) {
      return const SizedBox.shrink();
    }
    return _ReviewFrame(review: review, workspace: workspace);
  }
}

class _ReviewFrame extends StatelessWidget {
  const _ReviewFrame({required this.review, required this.workspace});

  final CodeReview review;
  final DemoWorkspace workspace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final author = agentById(review.agentId);
    final reviewer = agentById(review.reviewerId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Grid.xxs),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Grid.twelve,
              Grid.twelve,
              Grid.twelve,
              Grid.xxs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.difference_outlined,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        review.branch,
                        style: context.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Grid.half),
                Text(
                  review.title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                // Author and reviewer are named separately on purpose: the
                // whole claim is that one agent's work was checked by another.
                Text.rich(
                  TextSpan(
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: author.name,
                        style: TextStyle(
                          color: author.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' wrote it · reviewed by '),
                      TextSpan(
                        text: reviewer.name,
                        style: TextStyle(
                          color: reviewer.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Grid.twelve),
                _DiffStat(review: review),
              ],
            ),
          ),
          if (review.findings.isNotEmpty) ...[
            Divider(height: 1, color: colors.outlineVariant),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Grid.twelve,
                vertical: Grid.xxs,
              ),
              child: Column(
                children: [
                  for (final finding in review.findings)
                    _FindingRow(finding: finding),
                ],
              ),
            ),
          ],
          Divider(height: 1, color: colors.outlineVariant),
          _ReviewActions(review: review, workspace: workspace),
        ],
      ),
    );
  }
}
