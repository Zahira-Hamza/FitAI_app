import 'package:flutter/material.dart';

/// Central snackbar factory. All screens use these instead of raw SnackBar.
class SnackBarHelper {
  SnackBarHelper._();

  static void showError(BuildContext context, String message) {
    _show(context, message, const Color(0xFFFF6584), Icons.error_outline);
  }

  static void showSuccess(BuildContext context, String message) {
    _show(context, message, const Color(0xFF43E97B), Icons.check_circle_outline);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, const Color(0xFF6C63FF), Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message,
    Color accentColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: accentColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF252538),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: accentColor.withOpacity(0.6), width: 1),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
