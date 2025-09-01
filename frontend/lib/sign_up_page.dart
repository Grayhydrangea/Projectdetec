// lib/sign_up_page.dart
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'services/authapi.dart';
import 'sign_in_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers (ยังคง UI เดิม: แยกชื่อ/นามสกุล แต่จะรวมเป็น name ตอนส่ง)
  final _firstNameCtl = TextEditingController();
  final _lastNameCtl  = TextEditingController();
  final _emailCtl     = TextEditingController();
  final _passwordCtl  = TextEditingController();
  final _confirmCtl   = TextEditingController();
  final _phoneCtl     = TextEditingController();
  final _plateCtl     = TextEditingController();

  String? _selectedRole; // 'นิสิต' | 'ผู้รักษาความปลอดภัย' | 'ผู้ดูแลระบบ'
  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _auth = AuthService();
  final _log  = Logger();

  @override
  void dispose() {
    _firstNameCtl.dispose();
    _lastNameCtl.dispose();
    _emailCtl.dispose();
    _passwordCtl.dispose();
    _confirmCtl.dispose();
    _phoneCtl.dispose();
    _plateCtl.dispose();
    super.dispose();
  }

  String _mapUiRoleToServer(String ui) {
    // แมปค่าจากดรอปดาวน์ให้ตรง backend
    switch (ui) {
      case 'นิสิต':
        return 'student';
      case 'ผู้รักษาความปลอดภัย':
        return 'security'; // ถ้าต้องการใช้ 'guard' ก็เปลี่ยนตรงนี้ได้
      default:
        return 'student';
    }
  }

  // ตัดช่องว่าง/ขีด และแปลงเป็นตัวพิมพ์ใหญ่ เพื่อให้ตรงกับ backend
  String _normalizePlate(String p) =>
      p.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '').replaceAll('-', '');

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailCtl.text.trim();
    final password = _passwordCtl.text;
    final name =
        '${_firstNameCtl.text.trim()} ${_lastNameCtl.text.trim()}'.trim();
    final phone = _phoneCtl.text.trim();

    final roleUi = _selectedRole ?? 'นิสิต';
    final role = _mapUiRoleToServer(roleUi);

    final plateRaw = _plateCtl.text.trim();
    final plate = (role == 'student' && plateRaw.isNotEmpty)
        ? _normalizePlate(plateRaw)
        : null;

    _log.i('Register -> email=$email, role=$role, plate=$plate, phone=$phone');

    try {
      final r = await _auth.register(
        email: email,
        password: password,
        name: name.isEmpty ? email : name,
        phone: phone,
        role: role,
        plate: plate,
      );

      _log.i('Registered OK: uid=${r.uid}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สมัครสมาชิกสำเร็จ')),
      );

      // กลับไปหน้าเข้าสู่ระบบ
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
    } on AuthException catch (e) {
      _log.e('Register failed: ${e.message}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สมัครสมาชิกไม่สำเร็จ: ${e.message}')),
      );
    } catch (e) {
      _log.e('Register error: $e');
      if (!mounted) return;
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
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'กลับไปหน้าเข้าสู่ระบบ',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignInPage()),
            );
          },
        ),
        title: const Text('สมัครสมาชิก'),
        centerTitle: true,
      ),
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
                    // โลโก้ + ชื่อแอป (คง UI เดิม)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.two_wheeler, size: 60, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'UP Parking',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // === ฟิลด์เดิมทั้งหมด คงหน้าตาเดิม ===
                    TextFormField(
                      controller: _firstNameCtl,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _lastNameCtl,
                      decoration: const InputDecoration(
                        labelText: 'นามสกุล',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'กรุณากรอกนามสกุล' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _emailCtl,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'กรุณากรอกอีเมล';
                        final re = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!re.hasMatch(value)) return 'กรุณากรอกอีเมลที่ถูกต้อง';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordCtl,
                      obscureText: _obscurePass,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                        if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmCtl,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'ยืนยันรหัสผ่าน',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon:
                              Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                        if (value != _passwordCtl.text) return 'รหัสผ่านไม่ตรงกัน';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // หมายเลขทะเบียนรถ (แสดงตาม UI เดิม; บังคับกรอกเฉพาะตอนเลือกนิสิต)
                    TextFormField(
                      controller: _plateCtl,
                      decoration: const InputDecoration(
                        labelText: 'หมายเลขทะเบียนรถ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_selectedRole == 'นิสิต' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'กรุณากรอกหมายเลขทะเบียนรถสำหรับนิสิต';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'คุณคือ ?',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'นิสิต', child: Text('นิสิต')),
                        DropdownMenuItem(value: 'ผู้รักษาความปลอดภัย', child: Text('ผู้รักษาความปลอดภัย')),
                      ],
                      value: _selectedRole,
                      onChanged: (v) => setState(() => _selectedRole = v),
                      validator: (v) => v == null ? 'กรุณาเลือกบทบาท' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneCtl,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทรศัพท์',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
                        if (!RegExp(r'^\d{9,10}$').hasMatch(value)) {
                          return 'กรุณากรอกเบอร์โทรศัพท์ให้ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('สมัครสมาชิก'),
                      ),
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
