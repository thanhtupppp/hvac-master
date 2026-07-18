import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String photoURL; // Can store preset color name or image URL
  final bool isPremium;
  final DateTime? premiumExpiry;
  final String? activeSubscriptionId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoURL,
    required this.isPremium,
    this.premiumExpiry,
    this.activeSubscriptionId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? getDateTime(dynamic field) {
      if (field is Timestamp) {
        return field.toDate();
      }
      return null;
    }

    // Default display name: prefix of email
    final email = data['email'] as String? ?? '';
    final defaultDisplayName = email.isNotEmpty ? email.split('@').first : 'Kỹ thuật viên';

    return UserModel(
      uid: doc.id,
      email: email,
      displayName: data['displayName'] as String? ?? defaultDisplayName,
      photoURL: data['photoURL'] as String? ?? 'purple', // Default to purple preset color
      isPremium: data['isPremium'] as bool? ?? false,
      premiumExpiry: getDateTime(data['premiumExpiry']),
      activeSubscriptionId: data['activeSubscriptionId'] as String?,
      status: data['status'] as String? ?? 'active',
      createdAt: getDateTime(data['createdAt']),
      updatedAt: getDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry != null ? Timestamp.fromDate(premiumExpiry!) : null,
      'activeSubscriptionId': activeSubscriptionId,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    bool? isPremium,
    DateTime? premiumExpiry,
    String? activeSubscriptionId,
    String? status,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      activeSubscriptionId: activeSubscriptionId ?? this.activeSubscriptionId,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
