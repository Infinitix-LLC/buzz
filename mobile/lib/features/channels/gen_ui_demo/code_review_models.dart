import 'package:flutter/material.dart';

/// How much a finding should worry the reader.
///
/// Three levels, not five. A review that grades everything teaches the reader
/// to skim it; the only distinction that changes behaviour is "must fix
/// before merge", "should look at", "noted".
enum FindingSeverity {
  blocker('blocker', Color(0xFFE05252)),
  warning('warning', Color(0xFFE0A33E)),
  note('note', Color(0xFF6E8BFF));

  const FindingSeverity(this.label, this.color);

  final String label;
  final Color color;
}

/// One file in a patch.
class ReviewFile {
  const ReviewFile({
    required this.path,
    required this.added,
    required this.removed,
  });

  final String path;
  final int added;
  final int removed;

  /// The last two segments — enough to identify the file without the leading
  /// crate path eating the width of a phone.
  String get shortPath {
    final parts = path.split('/');
    if (parts.length <= 2) {
      return path;
    }
    return '…/${parts.sublist(parts.length - 2).join('/')}';
  }
}

/// Something the reviewing agent noticed, anchored to a line.
class ReviewFinding {
  const ReviewFinding({
    required this.file,
    required this.line,
    required this.severity,
    required this.message,
  });

  final String file;
  final int line;
  final FindingSeverity severity;
  final String message;
}

/// A patch under review, as an agent would report it.
class CodeReview {
  const CodeReview({
    required this.taskId,
    required this.title,
    required this.branch,
    required this.agentId,
    required this.reviewerId,
    required this.files,
    required this.findings,
  });

  /// The board task this patch belongs to. Approving here moves that card.
  final String taskId;

  final String title;
  final String branch;

  /// The agent that wrote the patch.
  final String agentId;

  /// The agent that reviewed it. Deliberately a different one: an agent
  /// approving its own work is not a review, and a demo that shows that is
  /// making an argument nobody wants to hear.
  final String reviewerId;

  final List<ReviewFile> files;
  final List<ReviewFinding> findings;

  int get added => files.fold(0, (sum, f) => sum + f.added);
  int get removed => files.fold(0, (sum, f) => sum + f.removed);

  bool get hasBlocker =>
      findings.any((f) => f.severity == FindingSeverity.blocker);
}

/// The reviews this demo can show, keyed by the task they belong to.
const demoReviews = <String, CodeReview>{
  'relay-typing': CodeReview(
    taskId: 'relay-typing',
    title: 'Relay: collapse kind:20002 typing storms',
    branch: 'patch/typing-debounce',
    agentId: 'patch',
    reviewerId: 'scout',
    files: [
      ReviewFile(
        path: 'crates/buzz-pubsub/src/presence.rs',
        added: 48,
        removed: 27,
      ),
      ReviewFile(
        path: 'crates/buzz-relay/src/handlers/event.rs',
        added: 16,
        removed: 4,
      ),
    ],
    findings: [
      ReviewFinding(
        file: 'presence.rs',
        line: 88,
        severity: FindingSeverity.warning,
        message:
            'The 8s TTL is duplicated from the client. Worth lifting into '
            'buzz-core so the two cannot drift.',
      ),
      ReviewFinding(
        file: 'presence.rs',
        line: 132,
        severity: FindingSeverity.note,
        message:
            'Debounce map entries expire but the map never shrinks. Fine at '
            'current channel counts.',
      ),
    ],
  ),
};
