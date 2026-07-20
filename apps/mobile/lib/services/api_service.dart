import 'dart:convert';
import 'package:http/http.dart' as http;

/// API base URL — pass `--dart-define=ADMIN_API_BASE_URL=https://your-admin.vercel.app`
/// when building. Defaults to the local dev server.
const _apiBase = String.fromEnvironment(
  'ADMIN_API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

/// A minimal HTTP client for calling the admin API with Firebase ID token auth.
class ApiService {
  final http.Client _client = http.Client();

  /// POST [path] with an optional JSON [body] and the Firebase ID token as Bearer.
  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    required String idToken,
  }) async {
    final uri = Uri.parse('$_apiBase$path');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: body != null ? jsonEncode(body) : null,
    );
    return ApiResponse(
      statusCode: response.statusCode,
      body: response.body.isNotEmpty ? jsonDecode(response.body) : null,
    );
  }

  void dispose() {
    _client.close();
  }
}

/// Parsed HTTP response from the admin API.
class ApiResponse {
  final int statusCode;
  final dynamic body;

  ApiResponse({required this.statusCode, required this.body});

  bool get ok => statusCode >= 200 && statusCode < 300;

  String? get errorMessage {
    if (body is Map<String, dynamic>) {
      return (body as Map<String, dynamic>)['message'] as String? ??
          (body as Map<String, dynamic>)['error'] as String?;
    }
    return null;
  }

  bool get requiresRecentLogin =>
      (body is Map<String, dynamic>) &&
      (body as Map<String, dynamic>)['error'] == 'requires-recent-login';
}
