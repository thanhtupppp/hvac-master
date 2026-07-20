import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

/// Exposes the real-time user profile state from Firestore.
final userProfileProvider = StreamProvider<UserModel?>((ref) {
  final authState = FirebaseAuth.instance.authStateChanges();

  // Transform auth state change stream into Firestore user document stream
  final controller = StreamController<UserModel?>();
  StreamSubscription? sub;

  final authSub = authState.listen((user) {
    sub?.cancel();
    if (user == null) {
      controller.add(null);
      return;
    }

    // Reference to user document
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    sub = docRef.snapshots().listen(
      (snapshot) async {
        if (!snapshot.exists) {
          // Automatically create user document if it doesn't exist yet
          final email = user.email ?? '';
          final defaultDisplayName = email.isNotEmpty
              ? email.split('@').first
              : 'Kỹ thuật viên';

          final initialData = {
            'email': email,
            'displayName': defaultDisplayName,
            'photoURL': 'purple',
            'isPremium': false,
            'status': 'active',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          };

          try {
            await docRef.set(initialData);
          } catch (e) {
            // If fail (e.g. offline), add a temporary model to stream
          }

          controller.add(
            UserModel(
              uid: user.uid,
              email: email,
              displayName: defaultDisplayName,
              photoURL: 'purple',
              isPremium: false,
              status: 'active',
            ),
          );
        } else {
          controller.add(UserModel.fromFirestore(snapshot));
        }
      },
      onError: (err) {
        controller.addError(err);
      },
    );
  });

  ref.onDispose(() {
    authSub.cancel();
    sub?.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Service class containing helper methods to update user profiles and delete accounts.
class UserProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Update the current user's display name.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    await _db.collection('users').doc(user.uid).update({
      'displayName': displayName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update the current user's preset avatar color.
  Future<void> updateAvatarColor(String colorName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    await _db.collection('users').doc(user.uid).update({
      'photoURL': colorName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete the user account via the trusted backend endpoint.
  ///
  /// The backend (Admin SDK) handles:
  ///  1. ID token verification (checkRevoked: true).
  ///  2. recent-login check via adminAuth.getUser().
  ///  3. Recursive deletion of all subcollections.
  ///  4. Deletion of the user Firestore document.
  ///  5. Deletion of the Firebase Auth account.
  ///
  /// Throws with a message containing 'đăng nhập lại' when the backend
  /// reports auth/requires-recent-login, so the UI can prompt re-auth.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    // Force-refresh the ID token so the backend can verify it with
    // checkRevoked: true (checks token has not been invalidated since issue).
    final idToken = await user.getIdToken(true);
    if (idToken == null) {
      throw Exception('Không lấy được token xác thực. Vui lòng đăng nhập lại.');
    }

    final api = ApiService();
    try {
      final res = await api.post(
        '/api/profile/delete',
        body: {'uid': user.uid},
        idToken: idToken,
      );

      if (res.requiresRecentLogin) {
        throw Exception(
          'Hành động nhạy cảm - Vui lòng đăng nhập lại trước khi xóa tài khoản.',
        );
      }

      if (!res.ok) {
        throw Exception(
          res.errorMessage ?? 'Xóa tài khoản thất bại. Vui lòng thử lại.',
        );
      }
      // Backend succeeded — local sign-out is handled by the caller
      // (_executeDeleteAccount in profile_screen.dart).
    } finally {
      api.dispose();
    }
  }
}

/// Provider exposing UserProfileService.
final userProfileServiceProvider = Provider((ref) => UserProfileService());
