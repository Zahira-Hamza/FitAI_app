import 'package:flutter/material.dart';

/// Unified bottom sheet style used across the whole app.
Future<T?> showFitAIBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  bool isScrollControlled = true,
  double initialChildSize = 0.5,
  bool usesDraggable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: const Color(0xFF1C1C2E),
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => usesDraggable
        ? DraggableScrollableSheet(
            expand: false,
            initialChildSize: initialChildSize,
            builder: (_, controller) => _SheetContent(
              child: child,
              scrollController: controller,
            ),
          )
        : Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: _SheetContent(child: child),
          ),
  );
}

class _SheetContent extends StatelessWidget {
  final Widget child;
  final ScrollController? scrollController;
  const _SheetContent({required this.child, this.scrollController});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF5A5A7A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(child: child),
        ],
      );
}
