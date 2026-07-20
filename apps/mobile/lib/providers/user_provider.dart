import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

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

  /// Request deletion of the user account.
  /// Standard procedure: mark account status as 'deleted_request' in Firestore
  /// and perform Firebase Auth account deletion.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final uid = user.uid;

    // 1. Mark status in Firestore first for audit trails
    await _db.collection('users').doc(uid).update({
      'status': 'deleted_request',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Clear bookmarks and settings locally if any, then delete Auth account
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'Hành động nhạy cảm - Vui lòng đăng nhập lại trước khi xóa tài khoản.',
        );
      }
      rethrow;
    }
  }
}

/// Provider exposing UserProfileService.
final userProfileServiceProvider = Provider((ref) => UserProfileService());
