import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in_page.dart';
import 'package:frontend/models/user_model.dart';

class HomePage extends StatefulWidget {
  final String uid; // รับ UID มาจากหน้า Login

  const HomePage({super.key, required this.uid});
  
  

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        setState(() {
          _user = UserModel.fromJson(doc.data()!);
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

  void _showUserInfoSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final u = _user;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: (u == null)
              ? const Center(child: Text('ไม่มีข้อมูลผู้ใช้'))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('ข้อมูลผู้ใช้',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('รายละเอียดบัญชีของคุณ'),
                    ),
                    const Divider(),
                    _infoRow('UID', u.uid),
                    _infoRow('ชื่อ', u.name),
                    _infoRow('อีเมล', u.email),
                    _infoRow('เบอร์โทร', u.phone),
                    _infoRow('บทบาท', _roleTh(u.role)),
                    if (u.role == 'student' && (u.plate ?? '').isNotEmpty)
                      _infoRow('ทะเบียนรถ', u.plate!),
                    const SizedBox(height: 8),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _logout() async {
    // ถ้าใช้ FirebaseAuth ให้ signOut ที่นี่ก่อน
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => SignInPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = (_user?.name.trim().isNotEmpty ?? false)
        ? 'สวัสดี, ${_user!.name}!'
        : 'สวัสดี, ผู้ใช้!';

    return Scaffold(
      appBar: AppBar(
        title: const Text('University of Phayao'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            tooltip: 'ข้อมูลผู้ใช้',
            icon: const Icon(Icons.person),
            onPressed: _showUserInfoSheet,
          ),
          IconButton(
            tooltip: 'ตั้งค่า',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          IconButton(
            tooltip: 'ออกจากระบบ',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/attendance'),
                    style: _btnStyle(),
                    child: const Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.white),
                        SizedBox(width: 16),
                        Text('ดูบันทึกการเข้า - ออก ของนิสิต',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('ฟังก์ชันนี้ยังไม่พร้อมใช้งาน')),
                      );
                    },
                    style: _btnStyle(),
                    child: const Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.white),
                        SizedBox(width: 16),
                        Text('ดูงานการเข้า - ออก',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Colors.purple,
      );

  static String _roleTh(String role) {
    switch (role) {
      case 'student':
        return 'นิสิต';
      case 'guard':
        return 'ผู้รักษาความปลอดภัย';
      case 'admin':
        return 'ผู้ดูแลระบบ';
      default:
        return role;
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child:
                Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
