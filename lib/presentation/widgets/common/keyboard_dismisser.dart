import 'package:flutter/material.dart';

/// Wraps any widget — tapping outside inputs dismisses the keyboard.
class KeyboardDismisser extends StatelessWidget {
  final Widget child;
  const KeyboardDismisser({super.key, required this.child});

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: child,
      );
}
