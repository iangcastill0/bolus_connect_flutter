import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class KeyboardDismissible extends StatelessWidget {
  const KeyboardDismissible({super.key, required this.child});

  final Widget child;

  void _handlePointerDown(BuildContext context, PointerDownEvent event) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) return;

    final focusContext = primaryFocus.context;
    if (focusContext == null) {
      primaryFocus.unfocus();
      return;
    }

    final renderObject = focusContext.findRenderObject();
    if (renderObject is RenderBox) {
      final box = renderObject;
      final topLeft = box.localToGlobal(Offset.zero);
      final focusBounds = topLeft & box.size;
      if (focusBounds.contains(event.position)) {
        return; // Tapped inside the already focused field; keep focus.
      }
    }

    primaryFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _handlePointerDown(context, event),
      child: child,
    );
  }
}
