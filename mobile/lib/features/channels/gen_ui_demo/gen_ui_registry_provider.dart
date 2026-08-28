import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'agent_board_widget.dart';
import 'agent_progress_widget.dart';
import 'ci_run_widget.dart';
import 'code_review_widget.dart';
import 'release_readiness_widget.dart';
import 'val_demo_script.dart';
import 'val_local_scene.dart';

/// The gen-UI registry every channel message renders with.
///
/// `GenUiRegistry.defaults()` brings the widget types gpt_markdown ships —
/// charts, metric grids, timelines, progress lists, images, buttons. On top of
/// those, Buzz registers the two types that only mean something here:
///
/// * `agent_board` — the task board across agents
/// * `agent_progress` — per-agent progress for that board
///
/// That split is the whole extension story. A workspace does not need the
/// renderer to ship a widget for its own domain; it registers one, and its
/// agents can then emit it in an ordinary message.
final genUiRegistryProvider = Provider<GenUiRegistry>((ref) {
  // `chatGenUiRegistry` adds `val_scene` on top of the defaults, so a VAL
  // animation renders through the same path as a chart rather than being
  // special-cased in the bubble. Its streamed implementation is replaced
  // below, so the `ValArtifactScope` in `message_content.dart` is no longer
  // load-bearing — it is left in place for the day streaming comes back.
  return chatGenUiRegistry(
      GenUiRegistry.defaults(
        // A type nobody has registered is a host's gap, not a parse failure.
        // Rendering a quiet marker beats a blank line that looks like the
        // message simply failed to arrive.
        unknownBuilder: (context, model) => _UnknownType(type: model.type),
      ),
    )
    ..register(
      'agent_board',
      (context, model) => AgentBoardWidget(attributes: model.attributes),
    )
    ..register(
      'agent_progress',
      (context, model) => AgentProgressWidget(attributes: model.attributes),
    )
    ..register(
      'code_review',
      (context, model) => CodeReviewWidget(attributes: model.attributes),
    )
    ..register(
      'release_readiness',
      (context, model) => ReleaseReadinessWidget(attributes: model.attributes),
    )
    ..register(
      'ci_run',
      (context, model) => CiRunWidget(attributes: model.attributes),
    )
    // Replaces the streamed `val_scene` that `chatGenUiRegistry` adds, for
    // every payload including one carrying an artifact `id`.
    //
    // The streamed version renders a poster with a play button and opens the
    // scene in a modal sheet. A scene that plays inline the moment it arrives
    // reads as part of the answer instead of as an attachment to open, so the
    // demo uses the local engine everywhere and ignores `id` entirely.
    ..register('val_scene', (context, model) {
      final scene = genUiString(model.attributes['scene']);
      final frame = genUiString(model.attributes['frame']) ?? 'landscape';
      return AspectRatio(
        aspectRatio: switch (frame) {
          'reels' => 9 / 16,
          'square' => 1,
          _ => 16 / 9,
        },
        // Tap to start, never on build: a transcript can hold several scenes,
        // and autoplaying them all runs that many engines at once while each
        // one finishes before it is scrolled to.
        child: ValLocalScene(
          script: valDemoScript(scene),
          frame: frame,
          autoplay: false,
          title: genUiString(model.attributes['name']),
          followUps: valDemoFollowUps(scene),
        ),
      );
    });
});

class _UnknownType extends StatelessWidget {
  const _UnknownType({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        'Unsupported widget: $type',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
      ),
    );
  }
}
