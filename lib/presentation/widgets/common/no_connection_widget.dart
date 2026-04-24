import 'package:flutter/material.dart';

/// Full-screen no-connection state. Drop inside any screen's body
/// when connectivity is lost, or use NoConnectionScreen as a route.
class NoConnectionWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onGoOffline;

  const NoConnectionWidget({
    super.key,
    required this.onRetry,
    this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C2E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF5A5A7A).withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFF5A5A7A),
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Connection',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Check your internet connection\nand try again',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  color: Color(0xFF9E9EBE),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              if (onGoOffline != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onGoOffline,
                    icon: const Icon(Icons.cloud_off_outlined,
                        size: 16, color: Color(0xFF9E9EBE)),
                    label: const Text(
                      'Go Offline',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9E9EBE),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5A5A7A)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Pro tip card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF43E97B).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.bolt_rounded,
                          color: Color(0xFF43E97B), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pro Tip',
                              style: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your streak is safe! Local training data will sync once you\'re back online.',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 12,
                                color: Color(0xFF9E9EBE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
}
