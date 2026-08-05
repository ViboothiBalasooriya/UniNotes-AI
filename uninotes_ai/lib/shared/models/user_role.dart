import 'package:cloud_firestore/cloud_firestore.dart';

class UserRole {
  final String uid;
  final String role; // 'student' | 'admin'
  final DateTime assignedAt;
  final String assignedBy;

  const UserRole({
    required this.uid,
    required this.role,
    required this.assignedAt,
    required this.assignedBy,
  });

  factory UserRole.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRole(
      uid: doc.id,
      role: data['role'] ?? 'student',
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedBy: data['assignedBy'] ?? '',
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isStudent => role == 'student';
}

class AiMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  const AiMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
  });

  AiMessage copyWith({String? content, bool? isLoading}) => AiMessage(
        id: id,
        content: content ?? this.content,
        isUser: isUser,
        timestamp: timestamp,
        isLoading: isLoading ?? this.isLoading,
      );
}
