import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const int _maxRetryAttempts = 3;
  static const int _maxFileSizeMB = 10;

  Future<String?> uploadFileWithRetry({
    required String path,
    required File file,
    required String userId,
    void Function(double)? onProgress,
  }) async {
    int attempt = 0;
    late UploadTask uploadTask;
    String? lastError;

    // Validate file first
    try {
      await _validateFile(file);
    } catch (e) {
      debugPrint('File validation failed: $e');
      rethrow;
    }

    while (attempt < _maxRetryAttempts) {
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final ref = _storage.ref('users/$userId/$path/$fileName');

        // Start the upload task
        uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentType: _getMimeType(file.path),
            customMetadata: {'uploaded_by': userId},
          ),
        );

        // Listen for upload progress
        uploadTask.snapshotEvents.listen((taskSnapshot) {
          final progress = taskSnapshot.bytesTransferred / taskSnapshot.totalBytes;
          onProgress?.call(progress);  // Report progress
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        });

        // Wait for the upload to complete
        final taskSnapshot = await uploadTask;
        return await taskSnapshot.ref.getDownloadURL();  // Return the download URL
      } on FirebaseException catch (e) {
        attempt++;
        lastError = 'Attempt $attempt failed: ${e.code} - ${e.message}';
        debugPrint(lastError);

        // Break if the upload should be canceled or has reached max retries
        if (attempt >= _maxRetryAttempts || e.code == 'object-not-found' || e.code == 'canceled') {
          break;
        }

        // Exponential backoff for retry logic
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        lastError = 'Unexpected error: $e';
        debugPrint(lastError);
        break;
      }
    }

    // Cancel the upload task if it's still running after retries
    try {
      if (uploadTask.snapshot.state == TaskState.running) {
        await uploadTask.cancel();
      }
    } catch (e) {
      debugPrint('Error canceling upload: $e');
    }

    throw Exception('Upload failed after $_maxRetryAttempts attempts. Last error: $lastError');
  }

  /// Validates image file before upload
  Future<void> _validateFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw Exception('Selected file does not exist');
    }

    // Check file size (max 10MB)
    final sizeInMB = await file.length() / (1024 * 1024);
    if (sizeInMB > _maxFileSizeMB) {
      throw Exception('File size exceeds $_maxFileSizeMB MB limit');
    }
  }

  /// Determines MIME type from file extension
  String? _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }

  /// Deletes file from Firebase Storage
  Future<void> deleteFile(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        rethrow;  // Rethrow if it's another error
      }
      debugPrint('File already deleted: $url');
    }
  }
}
