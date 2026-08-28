import 'dart:async';

import 'package:flutter/material.dart';
import 'package:val_flutter/val_flutter.dart' as vf;
// The render model ships its own plain-data geometry and palette. Hiding those
// lets Flutter's own Size / Color / Offset / Rect win in widget code, while
// `paintInto` and RenderFrame still come through.
import 'package:val_player/val_player.dart'
    hide Color, Colors, Offset, Radius, Rect, Size;

import 'val_compile_client.dart';
import 'val_narration_audio.dart';

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
    this.title,
    this.followUps = const <String, String>{},
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

  /// Whether the scene compiles and plays as soon as it is built.
  ///
  /// False shows a poster and waits for a tap, which is what a scene inside a
  /// scrollable transcript wants: several autoplaying scenes run their engines
  /// at once, and a scene that starts when it is built has usually finished by
  /// the time it is scrolled into view. Waiting for the tap also defers the
  /// compile, so scrolling past a scene costs nothing at all.
  final bool autoplay;

  /// Shown on the poster. The scene's own title is drawn inside the animation,
  /// which is no help before it has started.
  final String? title;

  /// Continuations offered when the scene reaches its end, label to script.
  ///
  /// Each one plays as a further *beat* on the same player. `playBeat` is
  /// cumulative — a later beat runs on the executor the first one used, so it
  /// inherits every object already on stage and can move and recolour them.
  /// That is what makes this a branch in one continuous animation rather than a
  /// second video: the scene genuinely carries on from where the viewer chose.
  ///
  /// A continuation therefore cannot stand alone; it assumes the main script
  /// has run. Empty means the scene simply offers a replay.
  final Map<String, String> followUps;

  @override
  State<ValLocalScene> createState() => _ValLocalSceneState();
}

enum _Stage { idle, compiling, running, failed }

/// Uses the plural [TickerProviderStateMixin] deliberately.
///
/// "Show again" disposes the finished player and builds a new one, and each
/// player creates its own ticker. `SingleTickerProviderStateMixin` records the
/// first ticker and never clears that field — not even when the ticker is
/// disposed — so the second player throws "multiple tickers were created"
/// however carefully the first was torn down.
class _ValLocalSceneState extends State<ValLocalScene>
    with TickerProviderStateMixin {
  late _Stage _stage = widget.autoplay ? _Stage.compiling : _Stage.idle;
  String? _error;
  bool _finished = false;

  /// Set once a continuation has been chosen, so the choice is offered once.
  bool _branched = false;

  /// Bumped on every start, so a future belonging to a superseded run can tell
  /// that it no longer speaks for the widget.
  int _run = 0;
  int _instructionCount = 0;
  vf.LocalEnginePlayer? _player;

  @override
  void initState() {
    super.initState();
    if (widget.autoplay) {
      _start();
    }
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
      _finished = false;
      _branched = false;
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
    final run = ++_run;
    if (mounted && _stage != _Stage.compiling) {
      setState(() {
        _stage = _Stage.compiling;
        _error = null;
        _finished = false;
      });
    }
    try {
      final program =
          widget.precompiled ??
          await compileValScript(widget.script, frame: widget.frame);
      if (!mounted || run != _run) {
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
      // Pre-rendered speech ships with the app, because the engine's own
      // narration endpoint is not deployed. When every line of this scene has a
      // clip, seed them and let the normal audio path run: the beat then ends
      // when the sentence actually ends, which no estimate can match.
      final spoken = await ValNarrationAudio.seed(
        player,
        program.narrations.keys,
      );
      final allSpoken = spoken == program.narrations.length;
      final speechMs = narrationTotalMs(program.narrations.keys);
      final startedAt = DateTime.now();

      if (!allSpoken && !program.hasNarrationAudio) {
        await player.useSyntheticNarrationTiming(
          program.narrations.keys,
          // Slower than conversational speech on purpose: the narration is
          // silent here, so this is a reading pace for the caption on screen,
          // not a speaking pace. The package default (155) finishes the scene
          // in about twelve seconds, which reads as rushed.
          wordsPerMinute: 110,
        );
      }

      // Unconditional: `_start` is only ever reached because playback was
      // asked for — on build when [ValLocalScene.autoplay] is set, otherwise
      // from the poster or the replay control. Gating this on `autoplay` too
      // made a tapped scene compile, build its player, swap the poster for the
      // canvas, and then sit there painting nothing.
      //
      // Not awaited into the build: the engine runs for the length of the
      // animation, and the future completes when the script ends, not when it
      // starts painting.
      unawaited(
        player
            .playBeat(
              program.instructions,
              // Emptied when our own clips are in place. `playArtifact` seeds
              // the artifact's narrations on the way in, and the compiler
              // returns those as `{<text>: {}}` placeholders — so passing them
              // re-seeds every line with an empty audio url and overwrites the
              // clip we just registered. The symptom is `UrlSource(url: )`.
              allSpoken
                  ? const <String, Map<String, Object?>>{}
                  : program.narrations,
            )
            .then((_) => _settle(player, run, speechMs, startedAt)),
      );
    } on ValCompileException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail(e.toString());
    }
  }

  /// Waits for the scene to actually end, then offers "Show again".
  ///
  /// Two conditions, because neither is sufficient alone.
  ///
  /// `playBeat` resolves when the instruction list has been executed, which for
  /// a narrated scene is a few seconds in — long before the speech it queued
  /// has finished. And frame activity goes quiet *during* every narration hold,
  /// since a held picture publishes no frames, so "no new frames" on its own
  /// fires between beats. Waiting for the summed clip length AND a quiet
  /// stretch gets it right; waiting for either one alone put the control on
  /// screen around eight seconds into a forty-second scene.
  Future<void> _settle(
    vf.LocalEnginePlayer player,
    int run,
    int speechMs,
    DateTime startedAt,
  ) async {
    const step = Duration(milliseconds: 200);
    // Comfortably longer than the longest narration clip (3.0s), because a
    // held picture publishes no frames — so any threshold under that fires
    // between beats rather than at the end. Erring late is the right side to
    // err on: a control that appears a beat after the scene rests is
    // unremarkable, one that appears mid-scene looks broken.
    const quiet = Duration(milliseconds: 4500);
    const limit = Duration(seconds: 150);

    var lastFrameAt = DateTime.now();
    void onFrame() => lastFrameAt = DateTime.now();
    player.display.addListener(onFrame);

    try {
      final speech = Duration(milliseconds: speechMs);
      while (true) {
        await Future<void>.delayed(step);
        if (!mounted || run != _run) {
          return;
        }
        final elapsed = DateTime.now().difference(startedAt);
        if (elapsed > limit) {
          break;
        }
        final spoken = elapsed >= speech;
        final settled = DateTime.now().difference(lastFrameAt) >= quiet;
        if (spoken && settled && !player.hasActiveAnimations) {
          break;
        }
      }
    } finally {
      player.display.removeListener(onFrame);
    }

    // Checked against the run this future belongs to: "Show again" starts a new
    // player while the previous one's future is still outstanding, and that
    // future resolves regardless of the disposal. Without the guard it marks
    // the *new* run finished the moment the old one ends.
    if (mounted && run == _run) {
      setState(() => _finished = true);
    }
  }

  /// Plays [script] as a further beat on the player already on screen.
  Future<void> _playFollowUp(String script) async {
    final player = _player;
    if (player == null) {
      return;
    }
    final run = _run;
    setState(() {
      _branched = true;
      _finished = false;
    });
    try {
      final program = await compileValScript(
        script,
        frame: widget.frame,
        previousScript: widget.script,
      );
      if (!mounted || run != _run) {
        return;
      }
      final spoken = await ValNarrationAudio.seed(
        player,
        program.narrations.keys,
      );
      final allSpoken = spoken == program.narrations.length;
      final speechMs = narrationTotalMs(program.narrations.keys);
      final startedAt = DateTime.now();
      if (!allSpoken && !program.hasNarrationAudio) {
        await player.useSyntheticNarrationTiming(
          program.narrations.keys,
          wordsPerMinute: 110,
        );
      }
      unawaited(
        player
            .playBeat(
              program.instructions,
              allSpoken
                  ? const <String, Map<String, Object?>>{}
                  : program.narrations,
            )
            .then((_) => _settle(player, run, speechMs, startedAt)),
      );
    } on Object catch (e) {
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
          _Stage.idle => _Poster(title: widget.title, onPlay: _start),
          _Stage.compiling => const _Centered(child: _Compiling()),
          _Stage.failed => _Centered(child: _Failed(message: _error)),
          _Stage.running when player == null => const _Centered(
            child: _Compiling(),
          ),
          _Stage.running => Stack(
            fit: StackFit.expand,
            children: [
              _LocalCanvas(player: player!, background: widget.background),
              // Only once the script has run out: a replay control competing
              // with the animation would pull the eye off it.
              if (_finished)
                if (widget.followUps.isNotEmpty && !_branched)
                  _ChoiceOverlay(
                    choices: widget.followUps,
                    onChoose: _playFollowUp,
                  )
                else
                  _ReplayOverlay(onReplay: _restart),
            ],
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

/// The tap target shown before a scene has been started.
///
/// Deliberately not a play button on a black rectangle. This is not a video —
/// nothing is streamed, nothing is buffered, and there is no file. A play
/// triangle sets the wrong expectation about what the thing is, and invites
/// the wrong question ("how big is it?", "does it work offline?"). A worded
/// invitation reads as part of the answer instead.
class _Poster extends StatelessWidget {
  const _Poster({required this.onPlay, this.title});

  final VoidCallback onPlay;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = title;
    return InkWell(
      onTap: onPlay,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (name != null && name.isNotEmpty) ...[
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
              ],
              // A scene can be laid out narrow — a reels frame, or a phone in
              // portrait — and the pill is a fixed-width row, so it must be
              // allowed to shrink rather than overflow its own poster.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See how it works',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Offered once the scene has played through.
///
/// A dimming overlay with the control in the middle, rather than a corner
/// button. Every corner is occupied by the scene itself — the title runs along
/// the top and the closing caption along the bottom — so a corner control
/// landed on top of one or the other. Covering the frame also makes the state
/// unambiguous: the scene has ended, and this is what to do about it.
class _ReplayOverlay extends StatelessWidget {
  const _ReplayOverlay({required this.onReplay});

  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: onReplay,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  child: Text(
                    'Show again',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The question the scene stops to ask, and the answers it will act on.
///
/// Deliberately the same visual language as the replay overlay: the scene dims
/// and the controls sit in the middle, so "it has paused for you" reads the
/// same way whether what follows is a branch or a replay.
class _ChoiceOverlay extends StatelessWidget {
  const _ChoiceOverlay({required this.choices, required this.onChoose});

  final Map<String, String> choices;
  final void Function(String script) onChoose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'What do you do?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final entry in choices.entries) ...[
                        _ChoiceChip(
                          label: entry.key,
                          onTap: () => onChoose(entry.value),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
