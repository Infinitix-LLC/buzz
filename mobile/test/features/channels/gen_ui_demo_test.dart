import 'package:buzz/features/channels/gen_ui_demo/val_local_scene.dart';
import 'package:buzz/features/channels/gen_ui_demo/showcase_thread.dart';
import 'package:buzz/features/channels/gen_ui_demo/demo_workspace.dart';
import 'package:buzz/features/channels/gen_ui_demo/gen_ui_demo_replies.dart';
import 'package:buzz/features/channels/gen_ui_demo/agent_board_models.dart';
import 'package:buzz/features/channels/gen_ui_demo/gen_ui_registry_provider.dart';
import 'package:buzz/features/channels/gen_ui_demo/val_artifact_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// The board and the tracker as a channel message actually renders them:
/// through `GptMarkdown` and the registry, not by constructing the widgets
/// directly. That is what proves the directive round-trips — a widget test
/// that skips the markdown layer would still pass if gen-UI parsing broke.
void main() {
  Widget wrap(String markdown) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          // Mirrors message_content.dart: a `val_scene` card reads its status
          // from a scope above it.
          body: ValArtifactScope(
            child: Consumer(
              builder: (context, ref, _) => SingleChildScrollView(
                child: GptMarkdown(
                  markdown,
                  genUiBuilder: ref.watch(genUiRegistryProvider).build,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The board is wider than the default 800x600 test surface, so columns
  /// past the second would be off-screen and their cards never laid out.
  Future<void> pumpBoard(WidgetTester tester, String markdown) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(markdown));
    await tester.pump();
  }

  String board({String id = 'test-board'}) =>
      wrapGenUi('{"agent_board": {"board": "$id", "title": "Release cut"}}');

  String progress({String id = 'test-board'}) =>
      wrapGenUi('{"agent_progress": {"board": "$id"}}');

  group('agent_board directive', () {
    testWidgets('renders the board with its columns', (tester) async {
      await pumpBoard(tester, 'Before\n\n${board()}\n\nAfter');

      expect(find.text('Release cut'), findsOneWidget);
      for (final column in BoardColumn.values) {
        expect(find.text(column.label), findsOneWidget);
      }
      // Prose around the directive still renders as prose.
      expect(find.textContaining('Before'), findsWidgets);
    });

    testWidgets('starts with work already in flight', (tester) async {
      await pumpBoard(tester, board(id: 'in-flight'));

      // A board that opens empty and fills up looks like a loading state.
      // Three tasks are mid-flight at t=0 so it reads as work already running.
      final snapshot = BoardSnapshot(Duration.zero);
      expect(snapshot.inFlightCount, greaterThan(0));
      expect(find.textContaining('184k / 840k events'), findsOneWidget);
    });

    testWidgets('moves tasks forward as the run progresses', (tester) async {
      await pumpBoard(tester, board(id: 'moving'));

      expect(find.textContaining('184k / 840k'), findsOneWidget);

      // Past the first scripted transition for the backfill.
      await tester.pump(const Duration(seconds: 13));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.textContaining('184k / 840k'), findsNothing);
      expect(find.textContaining('389k / 840k'), findsOneWidget);

      // Let the timer wind down so the test does not leave one pending.
      await tester.pump(demoRunLength);
    });

    testWidgets('an unknown widget type does not blank the message', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        'Before\n\n${wrapGenUi('{"not_a_widget": {}}')}\n\nAfter',
      );

      expect(find.textContaining('Unsupported widget'), findsOneWidget);
      expect(find.textContaining('After'), findsWidgets);
    });
  });

  group('agent_progress directive', () {
    testWidgets('renders every agent with a percentage', (tester) async {
      await pumpBoard(tester, progress(id: 'progress-only'));

      for (final agent in demoAgents) {
        expect(find.text(agent.name), findsOneWidget);
      }
      expect(find.text('done'), findsOneWidget);
      expect(find.text('blocked'), findsOneWidget);
    });
  });

  group('shared clock', () {
    testWidgets('board and tracker in one message agree', (tester) async {
      // The two directives mount independently. If they ran their own clocks
      // the tracker could count a task as in-flight while the board beside it
      // showed the same task in review, which reads as a bug in the workspace.
      await pumpBoard(
        tester,
        '${board(id: 'shared')}\n\n${progress(id: 'shared')}',
      );
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 700));

      final expected = BoardSnapshot(const Duration(seconds: 30));
      // The header states the same in-flight count the tracker's metric shows.
      expect(
        find.textContaining('${expected.inFlightCount} in flight'),
        findsOneWidget,
      );
      expect(find.text('${expected.inFlightCount}'), findsWidgets);

      await tester.pump(demoRunLength);
    });
  });

  group('scripted run', () {
    test('every task ends somewhere, and the run settles', () {
      final end = BoardSnapshot(demoRunLength);
      // Nothing may be left mid-progress at the end: a board frozen at 71%
      // announces that it was a canned loop that ran out.
      for (final task in demoTasks) {
        final step = end.stepFor(task);
        expect(
          step.column,
          isNot(BoardColumn.backlog),
          reason: '${task.id} never started',
        );
      }
      expect(end.doneCount, greaterThan(0));
    });

    test('tasks only ever move forward', () {
      // A card that moves back a column would be read as the board correcting
      // itself, which is worse than it not moving at all.
      for (final task in demoTasks) {
        var previous = -1;
        for (final step in task.steps) {
          final index = BoardColumn.values.indexOf(step.column);
          expect(
            index,
            greaterThanOrEqualTo(previous),
            reason: '${task.id} moves backwards',
          );
          previous = index;
        }
      }
    });

    test(
      'one task stays blocked, so the board reports rather than decorates',
      () {
        expect(BoardSnapshot(demoRunLength).blockedCount, greaterThan(0));
      },
    );
  });

  group('code_review directive', () {
    testWidgets('shows the patch, its findings and the actions', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        wrapGenUi('{"code_review": {"board": "cr", "task": "relay-typing"}}'),
      );

      expect(find.textContaining('patch/typing-debounce'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
      expect(find.text('Request changes'), findsOneWidget);
      // Author and reviewer are different agents on purpose.
      expect(find.textContaining('presence.rs:88'), findsOneWidget);
    });
  });

  group('cross-widget causality', () {
    testWidgets('approving a patch moves it on the board and clears the gate', (
      tester,
    ) async {
      // The whole argument of the demo in one test: three directives, one
      // workspace. A tap in the review has to be visible in the other two, or
      // they are three pictures rather than three views.
      await pumpBoard(
        tester,
        '${wrapGenUi('{"agent_board": {"board": "wired", "title": "Cut"}}')}\n\n'
        '${wrapGenUi('{"code_review": {"board": "wired", "task": "relay-typing"}}')}\n\n'
        '${wrapGenUi('{"release_readiness": {"board": "wired", "version": "0.6.0"}}')}',
      );
      // Past the point where the patch reaches review.
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 700));

      final before = BoardSnapshot(const Duration(seconds: 30));
      final task = before.taskById('relay-typing');
      expect(task, isNotNull);
      expect(before.stepFor(task!).column, BoardColumn.review);
      expect(find.textContaining('awaiting sign-off'), findsOneWidget);

      await tester.tap(find.text('Approve'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The review reports the consequence, not just the tap.
      expect(find.textContaining('You approved this patch'), findsOneWidget);
      // The board moved the card.
      expect(find.textContaining('approved by you'), findsWidgets);
      // The checklist cleared its gate, in a message posted before the tap.
      expect(find.textContaining('awaiting sign-off'), findsNothing);
      expect(find.textContaining('has a sign-off'), findsOneWidget);

      await tester.pump(demoRunLength);
    });

    testWidgets('requesting changes sends it back to In progress', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        '${wrapGenUi('{"agent_board": {"board": "back", "title": "Cut"}}')}\n\n'
        '${wrapGenUi('{"code_review": {"board": "back", "task": "relay-typing"}}')}',
      );
      await tester.pump(const Duration(seconds: 30));
      await tester.pump(const Duration(milliseconds: 700));

      await tester.tap(find.text('Request changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Changes requested'), findsOneWidget);
      expect(find.textContaining('changes requested by you'), findsWidgets);

      await tester.pump(demoRunLength);
    });
  });

  group('ci_run directive', () {
    testWidgets('names the failing job and its flake rate', (tester) async {
      await pumpBoard(
        tester,
        wrapGenUi('{"ci_run": {"board": "ci", "run": "4812"}}'),
      );

      // The last job is still running when the card first appears — that is
      // what stops it reading as a screenshot. Move past the point it reports.
      expect(find.textContaining('running'), findsWidgets);
      await tester.pump(const Duration(seconds: 14));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('CI run #4812'), findsOneWidget);
      expect(find.text('Relay E2E'), findsOneWidget);
      expect(find.textContaining('1 failing'), findsOneWidget);
      expect(find.textContaining('2 failed'), findsOneWidget);
      expect(
        find.textContaining('test_huddle_rejoin_is_idempotent'),
        findsOneWidget,
      );

      await tester.pump(demoRunLength);
    });
  });

  group('release_readiness directive', () {
    testWidgets('reports the blocker rather than a bare verdict', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        wrapGenUi('{"release_readiness": {"board": "rr", "version": "0.6.0"}}'),
      );

      expect(find.text('Release 0.6.0'), findsOneWidget);
      expect(find.text('Not ready'), findsOneWidget);
      expect(find.textContaining('NIP-42 scope check'), findsOneWidget);

      await tester.pump(demoRunLength);
    });

    testWidgets('agrees with the CI directive about the failing job', (
      tester,
    ) async {
      // Two messages describing one run. If the checklist called CI green
      // while the run beside it showed a red job, the workspace would be
      // contradicting itself in front of the reader.
      await pumpBoard(
        tester,
        '${wrapGenUi('{"ci_run": {"board": "agree", "run": "4812"}}')}\n\n'
        '${wrapGenUi('{"release_readiness": {"board": "agree", "version": "0.6.0"}}')}',
      );
      await tester.pump(const Duration(seconds: 14));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.textContaining('1 failing'), findsOneWidget);
      expect(find.textContaining('Relay E2E failing'), findsOneWidget);

      await tester.pump(demoRunLength);
    });
  });

  group('reply routing', () {
    test('each question reaches its own answer', () {
      expect(replyFor('show me the typing patch').name, 'code review');
      expect(replyFor('why is CI red?').name, 'ci run');
      expect(replyFor('are we ready to ship 0.6.0?').name, 'release readiness');
      expect(replyFor("what's everyone working on?").name, 'agent board');
    });

    test('anything unrecognised falls back to the board', () {
      expect(
        replyFor('so what do these agents actually do?').name,
        'agent board',
      );
      expect(replyFor('zzzz').name, 'agent board');
    });

    test('every scripted answer carries a view to fall back on', () {
      // A live answer that arrives as prose alone gets one of these appended,
      // so an empty one would mean a reply with no UI at all.
      for (final reply in demoReplies) {
        expect(reply.view, isNotEmpty, reason: reply.name);
      }
    });
  });

  group('what gets answered', () {
    test('questions phrased without a question mark still get answered', () {
      // Measured against questions nobody scripted, an earlier keyword-and-`?`
      // gate dropped 15 of 18 — including every one of these. The model
      // answered all of them well once it was actually asked.
      for (final message in [
        'tell me about the release',
        'hows it going',
        'summarise the week',
        'explain the blocker to me',
        'who is the slowest agent',
        'anything I should worry about',
        'break down the work by agent',
      ]) {
        expect(isWorthAnswering(message), isTrue, reason: message);
      }
    });

    test('bare acknowledgements are left alone', () {
      // An agent that answers "thanks" with a board is a bot, not a teammate.
      for (final message in [
        'ok',
        'thanks',
        'ty',
        '+1',
        'sounds good',
        'nice',
        '',
        '   ',
        '👍',
        '...',
      ]) {
        expect(isWorthAnswering(message), isFalse, reason: '"\$message"');
      }
    });
  });

  group('every reply carries a view', () {
    final scripted = replyFor("what's everyone working on?");

    test('a live answer with a view is posted as written', () {
      final live =
          'Two agents busy.\n\n'
          '${wrapGenUi('{"ci_run": {"board": "release-cut"}}')}';

      expect(answerWithView(live, scripted), live);
    });

    test('a live answer that is prose alone gains the routed view', () {
      // The model is good about this, but "good" is not "always", and a reply
      // with no UI in a demo about UI is the worst possible miss.
      const live = 'Morning — nothing on fire.';

      final out = answerWithView(live, scripted);

      expect(out, startsWith(live));
      expect(out, contains(genUiOpenMarker));
    });

    test('no live answer falls back to the script whole', () {
      expect(answerWithView(null, scripted), scripted.body);
      expect(answerWithView('   ', scripted), scripted.body);
    });
  });

  group('val_scene directive', () {
    testWidgets('waits for a tap and then plays in place', (tester) async {
      // Two things at once. The scene is never opened in a sheet — it plays
      // where it lands — and it does not start on build: a transcript can hold
      // several scenes, and autoplaying them runs that many engines at once
      // while each finishes before it is scrolled to.
      await pumpBoard(
        tester,
        'Easier to watch.\n\n'
        '${wrapGenUi('{"val_scene": {"id": "tzUQ7N24bPnR67enUoYT", '
        '"name": "NIP-42 Authentication Handshake", '
        '"frame": "landscape", "status": "ready"}}')}',
      );

      expect(find.byType(ValLocalScene), findsOneWidget);
      expect(
        find.text('See how it works'),
        findsOneWidget,
        reason: 'the invitation is the start control, not a play button',
      );
      // The poster names the scene, since its own title is drawn inside the
      // animation and is no help before it runs.
      expect(find.text('NIP-42 Authentication Handshake'), findsOneWidget);
      expect(find.textContaining('Easier to watch'), findsWidgets);
    });

    testWidgets('tapping the poster starts it inline, not in a sheet', (
      tester,
    ) async {
      await pumpBoard(
        tester,
        wrapGenUi('{"val_scene": {"name": "Scene", "frame": "landscape"}}'),
      );

      await tester.tap(find.text('See how it works'));
      await tester.pump();

      // It leaves the poster for the compiling state, and does so in place:
      // no sheet is presented, the same scene widget is still in the tree.
      expect(find.text('See how it works'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(ValLocalScene), findsOneWidget);
    });
  });

  group('no unrendered interpolation', () {
    testWidgets('every view renders without a literal dollar sign', (
      tester,
    ) async {
      // Twice now a Dart string was written with an escaped `\$`, so the app
      // shipped the source text instead of the value — once in an auth header,
      // once as "\$failed failing" on this card. Both compiled, both passed
      // every other test, and both were only caught by eye. This catches the
      // whole class.
      final views = [
        '{"agent_board": {"board": "dollar", "title": "Cut"}}',
        '{"agent_progress": {"board": "dollar"}}',
        '{"code_review": {"board": "dollar", "task": "relay-typing"}}',
        '{"ci_run": {"board": "dollar", "run": "4812"}}',
        '{"release_readiness": {"board": "dollar", "version": "0.6.0"}}',
      ];

      for (final view in views) {
        await pumpBoard(tester, wrapGenUi(view));
        // Sample the run at both ends: a card can be clean at rest and wrong
        // while something is still in flight.
        for (final wait in [Duration.zero, const Duration(seconds: 20)]) {
          if (wait > Duration.zero) {
            await tester.pump(wait);
            await tester.pump(const Duration(milliseconds: 600));
          }
          for (final text in tester.widgetList<Text>(find.byType(Text))) {
            final data = text.data;
            if (data == null) {
              continue;
            }
            expect(
              data.contains(r'$'),
              isFalse,
              reason: 'literal \$ in "$data" — from $view',
            );
          }
        }
        await tester.pump(demoRunLength);
      }
    });
  });

  group('showcase thread', () {
    test('alternates the two speakers and starts with the owner', () {
      final msgs = showcaseMessages('owner-pk');

      expect(msgs, isNotEmpty);
      expect(msgs.first.pubkey, 'owner-pk');
      for (var i = 0; i < msgs.length; i++) {
        expect(
          msgs[i].pubkey,
          i.isEven ? 'owner-pk' : showcaseBotPubkey,
          reason: 'turn $i broke the ask/answer alternation',
        );
      }
    });

    test('every answer carries exactly one widget', () {
      // The whole premise of the thread. Two widgets in one bubble and the
      // reader stops being able to tell which caption belongs to which.
      for (final m in showcaseMessages('owner-pk')) {
        final count = genUiOpenMarker.allMatches(m.content).length;
        if (m.pubkey == showcaseBotPubkey) {
          expect(count, 1, reason: 'answer "${m.content.split('\n').first}"');
        } else {
          expect(count, 0, reason: 'a question should not carry a widget');
        }
      }
    });

    test('rises in time so the thread reads oldest-first', () {
      final msgs = showcaseMessages('owner-pk');
      for (var i = 1; i < msgs.length; i++) {
        expect(msgs[i].createdAt, greaterThan(msgs[i - 1].createdAt));
      }
    });

    testWidgets('every widget in the thread has a registered builder', (
      tester,
    ) async {
      // Catches a typo'd type or a malformed payload, either of which renders
      // as a placeholder rather than failing — invisible until someone demos it.
      for (final m in showcaseMessages('owner-pk')) {
        if (m.pubkey != showcaseBotPubkey) continue;
        await pumpBoard(tester, m.content);
        expect(
          find.textContaining('Unsupported widget'),
          findsNothing,
          reason: 'unregistered type in: ${m.content}',
        );
        expect(
          find.textContaining('Could not render'),
          findsNothing,
          reason: 'payload failed to decode in: ${m.content}',
        );
      }
    });
  });
}
