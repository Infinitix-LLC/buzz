import 'package:flutter/material.dart';

/// The colour names every VAL demo scene draws with, as a VAL `const` block.
///
/// The scenes used to hardcode a dark palette, which meant a light-themed
/// transcript showed a black rectangle sitting in a white page. They now
/// declare no colours at all: this block is prepended to a script before it is
/// compiled, so one script renders correctly in either theme.
///
/// [INK], [MUTED] and [PANEL] come from the app's own scheme, so the scene is
/// literally painted in the colours around it. The accents are chosen per
/// brightness instead — the scheme's own accents are tuned for buttons and
/// chips against a surface, and several of them wash out as a hairline stroke
/// on a light background.
///
/// Prepending rather than substituting keeps the scripts readable: they still
/// say `setColor(BLUE)` and mean it.
String valScenePalette(ColorScheme scheme) {
  final light = scheme.brightness == Brightness.light;

  String hex(Color c) =>
      '0x${(c.toARGB32() & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0').toUpperCase()}';

  // Deeper on light, brighter on dark — a stroke has to hold its own against
  // the surface it is drawn on, and a mid-tone does neither well.
  final blue = light ? const Color(0xFF1B63C7) : const Color(0xFF4C9AFF);
  final green = light ? const Color(0xFF1B7F4B) : const Color(0xFF35D07F);
  final orange = light ? const Color(0xFFB4600A) : const Color(0xFFFFA62B);
  final purple = light ? const Color(0xFF6B3FBF) : const Color(0xFFB78CFF);

  // A tint of the surface rather than a fixed colour: the panels read as
  // raised areas of the page, not as pasted-on cards.
  final panel = Color.alphaBlend(
    scheme.onSurface.withValues(alpha: light ? 0.06 : 0.14),
    scheme.surface,
  );

  return '''
const INK = Color(${hex(scheme.onSurface)});
const MUTED = Color(${hex(scheme.onSurfaceVariant)});
const PANEL = Color(${hex(panel)});
const BLUE = Color(${hex(blue)});
const GREEN = Color(${hex(green)});
const ORANGE = Color(${hex(orange)});
const PURPLE = Color(${hex(purple)});
''';
}
