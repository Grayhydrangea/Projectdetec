// lib/sign_in_page.dart
import 'package:flutter/material.dart';
import 'package:frontend/services/authapi.dart';
import 'package:frontend/exceptions/auth_exception.dart';
import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // 1) login กับ backend
      final resp = await _authApi.login(email: email, password: password);
      _logger.i('Backend login OK -> uid=${resp.uid} customToken=${resp.customToken != null}');

      // 2) ลงชื่อเข้าใช้ Firebase (มี customToken ใช้อันนี้ก่อน)
      UserCredential cred;
      if ((resp.customToken ?? '').isNotEmpty) {
        _logger.i('Use FirebaseAuth.signInWithCustomToken()');
        cred = await FirebaseAuth.instance.signInWithCustomToken(resp.customToken!);
      } else {
        _logger.w('No customToken — fallback to signInWithEmailAndPassword');
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // 3) refresh token เพื่อให้ custom claims (role) มาครบ
      await cred.user?.getIdToken(true);
      final tok = await cred.user?.getIdTokenResult();
      _logger.i('Signed in uid=${cred.user?.uid}, claims=${tok?.claims}');

      if (!mounted) return;

      // 4) ไปหน้า Home (ใช้ uid จาก Firebase ถ้า response ไม่มี)
      final uidToUse = (resp.uid.isNotEmpty) ? resp.uid : (cred.user?.uid ?? '');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: {'uid': uidToUse},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _logger.e('FirebaseAuth sign-in failed: ${e.code} ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เข้าสู่ระบบ Firebase ล้มเหลว: ${e.message}')),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      _logger.e('Backend login failed: ${e.message}');
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.purple),
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
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage()));
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
