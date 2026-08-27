import 'package:flutter/widgets.dart';
import 'package:gpt_markdown/gpt_chat_gateway.dart';

/// Supplies the artifact store a `val_scene` card needs.
///
/// `ValArtifactCard` reads its live status from an [ArtifactScope] above it. In
/// this demo the scenes arrive already `ready` — the gateway generated them
/// before the message was posted — and the store never watches a terminal
/// artifact, so nothing here polls. It exists to satisfy the card's contract
/// and to be the seam where real generation would plug in.
///
/// Playback itself needs none of this: the render endpoint is unauthenticated,
/// so a ready scene plays from its id alone.
class ValArtifactScope extends StatefulWidget {
  const ValArtifactScope({super.key, required this.child});

  final Widget child;

  @override
  State<ValArtifactScope> createState() => _ValArtifactScopeState();
}

class _ValArtifactScopeState extends State<ValArtifactScope> {
  late final ArtifactStore _store = _DemoArtifactStore();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ArtifactScope(store: _store, child: widget.child);
  }
}

/// A store that reports what it was given and never calls out.
///
/// The demo has no gateway credentials, so watching a not-yet-ready artifact
/// reaches the gateway unauthenticated, comes back 400, and paints the card as
/// **Failed** — a scene that is merely still rendering looks broken. Every
/// scene here arrives `ready` anyway; this makes the other case degrade to
/// "still working" rather than to a lie.
class _DemoArtifactStore extends ArtifactStore {
  _DemoArtifactStore()
    : super(
        repository: ArtifactRepository(
          service: ArtifactService(config: const PlusfinityConfig(apiKey: '')),
        ),
      );

  @override
  void track(ValArtifact artifact) {}
}
