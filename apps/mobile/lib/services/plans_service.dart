import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/plan.dart';

/// API base URL for the admin backend.
const _adminApiBase = String.fromEnvironment(
  'ADMIN_API_BASE_URL',
  defaultValue: 'https://hvac-pro-admin.web.app',
);

/// Service for fetching subscription plans from the admin backend.
class PlansService {
  final http.Client _client = http.Client();

  /// Fetch active plans from the admin backend.
  /// Returns null on failure.
  Future<List<Plan>?> getActivePlans() async {
    try {
      final uri = Uri.parse('$_adminApiBase/api/plans/active');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final plansJson = body['plans'] as List<dynamic>?;
      if (plansJson == null) return null;

      return plansJson
          .map((e) => Plan.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
