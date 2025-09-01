// lib/notifications_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // ย่อชื่อวัน/เดือนแบบไทยเล็ก ๆ เพื่อไม่ต้องพึ่งแพ็กเกจเพิ่ม
  static const _thaiWeekdaysShort = ['อา.', 'จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.'];
  static const _thaiMonthsShort = [
    'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
    'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
  ];

  String _formatTrailing(DateTime dt) {
    // ถ้าวันเดียวกัน แสดง "วัน 11:30", ไม่งั้น "พ. 17:30" หรือ "23 ส.ค. 10:40"
    final now = DateTime.now();
    final sameDay = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (sameDay) {
      // ตัวอย่างต้นฉบับมี "วัน 11:30" → ใช้ "วันนี้ 11:30" ให้ใกล้เคียง
      return 'วันนี้ $hh:$mm';
    }
    // ถ้าอาทิตย์เดียวกัน แสดงย่อวัน
    final weekday = _thaiWeekdaysShort[dt.weekday % 7]; // DateTime: 1=Mon..7=Sun
    // เลือกใช้รูปแบบ "พ. 17:30"
    return '$weekday $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('การแจ้งเตือน'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('toUid', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final err = snapshot.error.toString();
                  final isIndex = err.contains('FAILED_PRECONDITION') || err.contains('requires an index');
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      isIndex
                          ? 'คิวรีนี้ต้องสร้าง Composite Index ใน Firestore Console ก่อน'
                          : 'เกิดข้อผิดพลาดในการโหลดการแจ้งเตือน: $err',
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('ยังไม่มีการแจ้งเตือน'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final title = (m['title'] ?? '').toString();
                    final body = (m['body'] ?? '').toString();

                    final ts = m['createdAt'];
                    DateTime? createdAt;
                    if (ts is Timestamp) createdAt = ts.toDate();
                    if (ts is DateTime) createdAt = ts;

                    final trailing = createdAt != null
                        ? _formatTrailing(createdAt)
                        : '';

                    // NOTE: คง UI เดิม (ListTile, CircleAvatar, trailing ข้อความ)
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.two_wheeler)),
                      title: Text(title.isNotEmpty ? title : 'การแจ้งเตือน'),
                      subtitle: Text(body.isNotEmpty ? body : '-'),
                      trailing: Text(trailing),
                      onTap: () {
                        // ถ้าต้องการ mark read:
                        // final id = docs[i].id;
                        // FirebaseFirestore.instance
                        //   .collection('notifications')
                        //   .doc(id)
                        //   .update({'read': true});
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
