import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Updates user profile with new image, handling all upload and update operations
  Future<void> updateProfileWithImage({
    required String userId,
    required XFile imageFile,
    required BuildContext context,
    int maxRetries = 3,
  }) async {
    try {
      // Show initial loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image...'),
            duration: Duration(minutes: 1), // Long duration for upload
          ),
        );
      }

      // Convert XFile to File and validate
      final file = File(imageFile.path);
      await _validateImageFile(file);

      // Upload image with retry logic
      String? imageUrl;
      int attempt = 0;
      while (attempt < maxRetries) {
        try {
          imageUrl = await _uploadProfileImage(
            userId: userId,
            file: file,
            onProgress: (progress) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Uploading ${(progress * 100).toStringAsFixed(0)}%'),
                    duration: const Duration(minutes: 1),
                  ),
                );
              }
            },
          );
          break; // Success, exit retry loop
        } catch (e) {
          attempt++;
          debugPrint('Upload attempt $attempt failed: $e');
          if (attempt >= maxRetries) rethrow;
          await Future.delayed(Duration(seconds: attempt)); // Exponential backoff
        }
      }

      // Update user document with new image URL
      await _firestore.collection('users').doc(userId).update({
        'profileImage': imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${_getUserFriendlyError(e)}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      rethrow;
    }
  }

  /// Uploads profile image to Firebase Storage
  Future<String> _uploadProfileImage({
    required String userId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last;
      final filename = 'profile_$timestamp.$extension';

      // Create storage reference
      final ref = _storage.ref('users/$userId/profile_images/$filename');

      // Start upload task
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getMimeType(file.path),
          customMetadata: {'uploadedBy': userId},
        ),
      );

      // Listen for progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for completion
      final taskSnapshot = await uploadTask;
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error in _uploadProfileImage: $e');
      rethrow;
    }
  }

  /// Validates image file before upload
  Future<void> _validateImageFile(File file) async {
    const maxSizeMB = 5;
    const maxSizeBytes = maxSizeMB * 1024 * 1024;

    if (!await file.exists()) {
      throw Exception('Selected file does not exist');
    }

    final fileSize = await file.length();
    if (fileSize > maxSizeBytes) {
      throw Exception('Image must be smaller than $maxSizeMB MB');
    }
  }

  /// Determines MIME type from file extension
  String? _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return null;
    }
  }

  /// Converts technical errors to user-friendly messages
  String _getUserFriendlyError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'canceled':
          return 'Upload was canceled';
        case 'object-not-found':
          return 'Storage location not found';
        case 'quota-exceeded':
          return 'Storage quota exceeded';
        case 'unauthenticated':
          return 'Please sign in again';
        case 'unauthorized':
          return 'You don\'t have permission';
        default:
          return 'Network error occurred';
      }
    }
    return error.toString();
  }
}
