import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A VAL script compiled into something the on-device engine can run.
@immutable
class CompiledValProgram {
  const CompiledValProgram({
    required this.instructions,
    required this.narrations,
  });

  /// The flat instruction list — VAL bytecode, ready for the engine.
  final List<dynamic> instructions;

  /// Narrations keyed by the exact string the script narrates, each carrying
  /// its audio and word marks when the artifact has been enriched. A freshly
  /// compiled script has the keys and empty bodies: compilation does not
  /// synthesise speech.
  final Map<String, Map<String, dynamic>> narrations;

  /// Whether any narration carries the audio a paced voice-over needs.
  ///
  /// The compile endpoint returns narration text keyed to empty bodies, so this
  /// is false for every client-compiled program today. It is a property of the
  /// payload rather than a constant so a future endpoint that does synthesize
  /// audio starts working without a code change here.
  bool get hasNarrationAudio => narrations.values.any(
    (n) => (n['audioUrl'] as String?)?.isNotEmpty ?? false,
  );
}

/// Thrown when the server rejects a script. Carries the compiler's own message,
/// which names the line and column.
class ValCompileException implements Exception {
  const ValCompileException(this.message);

  final String message;

  @override
  String toString() => 'ValCompileException: $message';
}

/// The deployed `validateValArtifact` endpoint.
///
/// Compiles a **client-supplied** script — unlike the stream and program
/// endpoints, which only compile a script the server already stores. That is
/// what makes a hardcoded script possible: the app owns the source, the server
/// owns the compiler, and the device owns the run.
///
/// Unauthenticated with `CORS *`.
const String kValCompileEndpoint =
    'https://validate-val-artifact-4nssw7ubpq-uc.a.run.app';

/// Compiles [script] and returns its instruction list.
///
/// Note the endpoint answers **200 for a rejected script** — success and
/// failure are told apart by the `isOk` field in the body, not by the status
/// code. A caller that only checks the status treats a compile error as a
/// program with zero instructions, which plays as a blank canvas rather than
/// as an error.
Future<CompiledValProgram> compileValScript(
  String script, {
  String? frame,
  String? endpoint,
  http.Client? client,
  Duration timeout = const Duration(seconds: 60),
}) async {
  final transport = client ?? http.Client();
  try {
    final response = await transport
        .post(
          Uri.parse(endpoint ?? kValCompileEndpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'script': script,
            if (frame != null && frame.isNotEmpty) 'frame': frame,
          }),
        )
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw ValCompileException(
        'Compile request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const ValCompileException('Compiler returned an unexpected body.');
    }

    if (decoded['isOk'] != true) {
      final error = decoded['error'];
      throw ValCompileException(
        error == null ? 'Script did not compile.' : error.toString(),
      );
    }

    final instructions = decoded['instructions'];
    if (instructions is! List || instructions.isEmpty) {
      throw const ValCompileException('Script compiled to nothing to run.');
    }

    return CompiledValProgram(
      instructions: instructions,
      narrations: _narrations(decoded['narrations']),
    );
  } finally {
    if (client == null) {
      transport.close();
    }
  }
}

/// Coerces the decoded narrations into the shape the engine expects.
///
/// `jsonDecode` hands back `Map<String, dynamic>` whose values are `dynamic`,
/// and the engine wants `Map<String, Map<String, dynamic>>`. Passing the
/// decoded map straight through compiles and then fails at runtime on the
/// first cast.
Map<String, Map<String, dynamic>> _narrations(Object? raw) {
  if (raw is! Map) {
    return const {};
  }
  final out = <String, Map<String, dynamic>>{};
  for (final entry in raw.entries) {
    final value = entry.value;
    out[entry.key.toString()] = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
  }
  return out;
}
