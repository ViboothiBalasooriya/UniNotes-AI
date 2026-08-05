import 'package:cloud_firestore/cloud_firestore.dart';

class Note {
  final String id;
  final String courseId;
  final String uploaderId;
  final String uploaderName;
  final String title;
  final String description;
  final String fileUrl;
  final int fileSize;
  final String status; // 'pending' | 'approved' | 'flagged'
  final DateTime uploadedAt;
  final int viewCount;

  const Note({
    required this.id,
    required this.courseId,
    required this.uploaderId,
    required this.uploaderName,
    required this.title,
    required this.description,
    required this.fileUrl,
    required this.fileSize,
    required this.status,
    required this.uploadedAt,
    required this.viewCount,
  });

  factory Note.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Note(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      uploaderId: data['uploaderId'] ?? '',
      uploaderName: data['uploaderName'] ?? 'Anonymous',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      status: data['status'] ?? 'pending',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewCount: data['viewCount'] ?? 0,
    );
  }

  factory Note.fromMap(Map<String, dynamic> data, String id) {
    return Note(
      id: id,
      courseId: data['courseId'] ?? '',
      uploaderId: data['uploaderId'] ?? '',
      uploaderName: data['uploaderName'] ?? 'Anonymous',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      status: data['status'] ?? 'pending',
      uploadedAt: DateTime.tryParse(data['uploadedAt'] ?? '') ?? DateTime.now(),
      viewCount: data['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'courseId': courseId,
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'title': title,
        'description': description,
        'fileUrl': fileUrl,
        'fileSize': fileSize,
        'status': status,
        'uploadedAt': FieldValue.serverTimestamp(),
        'viewCount': viewCount,
      };

  /// Returns file size in a human-readable format (e.g., "2.4 MB")
  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isFlagged => status == 'flagged';

  Note copyWith({String? status, int? viewCount}) => Note(
        id: id,
        courseId: courseId,
        uploaderId: uploaderId,
        uploaderName: uploaderName,
        title: title,
        description: description,
        fileUrl: fileUrl,
        fileSize: fileSize,
        status: status ?? this.status,
        uploadedAt: uploadedAt,
        viewCount: viewCount ?? this.viewCount,
      );
}
