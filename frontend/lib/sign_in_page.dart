// lib/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/authapi.dart';
import 'sign_up_page.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authApi = AuthService();
  final _logger = Logger();

  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // 1) ล็อกอิน Firebase ก่อน เพื่อให้ได้ uid
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = cred.user?.uid ?? '';
      if (uid.isEmpty) {
        throw Exception('Firebase login succeeded but uid is empty');
      }

      // 2) (ออปชันนัล) เรียก backend ด้วย uid ตามสัญญาของ /api/auth/login ตอนนี้
      try {
        final r = await _authApi.loginWithUid(uid: uid);
        _logger.i('Backend login ok -> uid=${r.uid}, customToken=${r.customToken != null}');
        // ถ้า backend คืน customToken มาและอยากใช้จริง ๆ:
        // await FirebaseAuth.instance.signInWithCustomToken(r.customToken!);
      } catch (e) {
        // ถ้า backend ล้มเหลว ไม่ให้ผู้ใช้ติด — ใช้ session Firebase ที่ล็อกอินแล้วต่อไป
        _logger.w('Backend loginWithUid failed: $e (continue with Firebase session)');
      }

      // 3) รีเฟรช IdToken เพื่อดึง custom claims (role) ล่าสุด
      await cred.user?.getIdToken(true);
      final claims = await cred.user?.getIdTokenResult();
      _logger.i('Signed in uid=${cred.user?.uid}, claims=${claims?.claims}');

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: {'uid': uid},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _logger.e('FirebaseAuth sign-in failed: ${e.code} ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เข้าสู่ระบบไม่สำเร็จ: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      _logger.e('Unexpected login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.two_wheeler, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'UP Parking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 32),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'กรุณากรอกอีเมล';
                        final re = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
                        if (!re.hasMatch(v)) return 'กรุณากรอกอีเมลที่ถูกต้อง';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                        if (v.length < 6) return 'รหัสผ่านต้องอย่างน้อย 6 ตัวอักษร';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('เข้าสู่ระบบ'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignUpPage()),
                        );
                      },
                      child: const Text('สมัครสมาชิก', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
