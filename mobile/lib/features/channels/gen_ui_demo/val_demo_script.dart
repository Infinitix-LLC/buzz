/// The VAL scenes this demo can play, and how a payload names one.
///
/// Each scene lives in its own file: they are long, and one file holding all of
/// them ran up against the repository's 1000-line ceiling.
///
/// Every scene is hardcoded on purpose. The script is the artifact — the server
/// compiles it to an instruction list and the engine runs that list on the
/// device, so nothing is stored server-side and the same bytes play every time.
library;

import 'val_scene_agent_lifecycle.dart';
import 'val_scene_event_anatomy.dart';
import 'val_scene_handshake.dart';
import 'val_scene_latency_curve.dart';
import 'val_scene_message_fanout.dart';

export 'val_scene_agent_lifecycle.dart';
export 'val_scene_event_anatomy.dart';
export 'val_scene_handshake.dart';
export 'val_scene_latency_curve.dart';
export 'val_scene_message_fanout.dart';

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
