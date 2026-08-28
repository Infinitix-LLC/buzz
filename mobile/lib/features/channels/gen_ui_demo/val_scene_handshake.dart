/// One VAL demo scene. Split out per scene because the combined file was
/// closing on the repository's 1000-line ceiling.
library;

/// Raw so a backslash in the script stays a backslash. VAL uses them in its
/// own escapes, and Dart would otherwise eat them before the compiler ever
/// sees the source.
///
/// Layout notes, since getting these wrong is what makes a scene look broken:
/// the landscape frame is 1920x1080 with the origin at the centre and **+y up**.
/// Text renders at 20px * scale, and a `Text`'s second argument is a wrap width
/// in *final* pixels — so a caption at scale 2.2 needs roughly 22px per
/// character of room, and anything tighter silently wraps mid-word.
const String kNip42HandshakeScript = r'''
const INK = Color(0xFFE8F0FA);
const MUTED = Color(0xFF93A9C4);
const BLUE = Color(0xFF4C9AFF);
const GREEN = Color(0xFF35D07F);
const ORANGE = Color(0xFFFFA62B);
const PANEL = Color(0xFF142235);

const WIDE = 1.0;
const NEAR = 1.5;
const MID = 1.3;

const title = new Text("How Buzz knows it is really you", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const phone = new Rectangle(320, 400);
phone.setColor(BLUE);
phone.setFillColor(PANEL);
phone.setFillOpacity(0.9);
phone.setStroke(6);
phone.moveTo(Vector(-620, 40));

const phoneLabel = new Text("Your phone", 420);
phoneLabel.setColor(INK);
phoneLabel.setScale(2.2);
phoneLabel.moveTo(Vector(-620, 300));

const relay = new Rectangle(320, 400);
relay.setColor(BLUE);
relay.setFillColor(PANEL);
relay.setFillOpacity(0.9);
relay.setStroke(6);
relay.moveTo(Vector(620, 40));

const relayLabel = new Text("Buzz", 420);
relayLabel.setColor(INK);
relayLabel.setScale(2.2);
relayLabel.moveTo(Vector(620, 300));

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

const c1 = captionFor("Buzz needs to know a message really came from you.", 0, 0, WIDE);
const c2 = captionFor("It never asks for a password.", -620, 40, NEAR);
const c3 = captionFor("It sends you a random word instead, new every time.", 0, 40, MID);
const c4 = captionFor("Your phone marks that word with your own secret key.", -620, 40, NEAR);
const c5 = captionFor("The key itself never leaves your phone.", -620, 40, NEAR);
const c6 = captionFor("Buzz checks the mark, and it matches.", 620, 40, NEAR);
const c7 = captionFor("No password to type. Nothing for anyone to steal.", 0, 0, WIDE);

// --- establishing shot -----------------------------------------------------
await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([
  Scene.create(phone, Duration(0.6)),
  Scene.create(relay, Duration(0.6)),
]);
await Scene.play([
  Scene.create(phoneLabel, Duration(0.4)),
  Scene.create(relayLabel, Duration(0.4)),
]);

await say(null, c1);
const n1 = Scene.narrate("Buzz needs to know a message really came from you.");
await Scene.play([n1.start()]);

// --- push in on the phone and its key ---------------------------------------
const keyRing = new Circle(26);
keyRing.setColor(ORANGE);
keyRing.setStroke(7);
keyRing.moveTo(Vector(-672, 80));

const keyStem = new Line(Vector(-648, 80), Vector(-558, 80));
keyStem.setColor(ORANGE);
keyStem.setStroke(9);

const keyTooth = new Line(Vector(-586, 80), Vector(-586, 48));
keyTooth.setColor(ORANGE);
keyTooth.setStroke(9);

const keyLabel = new Text("your secret key", 420);
keyLabel.setColor(ORANGE);
keyLabel.setScale(1.8);
keyLabel.moveTo(Vector(-620, -100));

// The title lives at the top of the wide frame and juts into every close-up.
await Scene.play([
  Scene.unCreate(c1, Duration(0.25)),
  Scene.unCreate(title, Duration(0.25)),
]);
await focusOn(-620, 40, NEAR);
await Scene.play([Scene.create(c2, Duration(0.45))]);
await Scene.play([
  Scene.create(keyRing, Duration(0.4)),
  Scene.create(keyStem, Duration(0.4)),
  Scene.create(keyTooth, Duration(0.4)),
]);
await Scene.play([Scene.create(keyLabel, Duration(0.4))]);
await Scene.play([Scene.flashAround(keyRing, Duration(0.9))]);
await Scene.pause(Duration(0.45));
const n2 = Scene.narrate("It never asks for a password.");
await Scene.play([n2.start()]);

// --- the random word travels across ------------------------------------------
const card = new Rectangle(300, 120);
card.setColor(INK);
card.setFillColor(PANEL);
card.setFillOpacity(1.0);
card.setStroke(5);
card.moveTo(Vector(620, 40));

const word = new Text("sunset-4172", 260);
word.setColor(INK);
word.setScale(1.9);
word.moveTo(Vector(620, 40));

await Scene.play([Scene.unCreate(c2, Duration(0.25))]);
await Scene.play([
  Scene.cameraCenter(Vector(0, 40), Duration(1.2)),
  Scene.cameraZoom(MID, Duration(1.2)),
  Scene.create(card, Duration(0.6)),
  Scene.create(word, Duration(0.6)),
]);
await Scene.play([Scene.create(c3, Duration(0.45))]);
await Scene.play([
  card.animatedMoveTo(Vector(-180, 40), Duration(1.2)),
  word.animatedMoveTo(Vector(-180, 40), Duration(1.2)),
  Scene.showPassingFlash(card, Duration(1.2)),
]);
await Scene.pause(Duration(0.4));
const n3 = Scene.narrate("It sends you a random word instead, new every time.");
await Scene.play([n3.start()]);

// --- the phone marks it -------------------------------------------------------
const mark = new Polyline([
  Vector(-26, 0),
  Vector(-6, -22),
  Vector(30, 24),
]);
mark.setColor(GREEN);
mark.setStroke(10);
mark.moveTo(Vector(-460, -60));

await Scene.play([Scene.unCreate(c3, Duration(0.25))]);
await Scene.play([
  Scene.cameraCenter(Vector(-620, 40), Duration(1.2)),
  Scene.cameraZoom(NEAR, Duration(1.2)),
  card.animatedMoveTo(Vector(-460, 40), Duration(1.2)),
  word.animatedMoveTo(Vector(-460, 40), Duration(1.2)),
]);
await Scene.play([Scene.create(c4, Duration(0.45))]);
await Scene.play([
  card.animatedColor(GREEN, Duration(0.6)),
  Scene.create(mark, Duration(0.7)),
]);
await Scene.pause(Duration(0.45));
const n4 = Scene.narrate("Your phone marks that word with your own secret key.");
await Scene.play([n4.start()]);

// --- and the key stays put ------------------------------------------------------
await Scene.play([Scene.unCreate(c4, Duration(0.25))]);
await Scene.play([Scene.create(c5, Duration(0.45))]);
await Scene.play([Scene.flashAround(phone, Duration(1.0))]);
await Scene.pause(Duration(0.45));
const n5 = Scene.narrate("The key itself never leaves your phone.");
await Scene.play([n5.start()]);

// --- back to Buzz to check it ------------------------------------------------
await Scene.play([Scene.unCreate(c5, Duration(0.25))]);
await Scene.play([
  Scene.cameraCenter(Vector(620, 40), Duration(1.2)),
  Scene.cameraZoom(NEAR, Duration(1.2)),
  card.animatedMoveTo(Vector(400, 40), Duration(1.2)),
  word.animatedMoveTo(Vector(400, 40), Duration(1.2)),
  mark.animatedMoveTo(Vector(400, -60), Duration(1.2)),
  Scene.showPassingFlash(card, Duration(1.2)),
]);
await Scene.play([Scene.create(c6, Duration(0.45))]);
await Scene.play([relay.animatedColor(GREEN, Duration(0.6))]);
await Scene.play([Scene.flashAround(relay, Duration(0.9))]);
await Scene.pause(Duration(0.45));
const n6 = Scene.narrate("Buzz checks the mark, and it matches.");
await Scene.play([n6.start()]);

// --- pull back for the point ---------------------------------------------------
const verdict = new Text("It is you.", 700);
verdict.setColor(GREEN);
verdict.setScale(2.8);
verdict.moveTo(Vector(0, -230));

await Scene.play([Scene.unCreate(c6, Duration(0.25))]);
await focusOn(0, 0, WIDE);
await Scene.play([
  Scene.create(title, Duration(0.45)),
  Scene.create(verdict, Duration(0.6)),
]);
await Scene.play([Scene.create(c7, Duration(0.45))]);
await Scene.pause(Duration(0.4));
const n7 = Scene.narrate("No password to type. Nothing for anyone to steal.");
await Scene.play([n7.start()]);
''';
