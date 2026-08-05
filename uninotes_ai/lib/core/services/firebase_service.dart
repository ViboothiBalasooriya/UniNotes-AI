import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../shared/models/university.dart';
import '../../shared/models/academic_hierarchy.dart';
import '../../shared/models/note.dart';
import '../../shared/models/user_role.dart';

final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Universities ─────────────────────────────────────────────────────────────

  Stream<List<University>> streamUniversities() {
    return _db
        .collection(AppConstants.colUniversities)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(University.fromFirestore).toList());
  }

  Future<void> addUniversity(University university) async {
    await _db.collection(AppConstants.colUniversities).add(university.toFirestore());
  }

  Future<void> updateUniversity(University university) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(university.id)
        .update({'name': university.name, 'acronym': university.acronym, 'country': university.country});
  }

  Future<void> deleteUniversity(String universityId) async {
    await _db.collection(AppConstants.colUniversities).doc(universityId).delete();
  }

  // ─── Faculties ────────────────────────────────────────────────────────────────

  Stream<List<Faculty>> streamFaculties(String universityId) {
    return _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Faculty.fromFirestore(doc, universityId)).toList());
  }

  Future<void> addFaculty(String universityId, Faculty faculty) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .add(faculty.toFirestore());
  }

  Future<void> updateFaculty(String universityId, Faculty faculty) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(faculty.id)
        .update(faculty.toFirestore());
  }

  Future<void> deleteFaculty(String universityId, String facultyId) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .delete();
  }

  // ─── Departments ──────────────────────────────────────────────────────────────

  Stream<List<Department>> streamDepartments(String universityId, String facultyId) {
    return _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .collection(AppConstants.colDepartments)
        .orderBy('name')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Department.fromFirestore(doc, universityId, facultyId)).toList());
  }

  Future<void> addDepartment(String universityId, String facultyId, Department dept) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .collection(AppConstants.colDepartments)
        .add(dept.toFirestore());
  }

  Future<void> updateDepartment(String universityId, String facultyId, Department dept) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .collection(AppConstants.colDepartments)
        .doc(dept.id)
        .update(dept.toFirestore());
  }

  Future<void> deleteDepartment(
      String universityId, String facultyId, String departmentId) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .collection(AppConstants.colDepartments)
        .doc(departmentId)
        .delete();
  }

  // ─── Courses ──────────────────────────────────────────────────────────────────

  Stream<List<Course>> streamCourses(
      String universityId, String facultyId, String departmentId) {
    return _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .collection(AppConstants.colDepartments)
        .doc(departmentId)
        .collection(AppConstants.colCourses)
        .orderBy('code')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Course.fromFirestore(doc, universityId, facultyId, departmentId))
            .toList());
  }

  Future<void> addCourse(
      String universityId, String facultyId, String departmentId, Course course) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .collection(AppConstants.colDepartments)
        .doc(departmentId)
        .collection(AppConstants.colCourses)
        .add(course.toFirestore());
  }

  Future<void> deleteCourse(
      String universityId, String facultyId, String departmentId, String courseId) async {
    await _db
        .collection(AppConstants.colUniversities)
        .doc(universityId)
        .collection(AppConstants.colFaculties)
        .doc(facultyId)
        .collection(AppConstants.colDepartments)
        .doc(departmentId)
        .collection(AppConstants.colCourses)
        .doc(courseId)
        .delete();
  }

  // ─── Notes ────────────────────────────────────────────────────────────────────

  Stream<List<Note>> streamApprovedNotes(String courseId) {
    return _db
        .collection(AppConstants.colNotes)
        .where('courseId', isEqualTo: courseId)
        .where('status', isEqualTo: AppConstants.statusApproved)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Note.fromFirestore).toList());
  }

  Future<void> addNote(Note note) async {
    await _db.collection(AppConstants.colNotes).add(note.toFirestore());
  }

  Future<void> incrementViewCount(String noteId) async {
    await _db.collection(AppConstants.colNotes).doc(noteId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteNote(String noteId) async {
    await _db.collection(AppConstants.colNotes).doc(noteId).delete();
  }

  // ─── Saved Notes (Bookmarks) ──────────────────────────────────────────────────

  Stream<List<String>> streamSavedNoteIds(String userId) {
    return _db
        .collection(AppConstants.colSavedNotes)
        .doc(userId)
        .collection('notes')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  Future<void> saveNote(String userId, String noteId) async {
    await _db
        .collection(AppConstants.colSavedNotes)
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .set({'savedAt': FieldValue.serverTimestamp()});
  }

  Future<void> unsaveNote(String userId, String noteId) async {
    await _db
        .collection(AppConstants.colSavedNotes)
        .doc(userId)
        .collection('notes')
        .doc(noteId)
        .delete();
  }

  Future<List<Note>> getSavedNotes(String userId) async {
    final savedSnap = await _db
        .collection(AppConstants.colSavedNotes)
        .doc(userId)
        .collection('notes')
        .orderBy('savedAt', descending: true)
        .get();

    final noteIds = savedSnap.docs.map((doc) => doc.id).toList();
    if (noteIds.isEmpty) return [];

    // Fetch notes in batches (Firestore 'whereIn' limit: 30)
    final notes = <Note>[];
    for (int i = 0; i < noteIds.length; i += 30) {
      final batch = noteIds.sublist(i, i + 30 > noteIds.length ? noteIds.length : i + 30);
      final snap = await _db
          .collection(AppConstants.colNotes)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      notes.addAll(snap.docs.map(Note.fromFirestore));
    }
    return notes;
  }

  // ─── User Roles ───────────────────────────────────────────────────────────────

  Future<UserRole?> getUserRole(String uid) async {
    final doc = await _db.collection(AppConstants.colUserRoles).doc(uid).get();
    if (!doc.exists) return null;
    return UserRole.fromFirestore(doc);
  }

  Future<void> setUserRole(String uid, String role) async {
    await _db.collection(AppConstants.colUserRoles).doc(uid).set({
      'role': role,
      'assignedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<UserRole>> streamAllUserRoles() {
    return _db
        .collection(AppConstants.colUserRoles)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(UserRole.fromFirestore).toList());
  }
}
