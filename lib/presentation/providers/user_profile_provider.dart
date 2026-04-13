import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/firebase_service.dart';
import 'auth_provider.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

class UserProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const UserProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      UserProfileState(
        profile: profile ?? this.profile,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );

  bool get isProfileComplete => profile != null;
}

class UserProfileNotifier extends StateNotifier<UserProfileState> {
  final FirebaseService _firebaseService;
  final Ref _ref;

  UserProfileNotifier(this._firebaseService, this._ref)
      : super(const UserProfileState()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _ref.read(authStateProvider).currentUser;
    if (user == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _firebaseService.getUserProfile(user.uid);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _firebaseService.saveUserProfile(profile);
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    await saveProfile(profile);
  }

  Future<void> updateAvatarUrl(String uid, String url) async {
    try {
      await _firebaseService.updateAvatarUrl(uid, url);
      if (state.profile != null) {
        state = state.copyWith(
          profile: state.profile!.copyWith(avatarUrl: url),
        );
      }
    } catch (_) {}
  }

  void refreshProfile() => _loadProfile();
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileState>((ref) {
  return UserProfileNotifier(
    ref.watch(firebaseServiceProvider),
    ref,
  );
});
