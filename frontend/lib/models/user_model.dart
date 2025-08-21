class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String? plate; // Optional, only for students

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    this.plate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['uid'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      plate: json['plate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      if (plate != null) 'plate': plate,
    };
  }
}
