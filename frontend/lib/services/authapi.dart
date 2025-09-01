// lib/services/authapi.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

class AuthException implements Exception {
  final String message;
  final int? status;
  AuthException(this.message, {this.status});
  @override
  String toString() => 'AuthException($status): $message';
}

class RegisterResponse {
  final String uid;
  RegisterResponse({required this.uid});
}

class LoginResponse {
  final String uid;
  final String? customToken;
  LoginResponse({required this.uid, this.customToken});

  factory LoginResponse.fromJson(Map<String, dynamic> j) => LoginResponse(
        uid: (j['uid'] ?? '').toString(),
        customToken: j['customToken'] as String?,
      );
}

class AuthService {
  Future<RegisterResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? plate,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');
    final body = {
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'role': role,
      if (plate != null && plate.trim().isNotEmpty) 'plate': plate.trim(),
    };

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final data = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return RegisterResponse(uid: (data['uid'] ?? '').toString());
    }
    throw AuthException(
      data['error']?.toString() ?? 'Register failed',
      status: resp.statusCode,
    );
  }

  Future<LoginResponse> loginWithUid({required String uid}) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid}),
    );

    final data = jsonDecode(resp.body.isEmpty ? '{}' : resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return LoginResponse.fromJson(data as Map<String, dynamic>);
    }
    throw AuthException(
      data['error']?.toString() ?? 'Login failed',
      status: resp.statusCode,
    );
  }
}
