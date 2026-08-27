import 'dart:async';

import 'package:flutter/material.dart';
import 'package:val_flutter/val_flutter.dart' as vf;
// The render model ships its own plain-data geometry and palette. Hiding those
// lets Flutter's own Size / Color / Offset / Rect win in widget code, while
// `paintInto` and RenderFrame still come through.
import 'package:val_player/val_player.dart'
    hide Color, Colors, Offset, Radius, Rect, Size;

import 'val_compile_client.dart';

/// Runs a VAL script on the device.
///
/// The script is hardcoded in the app. The server compiles it — that is the one
/// step a phone cannot do, and it is a pure function of the source — and the
/// engine then executes the returned instruction list locally, publishing a
/// frame per tick. Nothing is stored server-side, no artifact id is involved,
/// and the same source produces the same run every time.
///
/// This is the counterpart to the streamed player in `gpt_markdown`, which asks
/// the server to *run* a stored artifact and receives pixels. Here the server
/// only compiles, and the run happens here.
class ValLocalScene extends StatefulWidget {
  const ValLocalScene({
    super.key,
    required this.script,
    this.frame = 'landscape',
    this.background = const Color(0xFF0E0E12),
    this.autoplay = true,
    this.precompiled,
  });

  final String script;

  /// An already-compiled program, used instead of calling the compiler.
  ///
  /// The compile is one network round trip, which a widget test cannot make —
  /// the test binding's fake clock never lets a real socket resolve. Injecting
  /// the program is what lets the engine and the painter be tested for real
  /// rather than mocked away.
  final CompiledValProgram? precompiled;

  /// The frame the script was authored against. Getting this wrong does not
  /// letterbox — it resolves every frame-relative placement (`frame.topCenter`
  /// and friends) against the wrong rect, so the composition comes apart.
  final String frame;

  final Color background;
  final bool autoplay;

  @override
  State<ValLocalScene> createState() => _ValLocalSceneState();
}

enum _Stage { compiling, running, failed }

class _ValLocalSceneState extends State<ValLocalScene>
    with SingleTickerProviderStateMixin {
  _Stage _stage = _Stage.compiling;
  String? _error;
  int _instructionCount = 0;
  vf.LocalEnginePlayer? _player;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant ValLocalScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.script != widget.script || oldWidget.frame != widget.frame) {
      _restart();
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _restart() {
    _player?.dispose();
    _player = null;
    setState(() {
      _stage = _Stage.compiling;
      _error = null;
    });
    _start();
  }

  /// Wires VAL's asset loader, cache dir, text measurer and stroke rasterizer
  /// to their Flutter implementations.
  ///
  /// Must run before any player is constructed. Skipping it does not throw —
  /// the scene renders with an unwired text measurer, so every glyph comes out
  /// as a box and the failure looks like a missing font rather than a missing
  /// call. Idempotent, so calling it per scene is free.
  static bool _bootstrapped = false;

  static void _bootstrapVal() {
    if (_bootstrapped) {
      return;
    }
    vf.initValFlutter();
    _bootstrapped = true;
  }

  Future<void> _start() async {
    _bootstrapVal();
    try {
      final program =
          widget.precompiled ??
          await compileValScript(widget.script, frame: widget.frame);
      if (!mounted) {
        return;
      }

      // Built after the compile rather than in initState: the player starts a
      // ticker on construction, and starting one that then sits idle through a
      // network round trip burns frames for nothing.
      final player = vf.LocalEnginePlayer(vsync: this, frame: widget.frame);
      // Assigned as separate statements, not a cascade: `..onLog = (m) => …`
      // parses the arrow body as part of the cascade chain and misbinds.
      player.onLog = _log;
      player.onValException = _valException;
      player.startSession();
      _player = player;

      setState(() {
        _stage = _Stage.running;
        _instructionCount = program.instructions.length;
      });

      // `validate-val-artifact` compiles instructions and returns the narration
      // *text* with an empty body — no audio URL, no word marks. Left as is,
      // the first `narrate(...)` misses the seed cache, falls through to a live
      // TTS fetch, and when that fails the engine cancels every pending cue, so
      // the scene freezes half-drawn. Synthetic timing keeps the beats paced;
      // muting alone would collapse them all onto one frame.
      if (!program.hasNarrationAudio) {
        await player.useSyntheticNarrationTiming(program.narrations.keys);
      }

      if (widget.autoplay) {
        // Not awaited into the build: the engine runs for the length of the
        // animation, and the future completes when the script ends, not when
        // it starts painting.
        unawaited(player.playBeat(program.instructions, program.narrations));
      }
    } on ValCompileException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
  }

  void _log(String message) => debugPrint('VAL script: $message');

  /// The engine reports a runtime fault and keeps its remaining instructions
  /// unexecuted, so the scene freezes wherever it got to. Without this hook the
  /// only trace is an unattributed `ValRuntimeException` on stderr.
  void _valException(String message, int position) {
    debugPrint('VAL runtime fault at instruction $position: $message');
  }

  void _fail(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _stage = _Stage.failed;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.background),
        child: switch (_stage) {
          _Stage.compiling => const _Centered(child: _Compiling()),
          _Stage.failed => _Centered(child: _Failed(message: _error)),
          _Stage.running when player == null => const _Centered(
            child: _Compiling(),
          ),
          _Stage.running => _LocalCanvas(
            player: player!,
            background: widget.background,
          ),
        },
      ),
    );
  }

  /// Instruction count, for a caller that wants to show what it is running.
  int get instructionCount => _instructionCount;
}

/// Paints whatever frame the engine last published.
class _LocalCanvas extends StatelessWidget {
  const _LocalCanvas({required this.player, required this.background});

  final vf.LocalEnginePlayer player;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    return CustomPaint(
      size: Size.infinite,
      painter: _LocalScenePainter(player, pixelRatio, background),
    );
  }
}

class _LocalScenePainter extends CustomPainter {
  // Repainting off the player's own notifier, not off widget rebuilds: the
  // engine publishes a frame per tick and calling setState that often would
  // rebuild the tree sixty times a second for a picture that never changes
  // shape.
  _LocalScenePainter(this.player, this.pixelRatio, this.background)
    : super(repaint: player.display);

  final vf.LocalEnginePlayer player;
  final double pixelRatio;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = player.currentFrame;
    if (frame == null) {
      canvas.drawRect(Offset.zero & size, Paint()..color = background);
      return;
    }
    paintInto(
      canvas,
      Offset.zero & size,
      frame,
      // The engine composes against its own canvas, which is the authored
      // frame's size — not the box this widget happens to occupy.
      referenceCanvasSize: player.referenceCanvasSize,
      pixelRatio: pixelRatio,
      background: background,
    );
  }

  @override
  bool shouldRepaint(covariant _LocalScenePainter oldDelegate) => true;
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}

class _Compiling extends StatelessWidget {
  const _Compiling();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 10),
        Text(
          'Compiling scene',
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 20, color: colors.error),
          const SizedBox(height: 8),
          Text(
            // The compiler names the line and column, which is the only part
            // worth showing — swallowing it leaves a blank canvas and no idea
            // why.
            message ?? 'Scene failed to compile',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.error),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
