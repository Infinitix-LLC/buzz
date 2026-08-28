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

await Scene.cameraZoom(1.08, Duration(0.01));
await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([
  Scene.create(phone, Duration(0.6)),
  Scene.create(relay, Duration(0.6)),
  Scene.cameraZoom(1.0, Duration(1.1)),
]);
await Scene.play([
  Scene.create(phoneLabel, Duration(0.4)),
  Scene.create(relayLabel, Duration(0.4)),
]);

await say(null, c1);
const n1 = Scene.narrate("Buzz needs to know a message really came from you.");
await Scene.play([n1.start()]);

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
await Scene.play([Scene.flashAround(keyRing, Duration(0.9))]);
await Scene.pause(Duration(0.45));
const n2 = Scene.narrate("It never asks for a password.");
await Scene.play([n2.start()]);

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
  Scene.showPassingFlash(card, Duration(1.1)),
]);
await Scene.pause(Duration(0.4));
const n3 = Scene.narrate("It sends you a random word instead, new every time.");
await Scene.play([n3.start()]);

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
const n4 = Scene.narrate("Your phone marks that word with your own secret key.");
await Scene.play([n4.start()]);

await say(c4, c5);
await Scene.play([Scene.flashAround(phone, Duration(1.0))]);
await Scene.pause(Duration(0.45));
const n5 = Scene.narrate("The key itself never leaves your phone.");
await Scene.play([n5.start()]);

await say(c5, c6);
await Scene.play([
  card.animatedMoveTo(Vector(170, 60), Duration(1.1)),
  word.animatedMoveTo(Vector(170, 60), Duration(1.1)),
  mark.animatedMoveTo(Vector(170, -40), Duration(1.1)),
]);
await Scene.play([relay.animatedColor(GREEN, Duration(0.5))]);
const n6 = Scene.narrate("Buzz checks the mark, and it matches.");
await Scene.play([n6.start()]);

const verdict = new Text("It is you.", 700);
verdict.setColor(GREEN);
verdict.setScale(2.8);
verdict.moveTo(Vector(0, -190));

await say(c6, c7);
await Scene.play([
  Scene.create(verdict, Duration(0.6)),
  Scene.cameraZoom(1.04, Duration(0.9)),
]);
const n7 = Scene.narrate("No password to type. Nothing for anyone to steal.");
await Scene.play([n7.start()]);
''';

/// How an agent picks up work and reports back.
///
/// The mechanism newcomers understand least: that an agent is a participant in
/// a channel rather than a service behind a dashboard.
const String kAgentLifecycleScript = r'''
const INK = Color(0xFFE8F0FA);
const MUTED = Color(0xFF93A9C4);
const BLUE = Color(0xFF4C9AFF);
const GREEN = Color(0xFF35D07F);
const PURPLE = Color(0xFFB78CFF);
const PANEL = Color(0xFF142235);

const title = new Text("How an agent picks up work", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const you = new Rectangle(280, 300);
you.setColor(BLUE);
you.setFillColor(PANEL);
you.setFillOpacity(0.9);
you.setStroke(6);
you.moveTo(Vector(-640, 40));

const youLabel = new Text("You", 400);
youLabel.setColor(INK);
youLabel.setScale(2.2);
youLabel.moveTo(Vector(-640, 250));

const channel = new Rectangle(380, 460);
channel.setColor(MUTED);
channel.setFillColor(PANEL);
channel.setFillOpacity(0.6);
channel.setStroke(5);
channel.moveTo(Vector(0, 20));

const channelLabel = new Text("a channel", 500);
channelLabel.setColor(INK);
channelLabel.setScale(2.2);
channelLabel.moveTo(Vector(0, 300));

const agent = new Rectangle(280, 300);
agent.setColor(PURPLE);
agent.setFillColor(PANEL);
agent.setFillOpacity(0.9);
agent.setStroke(6);
agent.moveTo(Vector(640, 40));

const agentLabel = new Text("An agent", 400);
agentLabel.setColor(INK);
agentLabel.setScale(2.2);
agentLabel.moveTo(Vector(640, 250));

async function say(previous, next) {
  if (previous != null) {
    await Scene.play([Scene.unCreate(previous, Duration(0.25))]);
  }
  await Scene.play([Scene.create(next, Duration(0.45))]);
}

function caption(line) {
  const t = new Text(line, 1600);
  t.setColor(MUTED);
  t.setScale(2.1);
  t.moveTo(Vector(0, -420));
  return t;
}

const c1 = caption("Work starts as an ordinary message in a channel.");
const c2 = caption("You ask for something, the way you would ask a person.");
const c3 = caption("An agent in that channel picks it up.");
const c4 = caption("It works in the open. Everyone can watch.");
const c5 = caption("It reports back into the same channel.");
const c6 = caption("No dashboard. The conversation is the record.");

await Scene.cameraZoom(1.08, Duration(0.01));
await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([
  Scene.create(you, Duration(0.5)),
  Scene.create(channel, Duration(0.5)),
  Scene.create(agent, Duration(0.5)),
  Scene.cameraZoom(1.0, Duration(1.1)),
]);
await Scene.play([
  Scene.create(youLabel, Duration(0.35)),
  Scene.create(channelLabel, Duration(0.35)),
  Scene.create(agentLabel, Duration(0.35)),
]);

await say(null, c1);
const n1 = Scene.narrate("Work starts as an ordinary message in a channel.");
await Scene.play([n1.start()]);

const task = new Rectangle(300, 100);
task.setColor(BLUE);
task.setFillColor(PANEL);
task.setFillOpacity(1.0);
task.setStroke(5);
task.moveTo(Vector(-640, 40));

const taskText = new Text("fix login bug", 280);
taskText.setColor(INK);
taskText.setScale(1.6);
taskText.moveTo(Vector(-640, 40));

await say(c1, c2);
await Scene.play([
  Scene.create(task, Duration(0.4)),
  Scene.create(taskText, Duration(0.4)),
]);
await Scene.play([
  task.animatedMoveTo(Vector(0, 120), Duration(1.0)),
  taskText.animatedMoveTo(Vector(0, 120), Duration(1.0)),
  Scene.showPassingFlash(task, Duration(1.0)),
]);
await Scene.play([Scene.flashAround(channel, Duration(0.8))]);
await Scene.pause(Duration(0.45));
const n2 = Scene.narrate("You ask for something, the way you would ask a person.");
await Scene.play([n2.start()]);

await say(c2, c3);
await Scene.play([
  agent.animatedColor(GREEN, Duration(0.5)),
  Scene.highlight(agent, Duration(0.8)),
]);
await Scene.pause(Duration(0.45));
const n3 = Scene.narrate("An agent in that channel picks it up.");
await Scene.play([n3.start()]);

const step1 = new Circle(16);
step1.setColor(GREEN);
step1.setFillColor(GREEN);
step1.setFillOpacity(1.0);
step1.moveTo(Vector(580, -20));

const step2 = new Circle(16);
step2.setColor(GREEN);
step2.setFillColor(GREEN);
step2.setFillOpacity(1.0);
step2.moveTo(Vector(640, -20));

const step3 = new Circle(16);
step3.setColor(GREEN);
step3.setFillColor(GREEN);
step3.setFillOpacity(1.0);
step3.moveTo(Vector(700, -20));

await say(c3, c4);
await Scene.play([Scene.create(step1, Duration(0.3))]);
await Scene.play([Scene.create(step2, Duration(0.3))]);
await Scene.play([Scene.create(step3, Duration(0.3))]);
const n4 = Scene.narrate("It works in the open. Everyone can watch.");
await Scene.play([n4.start()]);

const result = new Rectangle(300, 100);
result.setColor(GREEN);
result.setFillColor(PANEL);
result.setFillOpacity(1.0);
result.setStroke(5);
result.moveTo(Vector(640, 40));

const resultText = new Text("fixed in 3 files", 280);
resultText.setColor(GREEN);
resultText.setScale(1.6);
resultText.moveTo(Vector(640, 40));

await say(c4, c5);
await Scene.play([
  Scene.create(result, Duration(0.4)),
  Scene.create(resultText, Duration(0.4)),
]);
await Scene.play([
  result.animatedMoveTo(Vector(0, -60), Duration(1.0)),
  resultText.animatedMoveTo(Vector(0, -60), Duration(1.0)),
  Scene.showPassingFlash(result, Duration(1.0)),
]);
await Scene.pause(Duration(0.4));
const n5 = Scene.narrate("It reports back into the same channel.");
await Scene.play([n5.start()]);

await say(c5, c6);
await Scene.play([Scene.cameraZoom(1.04, Duration(0.9))]);
const n6 = Scene.narrate("No dashboard. The conversation is the record.");
await Scene.play([n6.start()]);
''';

/// Where a message goes when you hit send.
///
/// One signed event to the relay, then a copy to every member — and the same
/// path whether the sender is a person or an agent.
const String kMessageFanoutScript = r'''
const INK = Color(0xFFE8F0FA);
const MUTED = Color(0xFF93A9C4);
const BLUE = Color(0xFF4C9AFF);
const GREEN = Color(0xFF35D07F);
const ORANGE = Color(0xFFFFA62B);
const PANEL = Color(0xFF142235);

const title = new Text("Where your message goes", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const you = new Rectangle(260, 260);
you.setColor(BLUE);
you.setFillColor(PANEL);
you.setFillOpacity(0.9);
you.setStroke(6);
you.moveTo(Vector(-700, 40));

const youLabel = new Text("You", 400);
youLabel.setColor(INK);
youLabel.setScale(2.2);
youLabel.moveTo(Vector(-700, 230));

const relay = new Rectangle(300, 380);
relay.setColor(GREEN);
relay.setFillColor(PANEL);
relay.setFillOpacity(0.9);
relay.setStroke(6);
relay.moveTo(Vector(-40, 40));

const relayLabel = new Text("Buzz", 400);
relayLabel.setColor(INK);
relayLabel.setScale(2.2);
relayLabel.moveTo(Vector(-40, 290));

function member(label, y, color) {
  const box = new Rectangle(300, 90);
  box.setColor(color);
  box.setFillColor(PANEL);
  box.setFillOpacity(0.9);
  box.setStroke(5);
  box.moveTo(Vector(700, y));
  return box;
}

function memberText(label, y, color) {
  const t = new Text(label, 280);
  t.setColor(color);
  t.setScale(1.7);
  t.moveTo(Vector(700, y));
  return t;
}

const m1 = member("Ana", 220, MUTED);
const m1t = memberText("Ana", 220, INK);
const m2 = member("Sam", 100, MUTED);
const m2t = memberText("Sam", 100, INK);
const m3 = member("an agent", -20, MUTED);
const m3t = memberText("an agent", -20, INK);
const m4 = member("Ravi", -140, MUTED);
const m4t = memberText("Ravi - offline", -140, MUTED);

async function say(previous, next) {
  if (previous != null) {
    await Scene.play([Scene.unCreate(previous, Duration(0.25))]);
  }
  await Scene.play([Scene.create(next, Duration(0.45))]);
}

function caption(line) {
  const t = new Text(line, 1600);
  t.setColor(MUTED);
  t.setScale(2.1);
  t.moveTo(Vector(0, -420));
  return t;
}

const c1 = caption("You send one message to a channel.");
const c2 = caption("It reaches Buzz once, signed by you.");
const c3 = caption("Buzz passes a copy to everyone in that channel.");
const c4 = caption("Ravi is offline. His copy waits for him.");
const c5 = caption("An agent is just another member on that list.");

await Scene.cameraZoom(1.08, Duration(0.01));
await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([
  Scene.create(you, Duration(0.5)),
  Scene.create(relay, Duration(0.5)),
  Scene.cameraZoom(1.0, Duration(1.1)),
]);
await Scene.play([
  Scene.create(youLabel, Duration(0.35)),
  Scene.create(relayLabel, Duration(0.35)),
]);
await Scene.play([
  Scene.create(m1, Duration(0.3)),
  Scene.create(m2, Duration(0.3)),
  Scene.create(m3, Duration(0.3)),
  Scene.create(m4, Duration(0.3)),
]);
await Scene.play([
  Scene.create(m1t, Duration(0.3)),
  Scene.create(m2t, Duration(0.3)),
  Scene.create(m3t, Duration(0.3)),
  Scene.create(m4t, Duration(0.3)),
]);

await say(null, c1);
const n1 = Scene.narrate("You send one message to a channel.");
await Scene.play([n1.start()]);

const note = new Rectangle(240, 90);
note.setColor(BLUE);
note.setFillColor(PANEL);
note.setFillOpacity(1.0);
note.setStroke(5);
note.moveTo(Vector(-700, 40));

const noteText = new Text("hello", 220);
noteText.setColor(INK);
noteText.setScale(1.7);
noteText.moveTo(Vector(-700, 40));

await say(c1, c2);
await Scene.play([
  Scene.create(note, Duration(0.4)),
  Scene.create(noteText, Duration(0.4)),
]);
await Scene.play([
  note.animatedMoveTo(Vector(-40, 40), Duration(1.0)),
  noteText.animatedMoveTo(Vector(-40, 40), Duration(1.0)),
  Scene.showPassingFlash(note, Duration(1.0)),
]);
await Scene.play([Scene.flashAround(relay, Duration(0.8))]);
await Scene.pause(Duration(0.45));
const n2 = Scene.narrate("It reaches Buzz once, signed by you.");
await Scene.play([n2.start()]);

function copy(y) {
  const c = new Rectangle(120, 60);
  c.setColor(GREEN);
  c.setFillColor(PANEL);
  c.setFillOpacity(1.0);
  c.setStroke(4);
  c.moveTo(Vector(-40, 40));
  return c;
}

const k1 = copy(220);
const k2 = copy(100);
const k3 = copy(-20);
const k4 = copy(-140);

await say(c2, c3);
await Scene.play([
  Scene.create(k1, Duration(0.3)),
  Scene.create(k2, Duration(0.3)),
  Scene.create(k3, Duration(0.3)),
  Scene.create(k4, Duration(0.3)),
]);
await Scene.play([
  k1.animatedMoveTo(Vector(420, 220), Duration(0.9)),
  k2.animatedMoveTo(Vector(420, 100), Duration(0.9)),
  k3.animatedMoveTo(Vector(420, -20), Duration(0.9)),
]);
await Scene.pause(Duration(0.35));
await Scene.play([
  m1.animatedColor(GREEN, Duration(0.4)),
  m2.animatedColor(GREEN, Duration(0.4)),
  m3.animatedColor(GREEN, Duration(0.4)),
]);
const n3 = Scene.narrate("Buzz passes a copy to everyone in that channel.");
await Scene.play([n3.start()]);

await say(c3, c4);
await Scene.play([
  k4.animatedMoveTo(Vector(250, -140), Duration(0.8)),
  k4.animatedColor(ORANGE, Duration(0.8)),
]);
const n4 = Scene.narrate("Ravi is offline. His copy waits for him.");
await Scene.play([n4.start()]);

await say(c4, c5);
await Scene.play([
  Scene.highlight(m3, Duration(0.9)),
  Scene.cameraZoom(1.04, Duration(0.9)),
]);
await Scene.pause(Duration(0.45));
const n5 = Scene.narrate("An agent is just another member on that list.");
await Scene.play([n5.start()]);
''';

/// Why a big channel costs more than a small one.
///
/// A different side of the engine from the box-and-arrow scenes: a real axis,
/// a curve plotted from a function at run time, and typeset maths — none of it
/// an image, all of it drawn on the device.
const String kLatencyCurveScript = r'''
const INK = Color(0xFFE8F0FA);
const MUTED = Color(0xFF93A9C4);
const BLUE = Color(0xFF4C9AFF);
const ORANGE = Color(0xFFFFA62B);

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

async function say(previous, next) {
  if (previous != null) {
    await Scene.play([Scene.unCreate(previous, Duration(0.25))]);
  }
  await Scene.play([Scene.create(next, Duration(0.45))]);
}

function caption(line) {
  const t = new Text(line, 1600);
  t.setColor(MUTED);
  t.setScale(2.1);
  t.moveTo(Vector(0, -430));
  return t;
}

const c1 = caption("A channel of ten is easy.");
const c2 = caption("The work grows faster than the room does.");
const c3 = caption("So Buzz sends once and lets the relay do the copying.");

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

await say(c1, c2);
await Scene.play([Scene.create(curve, Duration(1.6))]);
await Scene.pause(Duration(0.45));

const formula = new MathTex("n^2");
formula.setColor(ORANGE);
formula.setScale(3.8);
formula.moveTo(Vector(400, 220));

await Scene.play([Scene.create(formula, Duration(0.8))]);
await Scene.pause(Duration(0.45));
const n2 = Scene.narrate("The work grows faster than the room does.");
await Scene.play([n2.start()]);

const fix = new MathTex("n");
fix.setColor(BLUE);
fix.setScale(3.8);
fix.moveTo(Vector(400, 220));

await say(c2, c3);
await Scene.play([Scene.transform(formula, fix, Duration(1.0))]);
await Scene.pause(Duration(0.5));
const n3 = Scene.narrate("So Buzz sends once and lets the relay do the copying.");
await Scene.play([n3.start()]);
''';

/// What a message actually is, once you look inside one.
///
/// Camera-led rather than motion-led: the scene pushes in on a single event and
/// its fields arrive one at a time, then pulls back for the point about the
/// signature.
const String kEventAnatomyScript = r'''
const INK = Color(0xFFE8F0FA);
const MUTED = Color(0xFF93A9C4);
const BLUE = Color(0xFF4C9AFF);
const GREEN = Color(0xFF35D07F);
const ORANGE = Color(0xFFFFA62B);
const PANEL = Color(0xFF142235);

const title = new Text("What a message really is", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const card = new Rectangle(760, 460);
card.setColor(BLUE);
card.setFillColor(PANEL);
card.setFillOpacity(0.95);
card.setStroke(6);
card.moveTo(Vector(0, 30));

function field(label, y, color) {
  const t = new Text(label, 700);
  t.setColor(color);
  t.setScale(1.9);
  t.moveTo(Vector(0, y));
  return t;
}

const f1 = field("from   you", 180, INK);
const f2 = field("in     a channel", 100, INK);
const f3 = field("says   hello", 20, INK);
const f4 = field("at     09:41", -60, INK);
const f5 = field("signed by your key", -150, GREEN);

async function say(previous, next) {
  if (previous != null) {
    await Scene.play([Scene.unCreate(previous, Duration(0.25))]);
  }
  await Scene.play([Scene.create(next, Duration(0.45))]);
}

function caption(line) {
  const t = new Text(line, 1600);
  t.setColor(MUTED);
  t.setScale(2.1);
  t.moveTo(Vector(0, -430));
  return t;
}

const c1 = caption("Every message is one small, signed record.");
const c2 = caption("Who sent it, where, what it said, and when.");
const c3 = caption("Change one character and the signature stops matching.");

await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([
  Scene.create(card, Duration(0.8)),
  Scene.cameraZoom(1.12, Duration(1.2)),
]);

await say(null, c1);
const n1 = Scene.narrate("Every message is one small, signed record.");
await Scene.play([n1.start()]);

await say(c1, c2);
await Scene.play([Scene.create(f1, Duration(0.35))]);
await Scene.play([Scene.create(f2, Duration(0.35))]);
await Scene.play([Scene.create(f3, Duration(0.35))]);
await Scene.play([Scene.create(f4, Duration(0.35))]);
await Scene.pause(Duration(0.4));
const n2 = Scene.narrate("Who sent it, where, what it said, and when.");
await Scene.play([n2.start()]);

await say(c2, c3);
await Scene.play([Scene.create(f5, Duration(0.5))]);
await Scene.play([Scene.flashAround(f5, Duration(1.0))]);
await Scene.pause(Duration(0.5));
await Scene.play([Scene.cameraZoom(1.0, Duration(1.0))]);
const n3 = Scene.narrate("Change one character and the signature stops matching.");
await Scene.play([n3.start()]);
''';

/// The scenes a `val_scene` payload can name, keyed by its `scene` attribute.
///
/// Keeping the scripts behind a name rather than passing source through the
/// payload means the model picks a scene from a fixed set and cannot invent
/// one — a directive naming a scene that does not exist falls back to the
/// handshake rather than rendering an error into the conversation.
const Map<String, String> kValDemoScenes = {
  'handshake': kNip42HandshakeScript,
  'agent_lifecycle': kAgentLifecycleScript,
  'message_fanout': kMessageFanoutScript,
  'latency_curve': kLatencyCurveScript,
  'event_anatomy': kEventAnatomyScript,
};

/// The script for [name], or the handshake when [name] is unknown or absent.
String valDemoScript(String? name) =>
    kValDemoScenes[name] ?? kNip42HandshakeScript;
