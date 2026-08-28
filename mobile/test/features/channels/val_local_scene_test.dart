import 'package:buzz/features/channels/gen_ui_demo/val_compile_client.dart';
import 'package:buzz/features/channels/gen_ui_demo/val_local_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `const c = new Circle(40); Scene.add(c);` as the compiler emits it, so the
/// widget never needs the compile endpoint.
CompiledValProgram _program() => const CompiledValProgram(
  instructions: [
    201,
    0,
    'Circle',
    200,
    0,
    40,
    600,
    0,
    1,
    ['plain'],
    103,
    0,
    'const_',
    ['id', 'c'],
    201,
    0,
    'Scene',
    500,
    0,
    'add',
    true,
    201,
    0,
    'c',
    600,
    0,
    1,
    ['plain'],
    202,
    0,
  ],
  narrations: {},
);

void main() {
  Widget host({bool autoplay = false}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          height: 180,
          child: ValLocalScene(
            script: 'ignored',
            autoplay: autoplay,
            title: 'A scene',
            precompiled: _program(),
          ),
        ),
      ),
    ),
  );

  testWidgets('waits on a poster and names the scene', (tester) async {
    // The scene draws its own title inside the animation, which is no help
    // before it has started — hence the name on the poster.
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('See how it works'), findsOneWidget);
    expect(find.text('A scene'), findsOneWidget);
  });

  testWidgets('does not compile or run until it is tapped', (tester) async {
    // The reason tap-to-start exists: several scenes in one transcript each
    // ran an engine, and each had finished by the time it was scrolled to.
    await tester.pumpWidget(host());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    expect(find.text('See how it works'), findsOneWidget);
    expect(
      find
          .byType(CustomPaint)
          .evaluate()
          .where(
            (e) =>
                (e.widget as CustomPaint).painter.runtimeType.toString() ==
                '_LocalScenePainter',
          ),
      isEmpty,
      reason: 'an idle scene must not build a player or a painter',
    );
  });

  testWidgets('a tap leaves the poster for the scene, in place', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    await tester.pump();

    await tester.tap(find.text('See how it works'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text('See how it works'), findsNothing);
    // In place — no sheet, no pushed route.
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byType(ValLocalScene), findsOneWidget);

    // Unmount, then drain: the scene polls on a timer while it waits for the
    // animation to come to rest, and the binding fails a test that ends with
    // one outstanding. The poll bails out on the first tick after unmount.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
  });
}
