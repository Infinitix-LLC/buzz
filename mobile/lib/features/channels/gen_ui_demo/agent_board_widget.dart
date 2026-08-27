import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/theme/grid.dart';
import '../../../shared/theme/theme_extensions.dart';
import 'demo_workspace.dart';
import 'agent_board_models.dart';
import 'pulsing_dot.dart';
import 'use_demo_workspace.dart';

part 'agent_board/board_header.dart';
part 'agent_board/board_column.dart';
part 'agent_board/task_card.dart';

/// A live task board, rendered from a `genui{"agent_board": …}` directive
/// inside a channel message.
///
/// The payload names a board rather than carrying a snapshot of it:
///
/// ```text
/// genui{"agent_board": {"board": "release-cut", "title": "Release cut · 0.6.0"}}
/// ```
///
/// That shape is the point. A snapshot would be stale the moment the message
/// was posted; naming a board lets the widget subscribe and keep telling the
/// truth as agents work. Here the subscription is a scripted clock; against a
/// real workspace it would be the observer relay, and nothing else in this
/// file would change.
class AgentBoardWidget extends HookWidget {
  const AgentBoardWidget({super.key, required this.attributes});

  final Map<String, dynamic> attributes;

  @override
  Widget build(BuildContext context) {
    final title = attributes['title'];
    return _BoardFrame(
      title: title is String ? title : 'Agent board',
      snapshot: useDemoWorkspace(attributes),
    );
  }
}

class _BoardFrame extends StatelessWidget {
  const _BoardFrame({required this.title, required this.snapshot});

  final String title;
  final BoardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
          _BoardHeader(title: title, snapshot: snapshot),
          Divider(height: 1, color: colors.outlineVariant),
          // The board is wider than a message bubble by design — one that fits
          // without scrolling is a list, and loses the column metaphor that
          // makes a board readable at a glance.
          SizedBox(
            // Tall enough for the busiest column at its peak — four cards in
            // "In progress" around the 40s mark, including a blocked one,
            // which carries an extra pill and a two-line reason. Sized short,
            // the last card hides behind an inner scroll and the board
            // silently under-reports the work it exists to show.
            height: 396,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(Grid.twelve),
              itemCount: BoardColumn.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: Grid.xxs),
              itemBuilder: (context, index) => _Column(
                column: BoardColumn.values[index],
                snapshot: snapshot,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
