/// The VAL script this demo compiles and plays.
///
/// Hardcoded on purpose. The script is the artifact — the server compiles it to
/// an instruction list and the engine runs that list on the device, so nothing
/// is stored server-side and the same bytes play every time.
///
/// Written for a layman, not a protocol reader: it explains how Buzz knows a
/// message really came from you, without naming NIP-42, signatures or keys as
/// cryptography. Two actors stay put for the whole run and one caption line is
/// swapped per beat, so nothing ever overlaps.
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

const title = new Text("How Buzz knows it is really you", 1700);
title.setColor(INK);
title.setScale(3.0);
title.moveTo(Vector(0, 420));

const phone = new Rectangle(320, 400);
phone.setColor(BLUE);
phone.setFillColor(PANEL);
phone.setFillOpacity(0.9);
phone.setStroke(6);
phone.moveTo(Vector(-580, 60));

const phoneLabel = new Text("Your phone", 420);
phoneLabel.setColor(INK);
phoneLabel.setScale(2.4);
phoneLabel.moveTo(Vector(-580, 330));

const relay = new Rectangle(320, 400);
relay.setColor(BLUE);
relay.setFillColor(PANEL);
relay.setFillOpacity(0.9);
relay.setStroke(6);
relay.moveTo(Vector(580, 60));

const relayLabel = new Text("Buzz", 420);
relayLabel.setColor(INK);
relayLabel.setScale(2.4);
relayLabel.moveTo(Vector(580, 330));

async function say(previous, next) {
  if (previous != null) {
    await Scene.play([Scene.unCreate(previous, Duration(0.25))]);
  }
  await Scene.play([Scene.create(next, Duration(0.45))]);
}

function caption(line) {
  const t = new Text(line, 1600);
  t.setColor(MUTED);
  t.setScale(2.2);
  t.moveTo(Vector(0, -400));
  return t;
}

const c1 = caption("Buzz needs to know a message really came from you.");
const c2 = caption("It never asks for a password.");
const c3 = caption("It sends you a random word instead, new every time.");
const c4 = caption("Your phone marks that word with your own secret key.");
const c5 = caption("The key itself never leaves your phone.");
const c6 = caption("Buzz checks the mark, and it matches.");
const c7 = caption("No password to type. Nothing for anyone to steal.");

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
await Scene.pause(Duration(1.4));

const keyRing = new Circle(26);
keyRing.setColor(ORANGE);
keyRing.setStroke(7);
keyRing.moveTo(Vector(-632, 100));

const keyStem = new Line(Vector(-608, 100), Vector(-518, 100));
keyStem.setColor(ORANGE);
keyStem.setStroke(9);

const keyTooth = new Line(Vector(-546, 100), Vector(-546, 68));
keyTooth.setColor(ORANGE);
keyTooth.setStroke(9);

const keyLabel = new Text("your secret key", 420);
keyLabel.setColor(ORANGE);
keyLabel.setScale(1.8);
keyLabel.moveTo(Vector(-580, -200));

await say(c1, c2);
await Scene.play([
  Scene.create(keyRing, Duration(0.4)),
  Scene.create(keyStem, Duration(0.4)),
  Scene.create(keyTooth, Duration(0.4)),
]);
await Scene.play([Scene.create(keyLabel, Duration(0.4))]);
await Scene.pause(Duration(1.2));

const card = new Rectangle(300, 120);
card.setColor(INK);
card.setFillColor(PANEL);
card.setFillOpacity(1.0);
card.setStroke(5);
card.moveTo(Vector(330, 60));

const word = new Text("sunset-4172", 260);
word.setColor(INK);
word.setScale(2.0);
word.moveTo(Vector(330, 60));

await say(c2, c3);
await Scene.play([
  Scene.create(card, Duration(0.5)),
  Scene.create(word, Duration(0.5)),
]);
await Scene.play([
  card.animatedMoveTo(Vector(-160, 60), Duration(1.1)),
  word.animatedMoveTo(Vector(-160, 60), Duration(1.1)),
]);
await Scene.pause(Duration(0.8));

const mark = new Polyline([
  Vector(-26, 0),
  Vector(-6, -22),
  Vector(30, 24),
]);
mark.setColor(GREEN);
mark.setStroke(10);
mark.moveTo(Vector(-160, -40));

await say(c3, c4);
await Scene.play([
  card.animatedColor(GREEN, Duration(0.5)),
  Scene.create(mark, Duration(0.6)),
]);
await Scene.pause(Duration(1.2));

await say(c4, c5);
await Scene.play([Scene.highlight(keyRing, Duration(0.8))]);
await Scene.pause(Duration(1.0));

await say(c5, c6);
await Scene.play([
  card.animatedMoveTo(Vector(170, 60), Duration(1.1)),
  word.animatedMoveTo(Vector(170, 60), Duration(1.1)),
  mark.animatedMoveTo(Vector(170, -40), Duration(1.1)),
]);
await Scene.play([relay.animatedColor(GREEN, Duration(0.5))]);
await Scene.pause(Duration(1.2));

const verdict = new Text("It is you.", 700);
verdict.setColor(GREEN);
verdict.setScale(2.8);
verdict.moveTo(Vector(0, -190));

await say(c6, c7);
await Scene.play([Scene.create(verdict, Duration(0.6))]);
await Scene.pause(Duration(1.6));
''';
