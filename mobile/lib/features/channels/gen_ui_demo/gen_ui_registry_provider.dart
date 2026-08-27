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
  // special-cased in the bubble. It needs a `ValArtifactScope` above it.
  final registry = chatGenUiRegistry(
    GenUiRegistry.defaults(
      // A type nobody has registered is a host's gap, not a parse failure.
      // Rendering a quiet marker beats a blank line that looks like the
      // message simply failed to arrive.
      unknownBuilder: (context, model) => _UnknownType(type: model.type),
    ),
  );

  // Captured before the override below replaces it.
  final streamedScene = registry.builderFor('val_scene');

  return registry
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
    // Extends, rather than replaces, the streamed `val_scene` that
    // `chatGenUiRegistry` adds — the two are different mechanisms behind one
    // directive, and which one applies is decided by the payload:
    //
    //   `id` present -> a stored artifact the server renders and streams.
    //   no `id`      -> the script is in the app, the server only compiles it,
    //                   and the engine runs the instruction list on-device.
    //
    // Overriding unconditionally would strip the streamed path out of the demo
    // entirely, including the poster and progress states the gateway drives.
    ..register('val_scene', (context, model) {
      final id = genUiString(model.attributes['id']);
      if (id != null && id.isNotEmpty && streamedScene != null) {
        return streamedScene(context, model);
      }

      final frame = genUiString(model.attributes['frame']) ?? 'landscape';
      return AspectRatio(
        aspectRatio: switch (frame) {
          'reels' => 9 / 16,
          'square' => 1,
          _ => 16 / 9,
        },
        child: ValLocalScene(script: kNip42HandshakeScript, frame: frame),
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
