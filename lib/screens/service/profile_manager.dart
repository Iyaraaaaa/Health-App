import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  // Create or update user profile data during signup
  static Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    String? profileImageBase64,
  }) async {
    final now = Timestamp.now();

    final userData = {
      'uid': uid,
      'email': email,
      'name': name,
      'createdAt': now,
      'updatedAt': now,
      'isActive': true,
    };

    // Add profile image fields
    if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
      userData['profileImageBase64'] = profileImageBase64;
      userData['imageUrl'] = 'data:image/jpeg;base64,$profileImageBase64';
    } else {
      userData['profileImageBase64'] = '';
      userData['imageUrl'] = '';
    }

    // Save to Firestore
    await usersCollection.doc(uid).set(userData, SetOptions(merge: true));

    // Save to SharedPreferences for immediate access
    await _saveToSharedPreferences(uid, email, name, 
        profileImageBase64 != null && profileImageBase64.isNotEmpty 
            ? 'data:image/jpeg;base64,$profileImageBase64' 
            : '');
  }

  // Update user profile (for EditProfile functionality)
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? profileImageBase64,
  }) async {
    final Map<String, dynamic> updatedData = {
      'updatedAt': Timestamp.now(),
    };

    if (name != null && name.isNotEmpty) {
      updatedData['name'] = name;
    }

    if (profileImageBase64 != null) {
      if (profileImageBase64.isNotEmpty) {
        updatedData['profileImageBase64'] = profileImageBase64;
        updatedData['imageUrl'] = 'data:image/jpeg;base64,$profileImageBase64';
      } else {
        updatedData['profileImageBase64'] = '';
        updatedData['imageUrl'] = '';
      }
    }

    // Update in Firestore
    await usersCollection.doc(uid).update(updatedData);

    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      await prefs.setString('userName', name);
    }
    if (profileImageBase64 != null) {
      if (profileImageBase64.isNotEmpty) {
        await prefs.setString('userImage', 'data:image/jpeg;base64,$profileImageBase64');
      } else {
        await prefs.remove('userImage');
      }
    }
  }

  // Get user profile by UID
  static Future<DocumentSnapshot> getUser(String uid) async {
    return await usersCollection.doc(uid).get();
  }

  // Get current user data (Firebase + Firestore + SharedPreferences)
  static Future<Map<String, String>> getCurrentUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Try to get data from Firestore first
        final userDoc = await usersCollection.doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null) {
            final result = {
              'userId': currentUser.uid,
              'userName': userData['name']?.toString() ?? currentUser.displayName ?? 'User Name',
              'userEmail': userData['email']?.toString() ?? currentUser.email ?? 'user@example.com',
              'userImage': '',
            };

            // Handle profile image
            if (userData['profileImageBase64'] != null && userData['profileImageBase64'].toString().isNotEmpty) {
              result['userImage'] = 'data:image/jpeg;base64,${userData['profileImageBase64']}';
            } else if (userData['imageUrl'] != null && userData['imageUrl'].toString().isNotEmpty) {
              result['userImage'] = userData['imageUrl'].toString();
            }

            // Update SharedPreferences with latest data
            await _saveToSharedPreferences(
              result['userId']!,
              result['userEmail']!,
              result['userName']!,
              result['userImage']!,
            );

            return result;
          }
        }
      }
    } catch (e) {
      print('Error fetching user data from Firestore: $e');
    }

    // Fallback to SharedPreferences
    return await _getFromSharedPreferences();
  }

  // Save user data to SharedPreferences
  static Future<void> _saveToSharedPreferences(
    String userId,
    String userEmail,
    String userName,
    String userImage,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('userEmail', userEmail);
    await prefs.setString('userName', userName);
    if (userImage.isNotEmpty) {
      await prefs.setString('userImage', userImage);
    }
  }

  // Get user data from SharedPreferences
  static Future<Map<String, String>> _getFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? '',
      'userName': prefs.getString('userName') ?? 'User Name',
      'userEmail': prefs.getString('userEmail') ?? 'user@example.com',
      'userImage': prefs.getString('userImage') ?? '',
    };
  }

  // Clear all user data (for logout)
  static Future<void> clearUserData() async {
    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null;
  }

  // Refresh user data from Firestore and update local storage
  static Future<Map<String, String>> refreshUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        final userDoc = await usersCollection.doc(currentUser.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          if (userData != null) {
            final result = {
              'userId': currentUser.uid,
              'userName': userData['name']?.toString() ?? currentUser.displayName ?? 'User Name',
              'userEmail': userData['email']?.toString() ?? currentUser.email ?? 'user@example.com',
              'userImage': '',
            };

            // Handle profile image
            if (userData['profileImageBase64'] != null && userData['profileImageBase64'].toString().isNotEmpty) {
              result['userImage'] = 'data:image/jpeg;base64,${userData['profileImageBase64']}';
            } else if (userData['imageUrl'] != null && userData['imageUrl'].toString().isNotEmpty) {
              result['userImage'] = userData['imageUrl'].toString();
            }

            // Update SharedPreferences
            await _saveToSharedPreferences(
              result['userId']!,
              result['userEmail']!,
              result['userName']!,
              result['userImage']!,
            );

            return result;
          }
        }
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }

    // Fallback to SharedPreferences
    return await _getFromSharedPreferences();
  }

  // Listen to user data changes in real-time
  static Stream<DocumentSnapshot> getUserDataStream(String uid) {
    return usersCollection.doc(uid).snapshots();
  }

  // Update user's last active timestamp
  static Future<void> updateLastActive(String uid) async {
    try {
      await usersCollection.doc(uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating last active: $e');
    }
  }
}