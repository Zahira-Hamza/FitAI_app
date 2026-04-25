import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/connectivity_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init Hive for offline cache
  await Hive.initFlutter();
  await Hive.openBox<String>('workouts_cache');
  await Hive.openBox<String>('ai_cache');
  await Hive.openBox<String>('sessions_cache');

  // Init Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } catch (e) {
    debugPrint('Firebase init failed or already initialized: $e');
  }
  // Load .env — mergeMode keeps existing env vars if .env is missing
  try {
    await dotenv.load(fileName: "correct.env", mergeWith: {});
  } catch (e) {
    // .env not found — AI features will show error, app continues
    debugPrint('.env file not found: $e');
  }
  runApp(const ProviderScope(child: FitAIApp()));
}

class FitAIApp extends ConsumerWidget {
  const FitAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'FitAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) => _ConnectivityWrapper(child: child!),
    );
  }
}

/// Shows a persistent amber banner at the top when offline.
/// Does NOT block the app — user can still use cached data.
class _ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _ConnectivityWrapper({required this.child});

  @override
  ConsumerState<_ConnectivityWrapper> createState() =>
      _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<_ConnectivityWrapper> {
  bool _wasOffline = false;

  @override
  Widget build(BuildContext context) {
    final connectivityAsync = ref.watch(connectivityProvider);

    return connectivityAsync.when(
      data: (isOnline) {
        // Show "back online" snackbar once
        if (_wasOffline && isOnline) {
          _wasOffline = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.wifi, color: Color(0xFF43E97B), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Back online ✓',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF252538),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF43E97B), width: 1),
                ),
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }

        if (!isOnline) _wasOffline = true;

        return Column(
          children: [
            Expanded(child: widget.child),
            // Offline banner at bottom
            if (!isOnline)
              Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 7,
                    horizontal: 16,
                  ),
                  color: const Color(0xFFFFB347).withOpacity(0.15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFFFB347),
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'No internet — showing cached data',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: Color(0xFFFFB347),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => widget.child,
      error: (_, __) => widget.child,
    );
  }
}
