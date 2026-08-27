import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A dot that breathes.
///
/// Motion is what separates a live board from a screenshot of one, and it has
/// to stay visible in the gaps between state changes — otherwise a board that
/// is genuinely waiting on an agent looks frozen.
class PulsingDot extends HookWidget {
  const PulsingDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1100),
    );

    useEffect(() {
      controller.repeat(reverse: true);
      return null;
    }, [controller]);

    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(controller),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
