import 'package:flutter/material.dart';
import 'package:frontend/services/authapi.dart';
import 'package:frontend/exceptions/auth_exception.dart';
import 'package:logger/logger.dart';
import 'sign_in_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});           // ✅ const constructor
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers (รวม first/last ให้เป็น name ตอนส่ง register)
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ช่องที่ลอจิกเดิมต้องใช้
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  String? _selectedRole; // 'นิสิต' | 'ผู้รักษาความปลอดภัย'

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  @override
  void dispose() {
    _logger.d('Disposing SignUpPage controllers');
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      _logger.w('Form validation failed');
      return;
    }

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name =
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    final phone = _phoneController.text.trim();
    final role =
        _selectedRole == 'นิสิต' ? 'student' : 'security';
    final plate = _selectedRole == 'นิสิต'
        ? _plateController.text.trim()
        : null;

    _logger.d('SignUp attempt with data: email=$email, role=$_selectedRole, phone=$phone, plate=${plate ?? "N/A"}');

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        name: name.isEmpty ? email : name, // กันกรณีผู้ใช้ไม่ได้กรอกชื่อ
        phone: phone,
        role: role,
        plate: plate,
      );

      _logger.i('Registration successful: UID = ${response.uid}');

      if (!mounted) return;
      // กลับไปหน้าเข้าสู่ระบบตาม UI ที่ให้มา
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInPage()),
      );
      // หรือถ้าตั้ง route ไว้แล้ว:
      // Navigator.pushReplacementNamed(context, '/login');
    } on AuthException catch (e) {
      _logger.e('Registration failed: ${e.message}, Code: ${e.code}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สมัครสมาชิกไม่สำเร็จ: ${e.message}')),
      );
    } catch (e) {
      _logger.e('Unexpected error during registration: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _logger.d('SignUp process completed');
      }
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
            // ตาม UI ตัวอย่างใช้ pushReplacementNamed ไป /login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SignInPage()),
            );
            // หรือถ้าตั้ง route:
            // Navigator.pushReplacementNamed(context, '/login');
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
                    // Logo (เหมือนหน้า Login UI ใหม่)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(Icons.two_wheeler,
                          size: 60, color: Colors.black),
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

                    // === ฟิลด์ตาม UI ใหม่ ===
                    // ชื่อ
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
                    ),
                    const SizedBox(height: 16),

                    // นามสกุล
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'นามสกุล',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'กรุณากรอกนามสกุล' : null,
                    ),
                    const SizedBox(height: 16),

                    // อีเมล
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'อีเมล',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกอีเมล';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'กรุณากรอกอีเมลที่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // รหัสผ่าน
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรหัสผ่าน';
                        }
                        if (value.length < 6) {
                          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ยืนยันรหัสผ่าน
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'ยืนยันรหัสผ่าน',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณายืนยันรหัสผ่าน';
                        }
                        if (value != _passwordController.text) {
                          return 'รหัสผ่านไม่ตรงกัน';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // หมายเลขทะเบียนรถ (จาก UI ใหม่) — จะทำงานร่วมกับเงื่อนไขนิสิตด้านล่าง
                    // (เราจะโชว์ช่องนี้เสมอเพราะ UI ใหม่ต้องการ แต่จะตรวจ required เฉพาะตอนเลือก "นิสิต")
                    TextFormField(
                      controller: _plateController,
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

                    // === ฟิลด์เพิ่มที่ลอจิกเดิมต้องใช้ (แทรกแบบกลมกลืนกับ UI) ===
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'คุณคือ ?',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'นิสิต', child: Text('นิสิต')),
                        DropdownMenuItem(
                          value: 'ผู้รักษาความปลอดภัย',
                          child: Text('ผู้รักษาความปลอดภัย'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                          _logger.d('Selected role: $value');
                        });
                      },
                      validator: (value) =>
                          value == null ? 'กรุณาเลือกบทบาท' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'เบอร์โทรศัพท์',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกเบอร์โทรศัพท์';
                        }
                        if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                          return 'กรุณากรอกเบอร์โทรศัพท์ 10 หลัก';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ปุ่มสมัครสมาชิก
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
