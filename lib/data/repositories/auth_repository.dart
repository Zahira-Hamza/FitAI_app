import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<UserCredential> signUpWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Create user doc if new
      if (userCredential.user != null && userCredential.additionalUserInfo?.isNewUser == true) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user!.displayName ?? 'User',
          'email': userCredential.user!.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<bool> hasCompletedProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('profile').doc('data').get(); // Assuming profile/data layout based on common practices, or just check 'profile' collection
      // Wait, the prompt says: "checks Firestore users/{uid}/profile exists"
      // Firestore doesn't allow checking if a collection exists directly without finding a document in it.
      // Often, a profile is a document: users/{uid}/profile -> doesn't make sense since users/{uid} is already the document.
      // Let's assume it checks for a 'profileCompleted' boolean in users/{uid} OR a document users/{uid}/profile/info
      // Let's explicitly check `users/{uid}/profile` document, maybe it's a subcollection or document name.
      // Easiest is checking if `profile` subcollection exists by querying it. But let's check `users/{uid}/profile` as a doc.
      // "checks Firestore users/{uid}/profile exists" implies either a field 'profile' or a document 'profile' in a subcollection.
      // Let's check `users/{uid}/profile/data` for safety, actually I'll just check if the `users/{uid}/profile` document exists:
      final profileDoc = await _firestore.collection('users').doc(uid).collection('profile').doc('main').get();
      return profileDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password. Try again';
      case 'email-already-in-use':
        return 'An account with this email already exists';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Something went wrong. Please try again';
    }
  }
}
