// lib/models/auth_response.dart

class AuthResponse {
  final String uid;
  final String? idToken;
  final String? customToken; // ✅ เพิ่มฟิลด์ customToken

  const AuthResponse({
    required this.uid,
    this.idToken,
    this.customToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      uid: (json['uid'] ??
              (json['user'] is Map ? json['user']['uid'] : null) ??
              (json['data'] is Map ? json['data']['uid'] : null) ??
              '')
          .toString(),
      idToken: (json['idToken'] ??
              json['token'] ??
              (json['data'] is Map ? json['data']['idToken'] : null))
          ?.toString(),
      customToken: (json['customToken'] ??
              (json['data'] is Map ? json['data']['customToken'] : null))
          ?.toString(), // ✅ ดึง customToken จาก response
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      if (idToken != null) 'idToken': idToken,
      if (customToken != null) 'customToken': customToken, // ✅ serialize customToken ด้วย
    };
  }
}
