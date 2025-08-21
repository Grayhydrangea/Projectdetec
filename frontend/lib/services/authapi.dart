import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:frontend/models/auth_response.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/exceptions/auth_exception.dart';

class AuthService {
  // ใช้ 10.0.2.2 สำหรับ Android Emulator ที่จะชี้ไปยัง localhost ของเครื่องเรา
  static const String _baseUrl = 'http://10.0.2.2:3000';
  static const _defaultTimeout = Duration(seconds: 20);

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Helper: decode JSON ปลอดภัย
  dynamic _safeJsonDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // Helper: ดึงข้อความ error จาก body (หากเป็น JSON)
  String _extractError(dynamic decoded, int status) {
    if (decoded is Map) {
      final msg = decoded['error'] ?? decoded['message'] ?? decoded['msg'];
      if (msg is String && msg.trim().isNotEmpty) return msg;
    }
    return 'Request failed (HTTP $status)';
  }

  // Register user
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? plate,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');

    try {
      final resp = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'email': email,
              'password': password,
              'name': name,
              'phone': phone,
              'role': role,
              if (plate != null) 'plate': plate,
            }),
          )
          .timeout(_defaultTimeout);
          
          print('[REGISTER] status=${resp.statusCode} body=${resp.body}'); 

      final decoded = _safeJsonDecode(resp.body);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        // รองรับรูป JSON หลายแบบจาก backend
        // ตัวอย่าง:
        // { "uid": "...", "idToken": "..." }
        // { "user": {"uid": "..."}, "token": "..." }
        // { "data": {"uid": "...", "idToken": "..."} }
        Map<String, dynamic>? payload;

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('uid') || decoded.containsKey('idToken')) {
            payload = decoded;
          } else if (decoded['user'] is Map) {
            payload = {
              'uid': decoded['user']['uid'],
              'idToken': decoded['token'] ?? decoded['idToken'],
            };
          } else if (decoded['data'] is Map) {
            payload = Map<String, dynamic>.from(decoded['data']);
          }
        }

        if (payload == null) {
          throw RegisterException('Unexpected response shape from server.');
        }

        return AuthResponse.fromJson(payload);
      } else {
        throw RegisterException(_extractError(decoded, resp.statusCode));
      }
    } on SocketException {
      throw NetworkException('No internet connection.');
    } on HttpException catch (e) {
      throw RegisterException('HTTP error: ${e.message}');
    } on FormatException {
      throw RegisterException('Bad response format.');
    } on RegisterException {
      rethrow;
    } catch (e) {
      throw RegisterException('Registration error: $e');
    }
  }

  // Login user
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');

    try {
      final resp = await http
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_defaultTimeout);

      final decoded = _safeJsonDecode(resp.body);

      if (resp.statusCode == 200) {
        Map<String, dynamic>? payload;

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('uid') || decoded.containsKey('idToken')) {
            payload = decoded;
          } else if (decoded['user'] is Map) {
            payload = {
              'uid': decoded['user']['uid'],
              'idToken': decoded['token'] ?? decoded['idToken'],
            };
          } else if (decoded['data'] is Map) {
            payload = Map<String, dynamic>.from(decoded['data']);
          }
        }

        if (payload == null) {
          throw LoginException('Unexpected response shape from server.');
        }

        return AuthResponse.fromJson(payload);
      } else {
        throw LoginException(_extractError(decoded, resp.statusCode));
      }
    } on SocketException {
      throw NetworkException('No internet connection.');
    } on HttpException catch (e) {
      throw LoginException('HTTP error: ${e.message}');
    } on FormatException {
      throw LoginException('Bad response format.');
    } on LoginException {
      rethrow;
    } catch (e) {
      throw LoginException('Login error: $e');
    }
  }
}
