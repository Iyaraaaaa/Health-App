import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Create or update user profile data
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    required String name,
    String? profileImageUrl,  // optional
  }) async {
    final now = Timestamp.now();

    final userData = {
      'email': email,
      'name': name,
      'profileImageUrl': profileImageUrl ?? '',
      'updatedAt': now,
      'createdAt': now,
    };

    await usersCollection.doc(uid).set(userData, SetOptions(merge: true));
  }

  // Get user profile by UID
  Future<DocumentSnapshot> getUser(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  // Update user profile fields (name and/or profileImageUrl)
  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? profileImageUrl,
  }) async {
    final Map<String, dynamic> updatedData = {
      'updatedAt': Timestamp.now(),
    };

    if (name != null) updatedData['name'] = name;
    if (profileImageUrl != null) updatedData['profileImageUrl'] = profileImageUrl;

    await usersCollection.doc(uid).update(updatedData);
  }
}