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
  'Buzz needs to know a message really came from you.': '9b2ec0b24714.mp3',
  'It never asks for a password.': '29f9798b0e62.mp3',
  'It sends you a random word instead, new every time.': '13b9d82bef6c.mp3',
  'Your phone marks that word with your own secret key.': 'a80d4414b456.mp3',
  'The key itself never leaves your phone.': '52498a0be637.mp3',
  'Buzz checks the mark, and it matches.': '133d5cb6c482.mp3',
  'No password to type. Nothing for anyone to steal.': '23719773688b.mp3',
  'Work starts as an ordinary message in a channel.': '73e718aa1bc2.mp3',
  'You ask for something, the way you would ask a person.': '65af73adb676.mp3',
  'An agent in that channel picks it up.': '0f0f6c6a97d3.mp3',
  'It works in the open. Everyone can watch.': '85c8fd8eb8eb.mp3',
  'It reports back into the same channel.': 'fac355e8f3a5.mp3',
  'No dashboard. The conversation is the record.': '5d6aaef84e42.mp3',
  'You send one message to a channel.': '98c2930ef49e.mp3',
  'It reaches Buzz once, signed by you.': 'ad8d1fb297ec.mp3',
  'Buzz passes a copy to everyone in that channel.': '4e6686df632d.mp3',
  'Ravi is offline. His copy waits for him.': '895f6b63693a.mp3',
  'An agent is just another member on that list.': '5586db1d1646.mp3',
  'A channel of ten is easy.': '51d25a01f110.mp3',
  'The work grows faster than the room does.': 'e16806822dbe.mp3',
  'So Buzz sends once and lets the relay do the copying.': '7cd3b66fbb2e.mp3',
  'Every message is one small, signed record.': 'c92199e46fcb.mp3',
  'Who sent it, where, what it said, and when.': '6ae9b0a43b9b.mp3',
  'Change one character and the signature stops matching.': 'f75e9f2b335f.mp3',
  'Shipped. The whole thread is the record of why.': '76c4785be817.mp3',
  'You ask for a change, and it picks the same thread straight back up.':
      '81aa317aaddb.mp3',
};

/// How long each clip runs, in milliseconds.
///
/// The engine gives no usable "the scene has ended" signal — `playBeat`
/// resolves when the instruction list has been executed, which is long before
/// the narration it queued has finished speaking. Summing these is the only
/// honest lower bound on how long a scene actually lasts.
const Map<String, int> kNarrationDurationsMs = {
  'Buzz needs to know a message really came from you.': 2508,
  'It never asks for a password.': 1393,
  'It sends you a random word instead, new every time.': 3111,
  'Your phone marks that word with your own secret key.': 2508,
  'The key itself never leaves your phone.': 2043,
  'Buzz checks the mark, and it matches.': 1765,
  'No password to type. Nothing for anyone to steal.': 2601,
  'Work starts as an ordinary message in a channel.': 2694,
  'You ask for something, the way you would ask a person.': 2647,
  'An agent in that channel picks it up.': 1950,
  'It works in the open. Everyone can watch.': 1997,
  'It reports back into the same channel.': 1904,
  'No dashboard. The conversation is the record.': 2415,
  'You send one message to a channel.': 1904,
  'It reaches Buzz once, signed by you.': 1904,
  'Buzz passes a copy to everyone in that channel.': 2554,
  'Ravi is offline. His copy waits for him.': 2276,
  'An agent is just another member on that list.': 2090,
  'A channel of ten is easy.': 1440,
  'The work grows faster than the room does.': 2090,
  'So Buzz sends once and lets the relay do the copying.': 3019,
  'Every message is one small, signed record.': 2229,
  'Who sent it, where, what it said, and when.': 2229,
  'Change one character and the signature stops matching.': 2972,
  'Shipped. The whole thread is the record of why.': 2554,
  'You ask for a change, and it picks the same thread straight back up.': 3808,
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
