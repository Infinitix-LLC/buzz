/// One VAL demo scene. Split out per scene because the combined file was
/// closing on the repository's 1000-line ceiling.
library;

/// What a message actually is, once you look inside one.
///
/// Camera-led rather than motion-led: the scene pushes in on a single event and
/// its fields arrive one at a time, then pulls back for the point about the
/// signature.
const String kEventAnatomyScript = r'''

const WIDE = 1.0;
const NEAR = 1.5;
const MID = 1.3;

// Moves the camera and holds. `cameraCenter` and `cameraZoom` both return
// futures, and `Scene.play` awaits futures, so the two run as one move.
async function focusOn(x, y, s) {
  await Scene.play([
    Scene.cameraCenter(Vector(x, y), Duration(1.0)),
    Scene.cameraZoom(s, Duration(1.0)),
  ]);
}

// A caption placed for the shot it belongs to. Pinned to a fixed spot it would
// leave the frame the moment anything zooms, so both position and size come
// from the shot: at zoom `s` the visible half-height is 540/s, sitting 420/s
// below the focus puts it under the subject rather than on it, a wrap width of
// 900/s stops a long line running off the side, and a scale of 2.1/s renders it
// the same size on screen at every zoom level.
function captionFor(line, x, y, s) {
  const t = new Text(line, 900 / s);
  t.setColor(MUTED);
  t.setScale(2.1 / s);
  t.moveTo(Vector(x, y - 420 / s));
  return t;
}

async function say(previous, next) {
  if (previous != null) {
    await Scene.play([Scene.unCreate(previous, Duration(0.25))]);
  }
  await Scene.play([Scene.create(next, Duration(0.45))]);
}

const title = new Text("What a message really is", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const card = new Rectangle(760, 420);
card.setColor(BLUE);
card.setFillColor(PANEL);
card.setFillOpacity(0.95);
card.setStroke(6);
card.moveTo(Vector(0, 60));

function field(label, y, color) {
  const t = new Text(label, 700);
  t.setColor(color);
  t.setScale(1.9);
  t.moveTo(Vector(0, y));
  return t;
}

const f1 = field("from   you", 190, INK);
const f2 = field("in     a channel", 120, INK);
const f3 = field("says   hello", 50, INK);
const f4 = field("at     09:41", -20, INK);
const f5 = field("signed by your key", -100, GREEN);

const c1 = captionFor("Every message is one small, signed record.", 0, 0, WIDE);
const c2 = captionFor("Who sent it, where, what it said, and when.", 0, 60, MID);
const c3 = captionFor("Change one character and the signature stops matching.", 0, 60, MID);

await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([Scene.create(card, Duration(0.8))]);

await say(null, c1);
const n1 = Scene.narrate("Every message is one small, signed record.");
await Scene.play([n1.start()]);

// The title sits at the top of the wide frame and juts into the close-up.
await Scene.play([
  Scene.unCreate(c1, Duration(0.25)),
  Scene.unCreate(title, Duration(0.25)),
]);
await focusOn(0, 60, MID);
await Scene.play([Scene.create(c2, Duration(0.45))]);
await Scene.play([Scene.create(f1, Duration(0.35))]);
await Scene.play([Scene.create(f2, Duration(0.35))]);
await Scene.play([Scene.create(f3, Duration(0.35))]);
await Scene.play([Scene.create(f4, Duration(0.35))]);
await Scene.pause(Duration(0.4));
const n2 = Scene.narrate("Who sent it, where, what it said, and when.");
await Scene.play([n2.start()]);

await Scene.play([Scene.unCreate(c2, Duration(0.25))]);
await Scene.play([Scene.create(f5, Duration(0.5))]);
await Scene.play([Scene.create(c3, Duration(0.45))]);
await Scene.play([Scene.flashAround(f5, Duration(1.0))]);
await Scene.pause(Duration(0.5));
const n3 = Scene.narrate("Change one character and the signature stops matching.");
await Scene.play([n3.start()]);

await focusOn(0, 0, WIDE);
await Scene.play([Scene.create(title, Duration(0.45))]);
await Scene.pause(Duration(0.4));
''';
