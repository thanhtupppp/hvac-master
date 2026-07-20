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
  /// Google Play policy (2024+): must actually delete all user data.
  /// Steps: (1) delete all user subcollection docs, (2) delete user doc,
  /// (3) delete Firebase Auth account.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final uid = user.uid;
    final userDoc = _db.collection('users').doc(uid);

    // 1. Delete all subcollection docs (bookmarks, history, settings, etc.)
    // Recursively delete everything under the user doc.
    // Use a write batch to delete in batches of 500 (Firestore limit).
    await _deleteCollection(userDoc.collection('bookmarks'));
    await _deleteCollection(userDoc.collection('history'));
    // Add more subcollections here as they are created (e.g. 'notes', 'settings')

    // 2. Delete the user profile document
    await userDoc.delete();

    // 3. Delete Firebase Auth account
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

  /// Recursively deletes all documents in a collection using batched writes.
  Future<void> _deleteCollection(CollectionReference ref) async {
    try {
      while (true) {
        final batch = _db.batch();
        final docs = await ref.limit(500).get();

        if (docs.size == 0) break;

        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      // Subcollection may not exist yet — skip silently
    }
  }
}

/// Provider exposing UserProfileService.
final userProfileServiceProvider = Provider((ref) => UserProfileService());
