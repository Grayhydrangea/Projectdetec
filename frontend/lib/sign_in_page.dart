import 'package:flutter/material.dart';
import 'package:frontend/services/authapi.dart';
import 'package:frontend/exceptions/auth_exception.dart';
import 'package:logger/logger.dart'; // Added for debugging
import 'home.dart'; // Link to HomePage
import 'sign_up_page.dart'; // Link to SignUpPage

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final AuthService _authService = AuthService();
  final Logger _logger = Logger(); // Initialize logger for debugging

  @override
  void dispose() {
    _logger.d('Disposing SignInPage controllers');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      _isLoading = true;
    });

    _logger.d('SignIn attempt with email: ${_emailController.text.trim()}');

    try {
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      _logger.i('Login successful: UID = ${response.uid}, Token = ${response.idToken}');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(uid: response.uid)),
      );
    } on AuthException catch (e) {
      _logger.e('Login failed: ${e.message}, Code: ${e.code}');
      String errorMessage = e.message;
      if (e.message.contains('Invalid email or password')) {
        errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เข้าสู่ระบบไม่สำเร็จ: $errorMessage')),
      );
    } catch (e) {
      _logger.e('Unexpected error during login: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _logger.d('SignIn process completed');
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
                  SizedBox(height: 20),

                  // Sign In button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text('Sign In'),
                  ),

                  // Sign Up link
                  TextButton(
                    onPressed: () {
                      _logger.d('Navigating to SignUpPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(color: Colors.black),
                    ),
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