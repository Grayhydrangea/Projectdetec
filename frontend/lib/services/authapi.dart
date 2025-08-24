// lib/services/authapi.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:frontend/models/auth_response.dart';
import 'package:frontend/exceptions/auth_exception.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// REGISTER: สร้างบัญชีด้วย FirebaseAuth + สร้างเอกสาร users/{uid}
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role, // 'student' | 'guard' | 'admin' | 'security'
    String? plate,
  }) async {
    try {
      // 1) สร้างผู้ใช้บน FirebaseAuth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      // 2) อัปเดต displayName (optional)
      await cred.user!.updateDisplayName(name.trim());

      // 3) สร้างเอกสาร users/{uid} ใน Firestore (ถ้ายังไม่มี)
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'name': name.trim(),
        'phone': phone.trim(),
        'role': role,                 // ใช้ประกอบใน UI เท่านั้น (สิทธิ์จริงดูจาก Custom Claims)
        'plate': plate ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4) ดึง idToken (ถ้าจะส่งต่อ/ดีบัก)
      final idToken = await cred.user!.getIdToken();

      return AuthResponse(uid: uid, idToken: idToken);
    } on FirebaseAuthException catch (e) {
      // map เป็นข้อยกเว้นเดิมของคุณ
      switch (e.code) {
        case 'email-already-in-use':
          throw RegisterException('อีเมลนี้ถูกใช้ไปแล้ว', code: e.code);
        case 'invalid-email':
          throw RegisterException('อีเมลไม่ถูกต้อง', code: e.code);
        case 'weak-password':
          throw RegisterException('รหัสผ่านอ่อนเกินไป', code: e.code);
        default:
          throw RegisterException('สมัครสมาชิกไม่สำเร็จ: ${e.message}', code: e.code);
      }
    } catch (e) {
      throw RegisterException('Registration error: $e');
    }
  }

  /// LOGIN: เข้าสู่ระบบด้วย FirebaseAuth
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // สำคัญ: refresh token เพื่อดึง Custom Claims ล่าสุด
      await cred.user!.getIdToken(true);

      final uid = cred.user!.uid;
      final idToken = await cred.user!.getIdToken();

      return AuthResponse(uid: uid, idToken: idToken);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          throw LoginException('Invalid email or password', code: e.code);
        case 'invalid-email':
          throw LoginException('อีเมลไม่ถูกต้อง', code: e.code);
        case 'user-disabled':
          throw LoginException('บัญชีนี้ถูกระงับการใช้งาน', code: e.code);
        default:
          throw LoginException('เข้าสู่ระบบไม่สำเร็จ: ${e.message}', code: e.code);
      }
    } catch (e) {
      throw LoginException('Login error: $e');
    }
  }

  /// OPTIONAL: ออกจากระบบ
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// OPTIONAL: ดึง uid ปัจจุบัน (ถ้าล็อกอินอยู่)
  String? currentUid() => _auth.currentUser?.uid;
}
