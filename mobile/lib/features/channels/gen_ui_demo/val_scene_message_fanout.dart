/// One VAL demo scene. Split out per scene because the combined file was
/// closing on the repository's 1000-line ceiling.
library;

/// Where a message goes when you hit send.
///
/// One signed event to the relay, then a copy to every member — and the same
/// path whether the sender is a person or an agent.
const String kMessageFanoutScript = r'''

const WIDE = 1.0;
const NEAR = 1.5;
const MID = 1.3;

const title = new Text("Where your message goes", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const you = new Rectangle(300, 300);
you.setColor(BLUE);
you.setFillColor(PANEL);
you.setFillOpacity(0.9);
you.setStroke(6);
you.moveTo(Vector(-700, 40));

const youLabel = new Text("You", 400);
youLabel.setColor(INK);
youLabel.setScale(2.2);
youLabel.moveTo(Vector(-700, 250));

const relay = new Rectangle(320, 400);
relay.setColor(GREEN);
relay.setFillColor(PANEL);
relay.setFillOpacity(0.9);
relay.setStroke(6);
relay.moveTo(Vector(-40, 40));

const relayLabel = new Text("Buzz", 400);
relayLabel.setColor(INK);
relayLabel.setScale(2.2);
relayLabel.moveTo(Vector(-40, 300));

function member(y, color) {
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
  t.setScale(1.6);
  t.moveTo(Vector(700, y));
  return t;
}

const m1 = member(220, MUTED);
const m1t = memberText("Ana", 220, INK);
const m2 = member(100, MUTED);
const m2t = memberText("Sam", 100, INK);
const m3 = member(-20, MUTED);
const m3t = memberText("an agent", -20, INK);
const m4 = member(-140, MUTED);
const m4t = memberText("Ravi - offline", -140, MUTED);

// Moves the camera and holds. `cameraCenter` and `cameraZoom` both return
// futures, and `Scene.play` awaits futures, so the two run as one move.
async function focusOn(x, y, s) {
  await Scene.play([
    Scene.cameraCenter(Vector(x, y), Duration(1.0)),
    Scene.cameraZoom(s, Duration(1.0)),
  ]);
}

// A caption placed for the shot it belongs to. A caption pinned to a fixed
// spot leaves the frame the moment anything zooms, so both its position and
// its size come from the shot: at zoom `s` the visible half-height is 540/s,
// sitting 420/s below the focus puts it under the subject rather than on it,
// a wrap width of 900/s stops a long line running off the side, and a scale of
// 2.1/s renders it the same size on screen at every zoom level.
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

const c1 = captionFor("You send one message to a channel.", -700, 40, NEAR);
const c2 = captionFor("It reaches Buzz once, signed by you.", -40, 40, MID);
const c3 = captionFor("Buzz passes a copy to everyone in that channel.", 700, 40, MID);
const c4 = captionFor("Ravi is offline. His copy waits for him.", 700, -60, MID);
const c5 = captionFor("An agent is just another member on that list.", 0, 0, WIDE);

// --- establishing shot -----------------------------------------------------
await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([
  Scene.create(you, Duration(0.5)),
  Scene.create(relay, Duration(0.5)),
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
await Scene.pause(Duration(0.6));

// --- push in on the sender --------------------------------------------------
const note = new Rectangle(240, 90);
note.setColor(BLUE);
note.setFillColor(PANEL);
note.setFillOpacity(1.0);
note.setStroke(5);
note.moveTo(Vector(-700, 40));

const noteText = new Text("hello", 220);
noteText.setColor(INK);
noteText.setScale(1.6);
noteText.moveTo(Vector(-700, 40));

// The title lives at the top of the wide frame, so it juts into every close-up.
await Scene.play([Scene.unCreate(title, Duration(0.25))]);
await focusOn(-700, 40, NEAR);
await Scene.play([Scene.create(c1, Duration(0.45))]);
await Scene.play([
  Scene.create(note, Duration(0.45)),
  Scene.create(noteText, Duration(0.45)),
]);
await Scene.play([Scene.flashAround(note, Duration(0.8))]);
await Scene.pause(Duration(0.4));
const n1 = Scene.narrate("You send one message to a channel.");
await Scene.play([n1.start()]);

// --- travel with the message ------------------------------------------------
await Scene.play([Scene.unCreate(c1, Duration(0.25))]);
await Scene.play([
  Scene.cameraCenter(Vector(-40, 40), Duration(1.2)),
  Scene.cameraZoom(MID, Duration(1.2)),
  note.animatedMoveTo(Vector(-40, 40), Duration(1.2)),
  noteText.animatedMoveTo(Vector(-40, 40), Duration(1.2)),
  Scene.showPassingFlash(note, Duration(1.2)),
]);
await Scene.play([Scene.create(c2, Duration(0.45))]);
await Scene.play([Scene.flashAround(relay, Duration(0.8))]);
await Scene.pause(Duration(0.45));
const n2 = Scene.narrate("It reaches Buzz once, signed by you.");
await Scene.play([n2.start()]);

// --- fan out, camera on the recipients --------------------------------------
function copy() {
  const c = new Rectangle(120, 60);
  c.setColor(GREEN);
  c.setFillColor(PANEL);
  c.setFillOpacity(1.0);
  c.setStroke(4);
  c.moveTo(Vector(-40, 40));
  return c;
}

const k1 = copy();
const k2 = copy();
const k3 = copy();
const k4 = copy();

await Scene.play([Scene.unCreate(c2, Duration(0.25))]);
await Scene.play([
  Scene.create(k1, Duration(0.3)),
  Scene.create(k2, Duration(0.3)),
  Scene.create(k3, Duration(0.3)),
  Scene.create(k4, Duration(0.3)),
]);
await Scene.play([
  Scene.cameraCenter(Vector(700, 40), Duration(1.2)),
  Scene.cameraZoom(MID, Duration(1.2)),
  k1.animatedMoveTo(Vector(440, 220), Duration(1.2)),
  k2.animatedMoveTo(Vector(440, 100), Duration(1.2)),
  k3.animatedMoveTo(Vector(440, -20), Duration(1.2)),
]);
await Scene.play([Scene.create(c3, Duration(0.45))]);
await Scene.play([
  m1.animatedColor(GREEN, Duration(0.4)),
  m2.animatedColor(GREEN, Duration(0.4)),
  m3.animatedColor(GREEN, Duration(0.4)),
]);
await Scene.pause(Duration(0.45));
const n3 = Scene.narrate("Buzz passes a copy to everyone in that channel.");
await Scene.play([n3.start()]);

// --- the one that waits ------------------------------------------------------
await Scene.play([Scene.unCreate(c3, Duration(0.25))]);
await focusOn(700, -60, MID);
await Scene.play([Scene.create(c4, Duration(0.45))]);
await Scene.play([
  k4.animatedMoveTo(Vector(250, -140), Duration(0.9)),
  k4.animatedColor(ORANGE, Duration(0.9)),
]);
await Scene.play([Scene.flashAround(m4, Duration(0.8))]);
await Scene.pause(Duration(0.45));
const n4 = Scene.narrate("Ravi is offline. His copy waits for him.");
await Scene.play([n4.start()]);

// --- pull back for the point --------------------------------------------------
await Scene.play([Scene.unCreate(c4, Duration(0.25))]);
await focusOn(0, 0, WIDE);
await Scene.play([
  Scene.create(title, Duration(0.45)),
  Scene.create(c5, Duration(0.45)),
]);
await Scene.play([Scene.highlight(m3, Duration(0.9))]);
await Scene.pause(Duration(0.4));
const n5 = Scene.narrate("An agent is just another member on that list.");
await Scene.play([n5.start()]);
''';
