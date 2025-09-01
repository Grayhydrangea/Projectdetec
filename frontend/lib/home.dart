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
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

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

  // ---------- การ์ด “สถานะปัจจุบันของรถฉัน” (เฉพาะนิสิต) ----------
  Widget _buildStudentStatusCard() {
    // ใช้ StreamBuilder เพื่ออัปเดตแบบเรียลไทม์เมื่อมีบันทึกใหม่
    final q = FirebaseFirestore.instance
        .collection('attendance')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('time', descending: true)
        .limit(1);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snap.hasError) {
          return Card(
            color: Colors.red[50],
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: Colors.red[700], size: 40),
                  const SizedBox(height: 12),
                  const Text('โหลดสถานะล้มเหลว',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${snap.error}', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Card(
            color: Colors.grey[100],
            elevation: 6,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.directions_bike, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('ยังไม่มีข้อมูลการเข้า-ออก',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('รถของคุณยังไม่ถูกตรวจพบเลย'),
                ],
              ),
            ),
          );
        }

        final m = docs.first.data();
        final statusRaw = (m['status'] ?? '').toString().toLowerCase().trim();
        final location = (m['locationId'] ?? m['location'] ?? '')
            .toString()
            .trim();
        final statusText = statusRaw == 'entry'
            ? 'เข้าแล้ว'
            : statusRaw == 'exit'
                ? 'ออกแล้ว'
                : (statusRaw.isEmpty ? 'ไม่ทราบ' : statusRaw);
        final statusColor = statusRaw == 'entry'
            ? Colors.green
            : statusRaw == 'exit'
                ? Colors.orange
                : Colors.grey;

        return Card(
          color: Colors.purple[50],
          elevation: 6,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            // ทำให้ “เต็มพื้นที่ว่าง” มากขึ้นด้วย padding ใหญ่ + จัดกลาง
            padding:
                const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_bike, color: statusColor, size: 48),
                const SizedBox(height: 12),
                Text(
                  'สถานะปัจจุบันของรถคุณ',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.place, size: 18, color: Colors.purple[700]),
                    const SizedBox(width: 6),
                    Text(
                      location.isNotEmpty ? 'ที่จุดตรวจ: $location' : 'ยังไม่ทราบจุดตรวจ',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
              child: ListView(
                // ใช้ ListView เพื่อให้การ์ดสถานะ “ยืดพื้นที่” ได้สวย และเลื่อนหน้าได้
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

                  // การ์ด “สถานะปัจจุบันของรถฉัน” – เฉพาะนิสิต
                  if (_role == 'student') ...[
                    const SizedBox(height: 16),
                    _buildStudentStatusCard(),
                  ],

                  const SizedBox(height: 24),

                  // การ์ด: ดูบันทึกการเข้า-ออก (ทุกบทบาทเห็นได้)
                  Card(
                    color: Colors.purple[50],
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.bar_chart,
                          color: Colors.purple[700], size: 32),
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

                  // การ์ด: รายงาน (เฉพาะ guard/security/admin)
                  if (isStaff)
                    Card(
                      color: Colors.purple[50],
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.report,
                            color: Colors.purple[700], size: 32),
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
