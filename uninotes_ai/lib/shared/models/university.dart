import 'package:cloud_firestore/cloud_firestore.dart';

class University {
  final String id;
  final String name;
  final String acronym;
  final String country;
  final DateTime createdAt;

  const University({
    required this.id,
    required this.name,
    required this.acronym,
    required this.country,
    required this.createdAt,
  });

  factory University.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return University(
      id: doc.id,
      name: data['name'] ?? '',
      acronym: data['acronym'] ?? '',
      country: data['country'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'acronym': acronym,
      'country': country,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  University copyWith({String? name, String? acronym, String? country}) {
    return University(
      id: id,
      name: name ?? this.name,
      acronym: acronym ?? this.acronym,
      country: country ?? this.country,
      createdAt: createdAt,
    );
  }
}
