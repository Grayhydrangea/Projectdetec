import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  /// รับ uid มาได้; ถ้าไม่ส่งมาจะ fallback เป็น currentUser.uid
  final String? uid;
  const ProfilePage({super.key, this.uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 1; // แท็บโปรไฟล์
  bool _loading = true;

  // ข้อมูลผู้ใช้
  String username = 'Username';
  String fullName = 'ชื่อ / นามสกุล';
  String email = '—';
  String phone = '—';
  String role = '—';
  String carLicense = '—'; // <-- จะแม็พกับ licensePlate
  String passwordMasked = '************'; // แสดงเฉย ๆ ไม่ดึงจริง

  String? _docUid; // uid ที่ใช้งานจริง

  String? get _effectiveUid {
    if (widget.uid != null && widget.uid!.isNotEmpty) return widget.uid!;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = _effectiveUid;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่')),
      );
      return;
    }

    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!mounted) return;

      if (!snap.exists || snap.data() == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้')),
        );
        return;
      }

      final data = snap.data()!;

      final displayName = (data['name'] ?? '').toString();
      username = displayName.isNotEmpty ? displayName : 'Username';
      fullName = displayName.isNotEmpty ? displayName : 'ชื่อ / นามสกุล';
      email = (data['email'] ?? email).toString();
      phone = (data['phone'] ?? phone).toString();
      role  = (data['role']  ?? role ).toString();

      // 🔧 อ่านทะเบียนรถให้ครอบคลุมทั้งสองชื่อฟิลด์ (รองรับข้อมูลเก่า/ใหม่)
      carLicense = (data['licensePlate'] ?? data['plate'] ?? carLicense).toString();

      _docUid = uid;
      setState(() => _loading = false);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.code == 'permission-denied'
          ? 'ไม่มีสิทธิ์เข้าถึงข้อมูล (permission-denied)\n'
            '• ตรวจว่าได้ล็อกอินด้วย FirebaseAuth แล้วหรือยัง\n'
            '• ตรวจว่า doc id ใน users ตรงกับ UID หรือไม่\n'
            '• ถ้าเพิ่งตั้ง role ให้ sign out / sign in ใหม่'
          : 'ดึงข้อมูลผู้ใช้ล้มเหลว: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ดึงข้อมูลผู้ใช้ล้มเหลว: $e')),
      );
    }
  }

  /// เปิด dialog ให้กรอกทะเบียน แล้วบันทึก (แยกปุ่มจาก UI หลัก)
  Future<void> _editPlateDialog() async {
    final uid = _docUid ?? _effectiveUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบผู้ใช้')),
      );
      return;
    }

    final controller = TextEditingController(text: carLicense == '—' ? '' : carLicense);
    final newPlate = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขทะเบียนรถ'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'เช่น กมค 1234 พะเยา หรือ 1234',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            child: const Text('ยกเลิก'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: const Text('บันทึก'),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          ),
        ],
      ),
    );

    if (newPlate == null) return; // กดยกเลิก

    try {
      // ทำ normalize ง่าย ๆ เผื่อคุณใช้ค้นหา (เอาเฉพาะเลขไทย/อารบิก)
      final normalized = RegExp(r'\d+').allMatches(newPlate).map((m) => m.group(0)!).join('');

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'licensePlate': newPlate,           // ✅ ใช้ชื่อนี้เป็นหลัก
        'plateNormalized': normalized,      // (ถ้ามีใช้ในระบบค้นหา)
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() => carLicense = newPlate);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกทะเบียนรถสำเร็จ')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'permission-denied'
          ? 'ไม่มีสิทธิ์แก้ไขทะเบียนรถ (permission-denied)\n'
            '• Rules ต้องอนุญาตให้เจ้าของแก้ไขฟิลด์ licensePlate/plateNormalized'
          : 'บันทึกไม่สำเร็จ: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } finally {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _goHome() {
    final uid = _effectiveUid;
    if (uid == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    Navigator.pushReplacementNamed(context, '/home', arguments: {'uid': uid});
  }

  void _goProfile() {
    final uid = _effectiveUid;
    if (uid == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    Navigator.pushReplacementNamed(context, '/profile', arguments: {'uid': uid});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'ออกจากระบบ',
          icon: const Icon(Icons.logout),
          onPressed: _signOut,
        ),
        title: const Row(
          children: [
            Icon(Icons.school, size: 24),
            SizedBox(width: 8),
            Text('University of Phayao'),
          ],
        ),
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
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 48),
                      ),
                      const SizedBox(height: 16),

                      // ชื่อ/บรรทัดรอง
                      Text(
                        username,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),

                      // badge role (ถ้ามี)
                      if (role.isNotEmpty && role != '—')
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('บทบาท: $role',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // รายการข้อมูล
                      ListTile(title: const Text('ชื่อเต็ม'), subtitle: Text(fullName)),
                      ListTile(title: const Text('อีเมล'), subtitle: Text(email)),
                      ListTile(title: const Text('รหัสผ่าน'), subtitle: Text(passwordMasked)),
                      ListTile(title: const Text('เบอร์โทรศัพท์'), subtitle: Text(phone)),

                      // แสดงทะเบียนรถ + ปุ่มแก้ไข (ไม่แก้ในที่เลย เพื่อลดความผิดพลาด)
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('ทะเบียนรถ',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(carLicense),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _editPlateDialog,
                            icon: const Icon(Icons.edit),
                            label: const Text('แก้ไขทะเบียนรถ'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 0) _goHome();
          if (index == 1) _goProfile();
        },
      ),
    );
  }
}
