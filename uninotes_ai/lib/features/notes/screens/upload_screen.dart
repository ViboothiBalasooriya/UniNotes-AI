import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/note.dart';
import 'package:uuid/uuid.dart';

class UploadScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String courseName;
  const UploadScreen({super.key, required this.courseId, required this.courseName});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _selectedFile;
  String? _selectedFileName;
  int _fileSize = 0;
  double _uploadProgress = 0;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final size = await file.length();
      if (size > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File too large. Maximum size is 20MB.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      setState(() {
        _selectedFile = file;
        _selectedFileName = result.files.single.name;
        _fileSize = size;
        // Auto-fill title from filename (without extension)
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.single.name.replaceAll('.pdf', '');
        }
      });
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a PDF file.'), backgroundColor: AppColors.warning),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // 1. Upload PDF to Firebase Storage
      final fileUrl = await ref.read(storageServiceProvider).uploadPdf(
            file: _selectedFile!,
            courseId: widget.courseId,
            fileName: _selectedFileName!,
            onProgress: (progress) {
              setState(() => _uploadProgress = progress);
            },
          );

      // 2. Create Note document in Firestore (status = 'pending')
      final note = Note(
        id: '',
        courseId: widget.courseId,
        uploaderId: user.uid,
        uploaderName: user.displayName ?? user.email ?? 'Anonymous',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        fileUrl: fileUrl,
        fileSize: _fileSize,
        status: 'pending',
        uploadedAt: DateTime.now(),
        viewCount: 0,
      );

      await ref.read(firebaseServiceProvider).addNote(note);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Upload successful! Your note is pending admin review.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: ${e.toString()}'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Notes'),
            Text(
              widget.courseName,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondaryDark),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── File Picker ───────────────────────────────────────────────
              GestureDetector(
                onTap: _isUploading ? null : _pickFile,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    border: Border.all(
                      color: _selectedFile != null
                          ? AppColors.success
                          : AppColors.borderDark,
                      width: _selectedFile != null ? 2 : 1,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _selectedFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                size: 40, color: AppColors.textSecondaryDark),
                            const SizedBox(height: 12),
                            Text('Tap to select PDF',
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text('Maximum size: 20MB',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.textSecondaryDark)),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded,
                                size: 40, color: AppColors.success),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _selectedFileName!,
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(_fileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondaryDark),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Title ─────────────────────────────────────────────────────
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Note Title *',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 3) return 'Title is too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ─── Description ───────────────────────────────────────────────
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ─── Pending Notice ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your upload will be reviewed by an administrator before it appears in the course. This usually takes a short time.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Upload Progress ───────────────────────────────────────────
              if (_isUploading) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Uploading...', style: Theme.of(context).textTheme.bodySmall),
                    Text('${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.borderDark,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 24),
              ],

              // ─── Upload Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('upload_submit_btn'),
                  onPressed: _isUploading ? null : _upload,
                  icon: _isUploading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(_isUploading ? 'Uploading...' : 'Upload for Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
