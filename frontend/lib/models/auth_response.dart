class AuthResponse {
  final String uid;
  final String? idToken;

  const AuthResponse({
    required this.uid,
    this.idToken,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      if (idToken != null) 'idToken': idToken,
    };
  }
}
