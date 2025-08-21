import 'package:flutter/material.dart';
import 'package:frontend/services/authapi.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/exceptions/auth_exception.dart';
import 'package:logger/logger.dart'; // Added for debugging
import 'sign_in_page.dart'; // Link to SignInPage

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final Logger _logger = Logger(); 

  @override
  void dispose() {
    _logger.d('Disposing SignUpPage controllers');
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Log input data for debugging
      _logger.d('SignUp attempt with data: '
          'email: ${_emailController.text.trim()}, '
          'role: $_selectedRole, '
          'phone: ${_phoneController.text.trim()}, '
          'plate: ${_selectedRole == 'นิสิต' ? _plateController.text.trim() : 'N/A'}');

      try {
        final response = await _authService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _emailController.text.trim(), // Using email as name; adjust as needed
          phone: _phoneController.text.trim(),
          role: _selectedRole == 'นิสิต' ? 'student' : 'security',
          plate: _selectedRole == 'นิสิต' ? _plateController.text.trim() : null,
        );

        // Log success response
        _logger.i('Registration successful: UID = ${response.uid}');

        // Navigate to SignInPage on success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInPage()),
        );
      } on AuthException catch (e) {
        _logger.e('Registration failed: ${e.message}, Code: ${e.code}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('สมัครสมาชิกไม่สำเร็จ: ${e.message}')),
        );
      } catch (e) {
        _logger.e('Unexpected error during registration: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
        _logger.d('SignUp process completed');
      }
    } else {
      _logger.w('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/logo.png'),
                  ),
                  SizedBox(height: 20),

                  // App name
                  Text(
                    'UP PARKING',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),

                  // Role dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'คุณคือ ?',
                      border: OutlineInputBorder(),
                    ),
                    items: ['นิสิต', 'ผู้รักษาความปลอดภัย']
                        .map(
                          (label) => DropdownMenuItem(
                            value: label,
                            child: Text(label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                        _logger.d('Selected role: $value');
                      });
                    },
                    validator: (value) =>
                        value == null ? 'กรุณาเลือกบทบาท' : null,
                  ),
                  SizedBox(height: 10),

                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
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
                  SizedBox(height: 10),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน',
                      border: OutlineInputBorder(),
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
                  SizedBox(height: 10),

                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
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
                  SizedBox(height: 10),

                  // License plate field (only for students)
                  if (_selectedRole == 'นิสิต')
                    TextFormField(
                      controller: _plateController,
                      decoration: InputDecoration(
                        labelText: 'หมายเลขทะเบียนรถ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_selectedRole == 'นิสิต' &&
                            (value == null || value.isEmpty)) {
                          return 'กรุณากรอกหมายเลขทะเบียนรถ';
                        }
                        return null;
                      },
                    ),
                  if (_selectedRole == 'นิสิต') SizedBox(height: 10),

                  // Sign up button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}