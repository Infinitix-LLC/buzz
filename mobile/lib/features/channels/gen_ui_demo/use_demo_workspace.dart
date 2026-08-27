import 'package:flutter_hooks/flutter_hooks.dart';

import 'demo_workspace.dart';

/// Binds a widget to the demo workspace named in its gen-UI payload.
///
/// Every directive reads its board the same way, so the acquire / listen /
/// release cycle lives here once. Getting it wrong in one widget would leave a
/// timer running after the message scrolled away.
BoardSnapshot useDemoWorkspace(Map<String, dynamic> attributes) {
  final board = attributes['board'];
  final id = board is String && board.isNotEmpty ? board : 'default';

  final workspace = useMemoized(() => DemoWorkspace.acquire(id), [id]);
  useEffect(
    () =>
        () => workspace.release(id),
    [workspace],
  );
  useListenable(workspace);

  return workspace.snapshot;
}

/// The workspace itself, for widgets that record actions rather than just
/// reading state.
DemoWorkspace useDemoWorkspaceRef(Map<String, dynamic> attributes) {
  final board = attributes['board'];
  final id = board is String && board.isNotEmpty ? board : 'default';

  final workspace = useMemoized(() => DemoWorkspace.acquire(id), [id]);
  useEffect(
    () =>
        () => workspace.release(id),
    [workspace],
  );
  useListenable(workspace);

  return workspace;
}
