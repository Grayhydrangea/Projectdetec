// lib/home.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/user_model.dart';
import 'sign_in_page.dart';

class HomePage extends StatefulWidget {
  final String uid; // รับ UID มาจากหน้า Login

  const HomePage({super.key, required this.uid});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Home = 0, Profile = 1
  UserModel? _user;
  String _role = ''; // guard | security | admin | student | (อื่นๆ)
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();

      if (!mounted) return;

      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        setState(() {
          _user = UserModel.fromJson(data);
          _role = (data['role'] ?? '').toString().trim().toLowerCase();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ดึงข้อมูลผู้ใช้ล้มเหลว: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.pushNamed(
        context,
        '/profile',
        arguments: {'uid': widget.uid},
      );
    }
  }

  Future<void> _logout() async {
    if (!mounted) return;
    // ถ้าใช้งาน FirebaseAuth ให้ signOut() เพิ่มได้ที่นี่
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final greetingName =
        (_user?.name.trim().isNotEmpty ?? false) ? _user!.name : 'Username';

    // ผู้ที่เป็น staff = guard/security/admin
    final bool isStaff =
        _role == 'guard' || _role == 'security' || _role == 'admin';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.school, size: 24),
            SizedBox(width: 8),
            Text(
              'University of Phayao',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ทักทายด้วยชื่อจาก Firestore
                  Text(
                    'Hi, $greetingName!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[800],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // การ์ด: ดูบันทึกการเข้า-ออก (นิสิต/ทุกบทบาทเห็นได้)
                  Card(
                    color: Colors.purple[50],
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.bar_chart, color: Colors.purple[700], size: 32),
                      title: const Text(
                        'ดูบันทึกการเข้า - ออก',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/parking_list',
                        arguments: {'uid': widget.uid},
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // การ์ด: รายงาน (แสดงเฉพาะ guard/security/admin)
                  if (isStaff)
                    Card(
                      color: Colors.purple[50],
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.report, color: Colors.purple[700], size: 32),
                        title: const Text(
                          'ดูรายงานการเข้า - ออก',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/balance',
                          arguments: {'uid': widget.uid},
                        ),
                      ),
                    ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple[700],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
