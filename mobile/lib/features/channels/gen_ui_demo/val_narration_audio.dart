import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:val_flutter/val_flutter.dart' as vf;

/// Pre-rendered speech for every line the demo scenes narrate.
///
/// The VAL engine fetches narration audio from a `synthesize-narration`
/// endpoint that is **not deployed** — it answers 404, which is what used to
/// leave a scene frozen half-drawn. `bakeTimeline` embeds no narration clips
/// either. So the audio ships with the app instead: generated once with macOS
/// `say`, keyed by the exact `Scene.narrate` string.
///
/// Keyed by that string because `seedNarration` writes into a cache the engine
/// looks up by the byte-identical narrate argument. Change a line in a script
/// and its clip stops being found — the scene then falls back to silent
/// synthetic timing rather than breaking, but it will not speak.
const Map<String, String> kNarrationClips = {
  'Buzz needs to know a message really came from you.': '9b2ec0b24714.m4a',
  'It never asks for a password.': '29f9798b0e62.m4a',
  'It sends you a random word instead, new every time.': '13b9d82bef6c.m4a',
  'Your phone marks that word with your own secret key.': 'a80d4414b456.m4a',
  'The key itself never leaves your phone.': '52498a0be637.m4a',
  'Buzz checks the mark, and it matches.': '133d5cb6c482.m4a',
  'No password to type. Nothing for anyone to steal.': '23719773688b.m4a',
  'Work starts as an ordinary message in a channel.': '73e718aa1bc2.m4a',
  'You ask for something, the way you would ask a person.': '65af73adb676.m4a',
  'An agent in that channel picks it up.': '0f0f6c6a97d3.m4a',
  'It works in the open. Everyone can watch.': '85c8fd8eb8eb.m4a',
  'It reports back into the same channel.': 'fac355e8f3a5.m4a',
  'No dashboard. The conversation is the record.': '5d6aaef84e42.m4a',
  'You send one message to a channel.': '98c2930ef49e.m4a',
  'It reaches Buzz once, signed by you.': 'ad8d1fb297ec.m4a',
  'Buzz passes a copy to everyone in that channel.': '4e6686df632d.m4a',
  'Ravi is offline. His copy waits for him.': '895f6b63693a.m4a',
  'An agent is just another member on that list.': '5586db1d1646.m4a',
  'A channel of ten is easy.': '51d25a01f110.m4a',
  'The work grows faster than the room does.': 'e16806822dbe.m4a',
  'So Buzz sends once and lets the relay do the copying.': '7cd3b66fbb2e.m4a',
  'Every message is one small, signed record.': 'c92199e46fcb.m4a',
  'Who sent it, where, what it said, and when.': '6ae9b0a43b9b.m4a',
  'Change one character and the signature stops matching.': 'f75e9f2b335f.m4a',
};

/// How long each clip runs, in milliseconds.
///
/// The engine gives no usable "the scene has ended" signal — `playBeat`
/// resolves when the instruction list has been executed, which is long before
/// the narration it queued has finished speaking. Summing these is the only
/// honest lower bound on how long a scene actually lasts.
const Map<String, int> kNarrationDurationsMs = {
  'Buzz needs to know a message really came from you.': 2500,
  'It never asks for a password.': 1703,
  'It sends you a random word instead, new every time.': 2992,
  'Your phone marks that word with your own secret key.': 2662,
  'The key itself never leaves your phone.': 1939,
  'Buzz checks the mark, and it matches.': 2140,
  'No password to type. Nothing for anyone to steal.': 2967,
  'Work starts as an ordinary message in a channel.': 2556,
  'You ask for something, the way you would ask a person.': 2848,
  'An agent in that channel picks it up.': 1819,
  'It works in the open. Everyone can watch.': 2492,
  'It reports back into the same channel.': 2028,
  'No dashboard. The conversation is the record.': 2851,
  'You send one message to a channel.': 1780,
  'It reaches Buzz once, signed by you.': 2376,
  'Buzz passes a copy to everyone in that channel.': 2500,
  'Ravi is offline. His copy waits for him.': 2781,
  'An agent is just another member on that list.': 2411,
  'A channel of ten is easy.': 1424,
  'The work grows faster than the room does.': 1985,
  'So Buzz sends once and lets the relay do the copying.': 2870,
  'Every message is one small, signed record.': 2701,
  'Who sent it, where, what it said, and when.': 2851,
  'Change one character and the signature stops matching.': 2923,
};

/// Total speech time for [texts], in milliseconds. Unknown lines count zero.
int narrationTotalMs(Iterable<String> texts) =>
    texts.fold(0, (sum, t) => sum + (kNarrationDurationsMs[t] ?? 0));

/// Copies the bundled clips out to real files and seeds them into the engine.
///
/// A file rather than the asset bundle because playback goes through
/// `UrlSource`, which wants something the platform player can open; asset URIs
/// are not that. Copied once per launch and reused.
///
/// Marks are left empty deliberately. They exist to place `atWord` cues, and no
/// demo script uses one — every beat is sequenced by awaiting the narration.
/// With no marks the hold simply ends when the clip does, which is exactly the
/// pacing we want and is strictly more accurate than any estimate.
class ValNarrationAudio {
  ValNarrationAudio._();

  static Directory? _dir;
  static final Set<String> _seeded = <String>{};

  /// Whether [seed] has a clip for every one of [texts].
  static bool hasAll(Iterable<String> texts) =>
      texts.every(kNarrationClips.containsKey);

  /// Seeds the clips for [texts] into [player]. Returns the number seeded.
  static Future<int> seed(
    vf.LocalEnginePlayer player,
    Iterable<String> texts,
  ) async {
    var count = 0;
    for (final text in texts) {
      final asset = kNarrationClips[text];
      if (asset == null) {
        continue;
      }
      if (_seeded.contains(text)) {
        count++;
        continue;
      }
      try {
        final path = await _materialise(asset);
        player.seedNarration(text, path);
        _seeded.add(text);
        count++;
      } on Object {
        // A clip that will not copy is not worth failing a scene over; it
        // plays silent and the visuals still run.
      }
    }
    return count;
  }

  static Future<String> _materialise(String asset) async {
    final dir = _dir ??= await getTemporaryDirectory();
    final file = File('${dir.path}/val_narration_$asset');
    if (!file.existsSync()) {
      final bytes = await rootBundle.load('assets/narration/$asset');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    }
    // `file://`, not a bare path: playback goes through `UrlSource`, and on
    // iOS AVPlayer rejects a plain filesystem path with
    // "AVPlayerItem.Status.failed on setSourceUrl".
    return file.uri.toString();
  }
}
