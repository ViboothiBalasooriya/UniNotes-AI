import 'package:cloud_firestore/cloud_firestore.dart';

class Faculty {
  final String id;
  final String universityId;
  final String name;
  final String code;

  const Faculty({
    required this.id,
    required this.universityId,
    required this.name,
    required this.code,
  });

  factory Faculty.fromFirestore(DocumentSnapshot doc, String universityId) {
    final data = doc.data() as Map<String, dynamic>;
    return Faculty(
      id: doc.id,
      universityId: universityId,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {'name': name, 'code': code};

  Faculty copyWith({String? name, String? code}) =>
      Faculty(id: id, universityId: universityId, name: name ?? this.name, code: code ?? this.code);
}

class Department {
  final String id;
  final String facultyId;
  final String universityId;
  final String name;
  final String code;

  const Department({
    required this.id,
    required this.facultyId,
    required this.universityId,
    required this.name,
    required this.code,
  });

  factory Department.fromFirestore(DocumentSnapshot doc, String universityId, String facultyId) {
    final data = doc.data() as Map<String, dynamic>;
    return Department(
      id: doc.id,
      facultyId: facultyId,
      universityId: universityId,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {'name': name, 'code': code};

  Department copyWith({String? name, String? code}) => Department(
        id: id,
        facultyId: facultyId,
        universityId: universityId,
        name: name ?? this.name,
        code: code ?? this.code,
      );
}

class Course {
  final String id;
  final String departmentId;
  final String facultyId;
  final String universityId;
  final String name;
  final String code;
  final String semester;
  final int year;

  const Course({
    required this.id,
    required this.departmentId,
    required this.facultyId,
    required this.universityId,
    required this.name,
    required this.code,
    required this.semester,
    required this.year,
  });

  factory Course.fromFirestore(
    DocumentSnapshot doc,
    String universityId,
    String facultyId,
    String departmentId,
  ) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      departmentId: departmentId,
      facultyId: facultyId,
      universityId: universityId,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      semester: data['semester'] ?? '',
      year: data['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'code': code,
        'semester': semester,
        'year': year,
      };
}
