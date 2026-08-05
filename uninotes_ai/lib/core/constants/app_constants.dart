class AppConstants {
  AppConstants._();

  // ─── App Info ─────────────────────────────────────────────────────────────────
  static const String appName = 'UniNotes AI';
  static const String appVersion = '1.0.0';

  // ─── Firestore Collections ────────────────────────────────────────────────────
  static const String colUniversities = 'universities';
  static const String colFaculties = 'faculties';
  static const String colDepartments = 'departments';
  static const String colCourses = 'courses';
  static const String colNotes = 'notes';
  static const String colSavedNotes = 'savedNotes';
  static const String colUserRoles = 'userRoles';

  // ─── Firebase Storage ─────────────────────────────────────────────────────────
  static const String storageBucket = 'academic_materials';
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20MB
  static const String allowedFileType = 'application/pdf';

  // ─── Pagination ───────────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int pendingNotesLimit = 50;

  // ─── AI Context ───────────────────────────────────────────────────────────────
  static const int maxContextChars = 8000;
  static const int maxSummarizeChars = 10000;

  // ─── Note Status Values ───────────────────────────────────────────────────────
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusFlagged = 'flagged';
  static const String statusDeleted = 'deleted';

  // ─── User Roles ───────────────────────────────────────────────────────────────
  static const String roleStudent = 'student';
  static const String roleAdmin = 'admin';

  // ─── Shared Prefs Keys ────────────────────────────────────────────────────────
  static const String prefOnboardingDone = 'onboarding_done';
  static const String prefSelectedUniversityId = 'selected_university_id';
}
