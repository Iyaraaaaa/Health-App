import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Create user profile with Base64 image
  static Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    File? profileImage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      String? base64Image;
      if (profileImage != null) {
        base64Image = await _encodeImageToBase64(profileImage);
      }

      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'profileImageBase64': base64Image ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        ...?additionalData,
      };

      await _firestore.collection('users').doc(uid).set(userData);
      
      // Save to SharedPreferences (without image for performance)
      await _saveUserDataLocally(name, email, base64Image ?? '');
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Convert image to Base64
  static Future<String> _encodeImageToBase64(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  // Convert Base64 to Image (Uint8List)
  static Uint8List _decodeBase64ToImage(String base64String) {
    return base64Decode(base64String);
  }

  // Get user profile with Base64 image
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update profile image (Base64)
  static Future<void> updateProfileImage({
    required String uid,
    required File newImage,
  }) async {
    try {
      final base64Image = await _encodeImageToBase64(newImage);
      await _firestore.collection('users').doc(uid).update({
        'profileImageBase64': base64Image,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }

  // Delete profile image (set to empty string)
  static Future<void> deleteProfileImage(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'profileImageBase64': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Load user data with image
  static Future<Map<String, dynamic>> loadUserData() async {
    final user = currentUser;
    if (user == null) return await _loadLocalUserData();

    try {
      final profile = await getUserProfile(user.uid);
      if (profile == null) throw Exception('No profile found');

      return {
        'name': profile['name'] ?? user.displayName ?? "User",
        'email': profile['email'] ?? user.email ?? "",
        'imageBytes': profile['profileImageBase64'] != null && 
                     profile['profileImageBase64'].isNotEmpty
            ? _decodeBase64ToImage(profile['profileImageBase64'])
            : null,
      };
    } catch (e) {
      return await _loadLocalUserData();
    }
  }

  // SharedPreferences helpers (unchanged)
  static Future<void> _saveUserDataLocally(String name, String email, String imageBase64) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);
    // Note: Avoid saving large Base64 strings locally
  }

  static Future<Map<String, dynamic>> _loadLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName') ?? "User",
      'email': prefs.getString('userEmail') ?? "",
      'imageBytes': null,
    };
  }
}