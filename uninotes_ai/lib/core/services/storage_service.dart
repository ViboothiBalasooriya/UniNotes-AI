import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a PDF file to Firebase Storage and returns the download URL.
  /// [courseId] is used to organize files in a logical folder structure.
  Future<String> uploadPdf({
    required File file,
    required String courseId,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    // Validate file size
    final fileSize = await file.length();
    if (fileSize > AppConstants.maxFileSizeBytes) {
      throw Exception('File size exceeds 20MB limit. Please choose a smaller file.');
    }

    // Build storage path: academic_materials/courses/{courseId}/{uid}/{timestamp}_{fileName}
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath =
        '${AppConstants.storageBucket}/courses/$courseId/$uid/${timestamp}_$fileName';

    final ref = _storage.ref(storagePath);
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'uploaderId': uid,
          'courseId': courseId,
          'originalName': fileName,
        },
      ),
    );

    // Progress tracking
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  /// Deletes a file from Firebase Storage by its download URL.
  Future<void> deleteByUrl(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      // File may have already been deleted — swallow the error
    }
  }
}
