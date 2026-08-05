import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get middlewareBaseUrl =>
      dotenv.env['MIDDLEWARE_BASE_URL'] ?? 'http://localhost:3000';

  // ─── AI Endpoints ─────────────────────────────────────────────────────────────
  static String get aiExplainUrl => '$middlewareBaseUrl/api/ai/explain';
  static String get aiSummarizeUrl => '$middlewareBaseUrl/api/ai/summarize';

  // ─── Admin Endpoints ──────────────────────────────────────────────────────────
  static String get adminPendingNotesUrl => '$middlewareBaseUrl/api/admin/notes/pending';
  static String adminNoteStatusUrl(String noteId) =>
      '$middlewareBaseUrl/api/admin/notes/$noteId/status';
  static String get adminUsersUrl => '$middlewareBaseUrl/api/admin/users';
  static String adminRoleUrl(String uid) => '$middlewareBaseUrl/api/admin/roles/$uid';

  // ─── Health ───────────────────────────────────────────────────────────────────
  static String get healthUrl => '$middlewareBaseUrl/api/health';

  // ─── Timeouts ─────────────────────────────────────────────────────────────────
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
