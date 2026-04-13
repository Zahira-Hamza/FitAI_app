import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/workout_session.dart';
import '../models/personal_record.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── User Profile ──────────────────────────────────────────────
  Future<void> saveUserProfile(UserProfile profile) async {
    await _db
        .collection('users')
        .doc(profile.uid)
        .collection('profile')
        .doc('main')
        .set(profile.toMap());
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('main')
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap({...doc.data()!, 'uid': uid});
    } catch (_) {
      return null;
    }
  }

  Future<void> updateAvatarUrl(String uid, String url) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('main')
        .update({'avatarUrl': url});
  }

  // ── Sessions ──────────────────────────────────────────────────
  Future<void> saveWorkoutSession(WorkoutSession session) async {
    await _db
        .collection('users')
        .doc(session.userId)
        .collection('sessions')
        .doc(session.id)
        .set(session.toMap());
  }

  Future<List<WorkoutSession>> getTodaySessions(String uid) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThan: endOfDay.toIso8601String())
          .get();

      return snap.docs
          .map((d) => WorkoutSession.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<WorkoutSession>> getRecentSessions(String uid,
      {int limit = 3}) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((d) => WorkoutSession.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<WorkoutSession>> getWeeklySessions(
      String uid, DateTime weekStart) async {
    try {
      final weekEnd = weekStart.add(const Duration(days: 7));
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .where('date', isGreaterThanOrEqualTo: weekStart.toIso8601String())
          .where('date', isLessThan: weekEnd.toIso8601String())
          .get();

      return snap.docs
          .map((d) => WorkoutSession.fromMap({...d.data(), 'id': d.id}))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── Personal Records ──────────────────────────────────────────
  Future<List<PersonalRecord>> getPersonalRecords(String uid) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('records')
          .orderBy('date', descending: true)
          .get();

      return snap.docs
          .map((d) => PersonalRecord.fromMap(d.data()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePersonalRecord(String uid, PersonalRecord record) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(record.exerciseName.replaceAll(' ', '_').toLowerCase())
        .set(record.toMap());
  }
}
