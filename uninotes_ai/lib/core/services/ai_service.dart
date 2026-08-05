import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../../shared/models/user_role.dart';
import '../../shared/models/note.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

class AiService {
  /// Get the Firebase ID token for authenticated requests
  Future<String?> _getIdToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ─── Explain ──────────────────────────────────────────────────────────────────
  /// Explain a concept. Optionally provide [pdfText] for document-context mode.
  Future<String> explain({required String question, String? pdfText}) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse(ApiConstants.aiExplainUrl),
      headers: _headers(token),
      body: jsonEncode({
        'question': question,
        if (pdfText != null && pdfText.isNotEmpty) 'text': pdfText,
      }),
    ).timeout(ApiConstants.receiveTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['answer'] as String;
    }
    throw Exception(data['error'] ?? 'Failed to get explanation');
  }

  // ─── Summarize ────────────────────────────────────────────────────────────────
  /// Summarize a document. [text] is the extracted PDF text.
  Future<String> summarize({required String text, String? title}) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse(ApiConstants.aiSummarizeUrl),
      headers: _headers(token),
      body: jsonEncode({
        'text': text,
        if (title != null) 'title': title,
      }),
    ).timeout(ApiConstants.receiveTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['success'] == true) {
      return data['summary'] as String;
    }
    throw Exception(data['error'] ?? 'Failed to get summary');
  }

  // ─── Admin: Get Pending Notes ─────────────────────────────────────────────────
  Future<List<Note>> getPendingNotes() async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(ApiConstants.adminPendingNotesUrl),
      headers: _headers(token),
    ).timeout(ApiConstants.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      final notes = (data['notes'] as List)
          .map((n) => Note.fromMap(n as Map<String, dynamic>, n['id'] ?? ''))
          .toList();
      return notes;
    }
    throw Exception(data['error'] ?? 'Failed to fetch pending notes');
  }

  // ─── Admin: Update Note Status ────────────────────────────────────────────────
  Future<void> updateNoteStatus(String noteId, String status) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.patch(
      Uri.parse(ApiConstants.adminNoteStatusUrl(noteId)),
      headers: _headers(token),
      body: jsonEncode({'status': status}),
    ).timeout(ApiConstants.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to update note status');
    }
  }

  // ─── Admin: Set User Role ─────────────────────────────────────────────────────
  Future<void> setUserRole(String uid, String role) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.post(
      Uri.parse(ApiConstants.adminRoleUrl(uid)),
      headers: _headers(token),
      body: jsonEncode({'role': role}),
    ).timeout(ApiConstants.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to set role');
    }
  }

  // ─── Admin: Get All User Roles ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllUserRoles() async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    final response = await http.get(
      Uri.parse(ApiConstants.adminUsersUrl),
      headers: _headers(token),
    ).timeout(ApiConstants.connectionTimeout);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['users'] as List);
    }
    throw Exception(data['error'] ?? 'Failed to fetch users');
  }
}
