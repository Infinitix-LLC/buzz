/// One VAL demo scene. Split out per scene because the combined file was
/// closing on the repository's 1000-line ceiling.
library;

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
const ORANGE = Color(0xFFFFA62B);
const PANEL = Color(0xFF142235);

const WIDE = 1.0;
const NEAR = 1.5;
const MID = 1.35;

const title = new Text("How an agent picks up work", 1700);
title.setColor(INK);
title.setScale(2.8);
title.moveTo(Vector(0, 430));

const you = new Rectangle(360, 420);
you.setColor(BLUE);
you.setFillColor(PANEL);
you.setFillOpacity(0.9);
you.setStroke(6);
you.moveTo(Vector(-700, -20));

const youLabel = new Text("You", 400);
youLabel.setColor(INK);
youLabel.setScale(2.2);
youLabel.moveTo(Vector(-700, 240));

const channel = new Rectangle(440, 560);
channel.setColor(MUTED);
channel.setFillColor(PANEL);
channel.setFillOpacity(0.55);
channel.setStroke(5);
channel.moveTo(Vector(0, -20));

const channelLabel = new Text("a channel", 500);
channelLabel.setColor(INK);
channelLabel.setScale(2.2);
channelLabel.moveTo(Vector(0, 310));

const agent = new Rectangle(360, 420);
agent.setColor(PURPLE);
agent.setFillColor(PANEL);
agent.setFillOpacity(0.9);
agent.setStroke(6);
agent.moveTo(Vector(700, -20));

const agentLabel = new Text("An agent", 400);
agentLabel.setColor(INK);
agentLabel.setScale(2.2);
agentLabel.moveTo(Vector(700, 240));

// Moves the camera and holds. `cameraCenter` and `cameraZoom` both return
// futures, and `Scene.play` awaits futures, so the two run as one move rather
// than a pan followed by a zoom.
async function focusOn(x, y, s) {
  await Scene.play([
    Scene.cameraCenter(Vector(x, y), Duration(1.0)),
    Scene.cameraZoom(s, Duration(1.0)),
  ]);
}

// A caption placed for the shot it belongs to.
//
// The camera is the whole point of this scene, so a caption pinned to a fixed
// spot on the canvas simply leaves the frame the moment anything zooms. Both
// its position and its size are therefore derived from the shot: at zoom `s`
// the visible half-height is 540/s, so sitting 420/s below the focus puts it
// under the box it describes rather than on top of it, a wrap width of 900/s stops a long line running
// off the side of a close-up, and a scale of 2.1/s renders it the same size
// on screen at every zoom level.
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

const c1 = captionFor("Work starts as an ordinary message in a channel.", 0, 0, WIDE);
const c2 = captionFor("You ask for something, the way you would ask a person.", -700, -20, NEAR);
const c3 = captionFor("An agent in that channel picks it up.", 0, -20, MID);
const c4 = captionFor("It works in the open. Everyone can watch.", 700, -20, NEAR);
const c5 = captionFor("It reports back into the same channel.", 0, -20, MID);
const c6 = captionFor("No dashboard. The conversation is the record.", 0, 0, WIDE);

// --- the establishing shot ------------------------------------------------
await Scene.play([Scene.create(title, Duration(0.7))]);
await Scene.play([
  Scene.create(you, Duration(0.5)),
  Scene.create(channel, Duration(0.5)),
  Scene.create(agent, Duration(0.5)),
]);
await Scene.play([
  Scene.create(youLabel, Duration(0.35)),
  Scene.create(channelLabel, Duration(0.35)),
  Scene.create(agentLabel, Duration(0.35)),
]);

await say(null, c1);
const n1 = Scene.narrate("Work starts as an ordinary message in a channel.");
await Scene.play([n1.start()]);

// --- push in on the person ------------------------------------------------
const task = new Rectangle(300, 110);
task.setColor(BLUE);
task.setFillColor(PANEL);
task.setFillOpacity(1.0);
task.setStroke(5);
task.moveTo(Vector(-700, -20));

const taskText = new Text("fix login bug", 270);
taskText.setColor(INK);
taskText.setScale(1.5);
taskText.moveTo(Vector(-700, -20));

await Scene.play([
  Scene.unCreate(c1, Duration(0.25)),
  // The title sits at the top of the *wide* frame, so it juts into every
  // close-up. Taken away for the push-in, brought back for the pull-out.
  Scene.unCreate(title, Duration(0.25)),
]);
await focusOn(-700, -20, NEAR);
await Scene.play([Scene.create(c2, Duration(0.45))]);
await Scene.play([
  Scene.create(task, Duration(0.45)),
  Scene.create(taskText, Duration(0.45)),
]);
await Scene.play([Scene.flashAround(task, Duration(0.8))]);
await Scene.pause(Duration(0.4));
const n2 = Scene.narrate("You ask for something, the way you would ask a person.");
await Scene.play([n2.start()]);

// --- follow the message across ---------------------------------------------
await Scene.play([Scene.unCreate(c2, Duration(0.25))]);
await Scene.play([
  Scene.cameraCenter(Vector(0, -20), Duration(1.2)),
  Scene.cameraZoom(MID, Duration(1.2)),
  task.animatedMoveTo(Vector(0, 120), Duration(1.2)),
  taskText.animatedMoveTo(Vector(0, 120), Duration(1.2)),
  Scene.showPassingFlash(task, Duration(1.2)),
]);
await Scene.play([Scene.create(c3, Duration(0.45))]);
await Scene.play([
  agent.animatedColor(GREEN, Duration(0.6)),
  Scene.flashAround(channel, Duration(0.9)),
]);
await Scene.pause(Duration(0.45));
const n3 = Scene.narrate("An agent in that channel picks it up.");
await Scene.play([n3.start()]);

// --- push in on the agent, and show it working ------------------------------
const w1 = new Text("reading the code", 300);
w1.setColor(GREEN);
w1.setScale(1.3);
w1.moveTo(Vector(700, 60));

const w2 = new Text("writing a fix", 300);
w2.setColor(GREEN);
w2.setScale(1.3);
w2.moveTo(Vector(700, -20));

const w3 = new Text("running the tests", 300);
w3.setColor(GREEN);
w3.setScale(1.3);
w3.moveTo(Vector(700, -100));

await Scene.play([Scene.unCreate(c3, Duration(0.25))]);
await focusOn(700, -20, NEAR);
await Scene.play([Scene.create(c4, Duration(0.45))]);
await Scene.play([Scene.create(w1, Duration(0.4))]);
await Scene.play([Scene.create(w2, Duration(0.4))]);
await Scene.play([Scene.create(w3, Duration(0.4))]);
await Scene.pause(Duration(0.4));
const n4 = Scene.narrate("It works in the open. Everyone can watch.");
await Scene.play([n4.start()]);

// --- carry the result back --------------------------------------------------
const result = new Rectangle(300, 110);
result.setColor(GREEN);
result.setFillColor(PANEL);
result.setFillOpacity(1.0);
result.setStroke(5);
result.moveTo(Vector(700, -20));

const resultText = new Text("fixed in 3 files", 270);
resultText.setColor(GREEN);
resultText.setScale(1.5);
resultText.moveTo(Vector(700, -20));

await Scene.play([Scene.unCreate(c4, Duration(0.25))]);
await Scene.play([
  Scene.create(result, Duration(0.45)),
  Scene.create(resultText, Duration(0.45)),
]);
await Scene.play([
  Scene.cameraCenter(Vector(0, -20), Duration(1.2)),
  Scene.cameraZoom(MID, Duration(1.2)),
  result.animatedMoveTo(Vector(0, -140), Duration(1.2)),
  resultText.animatedMoveTo(Vector(0, -140), Duration(1.2)),
  Scene.showPassingFlash(result, Duration(1.2)),
]);
await Scene.play([Scene.create(c5, Duration(0.45))]);
await Scene.pause(Duration(0.4));
const n5 = Scene.narrate("It reports back into the same channel.");
await Scene.play([n5.start()]);

// --- pull back for the point ------------------------------------------------
await Scene.play([Scene.unCreate(c5, Duration(0.25))]);
await focusOn(0, 0, WIDE);
await Scene.play([
  Scene.create(title, Duration(0.45)),
  Scene.create(c6, Duration(0.45)),
]);
await Scene.pause(Duration(0.3));
const n6 = Scene.narrate("No dashboard. The conversation is the record.");
await Scene.play([n6.start()]);
''';
