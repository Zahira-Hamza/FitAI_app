import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository.dart';
import 'user_profile_provider.dart';
import 'progress_provider.dart';
import 'ai_coach_provider.dart';
import 'active_workout_provider.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final User? currentUser;

  const AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.currentUser,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    User? currentUser,
    bool clearError = false,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage:
            clearError ? null : (errorMessage ?? this.errorMessage),
        currentUser: currentUser ?? this.currentUser,
      );
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref)
      : super(AuthState(currentUser: _authRepository.currentUser)) {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      state = state.copyWith(currentUser: user, clearError: true);
    });
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.signInWithEmail(email, password);
      state = state.copyWith(isLoading: false);
      // Refresh user-specific providers for the new user
      _refreshUserProviders();
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUpWithEmail(
      String email, String password, String name) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.signUpWithEmail(email, password, name);
      state = state.copyWith(isLoading: false);
      _refreshUserProviders();
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final credential = await _authRepository.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      // Refresh user-specific providers for the new account
      _refreshUserProviders();
      return credential != null;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // ── Clear all user-specific provider state BEFORE signing out ──
      _clearUserProviders();

      await _authRepository.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> hasCompletedProfile() async {
    final user = state.currentUser;
    if (user == null) return false;
    return _authRepository.hasCompletedProfile(user.uid);
  }

  void clearError() => state = state.copyWith(clearError: true);

  // ── Provider management ───────────────────────────────────────

  /// Invalidates all providers that hold user-specific data.
  /// Called on sign out so the next user gets a clean slate.
  void _clearUserProviders() {
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(progressProvider);
    _ref.invalidate(aiCoachProvider);
    _ref.invalidate(activeWorkoutProvider);
  }

  /// Refreshes user-specific providers after a new sign in.
  /// Forces them to reload data for the newly signed-in account.
  void _refreshUserProviders() {
    _ref.invalidate(userProfileProvider);
    _ref.invalidate(progressProvider);
    _ref.invalidate(aiCoachProvider);
  }
}
