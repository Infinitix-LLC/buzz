import 'package:flutter/material.dart';
import 'package:gpt_markdown/gen_ui/gen_ui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'shared/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load preferences so the first frame uses the saved theme/accent.
  final prefs = await SharedPreferences.getInstance();

  // Build the shared Flutter GPU renderer the `surface_3d` gen-UI views use,
  // before the first frame. Skipping this still renders — each view falls back
  // to a renderer of its own — but the fallback initializes during the frame
  // that first shows a graph. Returns null and stays silent if the GPU is
  // unavailable; the view then reports it. Requires `FLTEnableFlutterGPU` in
  // ios/Runner/Info.plist (val_3d SETUP.md).
  await GenUi3D.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [savedPrefsProvider.overrideWithValue(prefs)],
      child: const App(),
    ),
  );
}
