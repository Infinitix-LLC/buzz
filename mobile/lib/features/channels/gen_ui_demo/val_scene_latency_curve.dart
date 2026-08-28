/// One VAL demo scene. Split out per scene because the combined file was
/// closing on the repository's 1000-line ceiling.
library;

/// Why a big channel costs more than a small one.
///
/// A different side of the engine from the box-and-arrow scenes: a real axis,
/// a curve plotted from a function at run time, and typeset maths — none of it
/// an image, all of it drawn on the device.
const String kLatencyCurveScript = r'''

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

const title = new Text("Why a big channel costs more", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const axes = new Axis(new Range(0, 10, 2), new Range(0, 10, 2));
axes.setColor(MUTED);
axes.setStroke(3);
axes.setScale(1.5);
axes.moveTo(Vector(-150, 60));

const xLabel = new Text("people in the channel", 700);
xLabel.setColor(MUTED);
xLabel.setScale(1.8);
xLabel.moveTo(Vector(-150, -250));

const yLabel = new Text("work per message", 600);
yLabel.setColor(MUTED);
yLabel.setScale(1.8);
yLabel.moveTo(Vector(-330, 350));

const c1 = captionFor("A channel of ten is easy.", 0, 0, WIDE);
const c2 = captionFor("The work grows faster than the room does.", -150, 60, MID);
const c3 = captionFor("So Buzz sends once and lets the relay do the copying.", 0, 0, WIDE);

await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([Scene.create(axes, Duration(0.9))]);
await Scene.play([
  Scene.create(xLabel, Duration(0.4)),
  Scene.create(yLabel, Duration(0.4)),
]);

await say(null, c1);
const n1 = Scene.narrate("A channel of ten is easy.");
await Scene.play([n1.start()]);

const curve = axes.getEquation((x) => x * x / 10);
curve.setColor(ORANGE);
curve.setStroke(6);

// The title sits at the top of the wide frame and juts into every close-up.
await Scene.play([
  Scene.unCreate(c1, Duration(0.25)),
  Scene.unCreate(title, Duration(0.25)),
]);
await focusOn(-150, 60, MID);
await Scene.play([Scene.create(c2, Duration(0.45))]);
await Scene.play([Scene.create(curve, Duration(1.8))]);
await Scene.pause(Duration(0.5));
const n2 = Scene.narrate("The work grows faster than the room does.");
await Scene.play([n2.start()]);

const formula = new MathTex("n^2");
formula.setColor(ORANGE);
formula.setScale(3.8);
formula.moveTo(Vector(400, 220));

const fix = new MathTex("n");
fix.setColor(BLUE);
fix.setScale(3.8);
fix.moveTo(Vector(400, 220));

await Scene.play([Scene.unCreate(c2, Duration(0.25))]);
await focusOn(0, 0, WIDE);
await Scene.play([
  Scene.create(title, Duration(0.45)),
  Scene.create(formula, Duration(0.8)),
]);
await Scene.play([Scene.create(c3, Duration(0.45))]);
await Scene.play([Scene.transform(formula, fix, Duration(1.1))]);
await Scene.pause(Duration(0.5));
const n3 = Scene.narrate("So Buzz sends once and lets the relay do the copying.");
await Scene.play([n3.start()]);
''';
