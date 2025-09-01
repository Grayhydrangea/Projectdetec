// lib/report_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BalancePage extends StatefulWidget {
  final String? uid;
  const BalancePage({super.key, this.uid});

  @override
  State<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends State<BalancePage> {
  // --- เลือกวัน/เดือน/ปี ---
  String _selectedDay = '1';
  String _selectedMonth = 'มกราคม';
  String _selectedYear = '2568';

  // --- เลือกสถานที่ ---
  String _locSel = 'gate1'; // gate1 | gate2 | gate3

  // --- สถานะโหลด/แสดงผล ---
  int? _count;
  bool _loading = false;
  String _role = '';
  bool _loadingRole = true;

  // แผนที่เดือนไทย -> เลขเดือน (คริสต์ศักราชใช้ปีพ.ศ.-543)
  static const Map<String, int> _thaiMonthToNum = {
    'มกราคม': 1, 'กุมภาพันธ์': 2, 'มีนาคม': 3, 'เมษายน': 4,
    'พฤษภาคม': 5, 'มิถุนายน': 6, 'กรกฎาคม': 7, 'สิงหาคม': 8,
    'กันยายน': 9, 'ตุลาคม': 10, 'พฤศจิกายน': 11, 'ธันวาคม': 12,
  };

  String? get _effectiveUid {
    if (widget.uid != null && widget.uid!.isNotEmpty) return widget.uid!;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  bool get _isStaff =>
      _role == 'guard' || _role == 'security' || _role == 'admin';

  (DateTime start, DateTime end) _selectedRange() {
    final month = _thaiMonthToNum[_selectedMonth]!;
    final yearCE = (int.tryParse(_selectedYear) ?? 2568) - 543;
    final day = int.tryParse(_selectedDay) ?? 1;
    final start = DateTime(yearCE, month, day, 0, 0, 0);
    final end = start.add(const Duration(days: 1));
    return (start, end);
  }

  @override
  void initState() {
    super.initState();
    _initRoleFromClaims().then((_) {
      if (_isStaff) _loadReport();
    });
  }

  Future<void> _initRoleFromClaims() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final res = await user.getIdTokenResult(true); // force refresh claims
        _role = (res.claims?['role']?.toString() ?? '').toLowerCase().trim();
      } else {
        _role = '';
      }
    } catch (_) {
      _role = '';
    } finally {
      if (mounted) setState(() => _loadingRole = false);
    }
  }

  // คืนรายการค่าที่เท่ากับสถานที่ที่เลือก (รองรับ gate1_side สำหรับประตู2)
  List<String> _locationWhereIn(String v) {
    final key = v.toLowerCase().trim();
    if (key == 'gate2') return ['gate2', 'gate1_side'];
    if (key == 'gate1') return ['gate1'];
    if (key == 'gate3') return ['gate3'];
    return [key];
  }

  /// โหลดรายงาน "เฉพาะสถานะเข้า" (status == 'entry')
  Future<void> _loadReport() async {
    final uid = _effectiveUid;
    if (uid == null) return;

    final (start, end) = _selectedRange();
    setState(() {
      _loading = true;
      _count = null;
    });

    try {
      // สร้างคิวรีตามวัน + เฉพาะ entry
      Query<Map<String, dynamic>> q = FirebaseFirestore.instance
          .collection('attendance')
          .where('status', isEqualTo: 'entry')
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('time', isLessThan: Timestamp.fromDate(end));

      // กรองสถานที่ (ใช้ whereIn เพื่อครอบคลุม gate1_side กรณีเลือกประตู2)
      final locIn = _locationWhereIn(_locSel);
      if (locIn.length == 1) {
        q = q.where('locationId', isEqualTo: locIn.first);
      } else {
        q = q.where('locationId', whereIn: locIn);
      }

      final snap = await q.get();
      if (!mounted) return;
      setState(() => _count = snap.size);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'failed-precondition'
          ? 'คิวรีนี้ต้องสร้าง Composite Index ใน Firestore Console (คลิกลิงก์จาก error แรกได้)'
          : 'โหลดรายงานไม่สำเร็จ: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('โหลดรายงานไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _effectiveUid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Icon(Icons.bar_chart, size: 24),
            SizedBox(width: 8),
            Text('รายงานการเข้า - ออก'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชสิทธิ์',
            onPressed: () async {
              setState(() => _loadingRole = true);
              await _initRoleFromClaims();
              if (_isStaff) _loadReport();
            },
          ),
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
      body: _loadingRole
          ? const Center(child: CircularProgressIndicator())
          : !_isStaff
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.lock, color: Colors.red),
                      title: const Text('ไม่มีสิทธิ์เข้าถึง'),
                      subtitle:
                          const Text('รายงานนี้อนุญาตเฉพาะเจ้าหน้าที่ (ยาม/แอดมิน)'),
                    ),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ตัวกรองวันที่
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = (constraints.maxWidth - 16) / 3;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                SizedBox(
                                  width: w,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedDay,
                                    decoration: const InputDecoration(
                                      labelText: 'วัน',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: List.generate(31, (i) => (i + 1).toString())
                                        .map((v) => DropdownMenuItem(
                                              value: v,
                                              child: Text(v),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedDay = v!),
                                  ),
                                ),
                                SizedBox(
                                  width: w,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedMonth,
                                    decoration: const InputDecoration(
                                      labelText: 'เดือน',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: _thaiMonthToNum.keys
                                        .map((m) => DropdownMenuItem(
                                              value: m,
                                              child: Text(m),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedMonth = v!),
                                  ),
                                ),
                                SizedBox(
                                  width: w,
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    value: _selectedYear,
                                    decoration: const InputDecoration(
                                      labelText: 'ปี',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: ['2568', '2567', '2566', '2565']
                                        .map((y) => DropdownMenuItem(
                                              value: y,
                                              child: Text(y),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedYear = v!),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // ตัวกรองสถานที่
                        SizedBox(
                          width: 320,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _locSel,
                            decoration: const InputDecoration(
                              labelText: 'สถานที่',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'gate1', child: Text('ประตู1')),
                              DropdownMenuItem(value: 'gate2', child: Text('ประตู2')),
                              DropdownMenuItem(value: 'gate3', child: Text('ประตู3')),
                            ],
                            onChanged: (v) => setState(() => _locSel = v ?? 'gate1'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ปุ่มโหลดรายงานใหม่
                        SizedBox(
                          width: 220,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _loadReport,
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('โหลดรายงาน'),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // แสดงผล
                        Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 32, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (_count ?? 0).toString(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text('คัน', style: TextStyle(fontSize: 24)),
                                const SizedBox(height: 16),
                                Text('วันที่: $_selectedDay $_selectedMonth $_selectedYear'),
                                Text('สถานที่: ${_locSel.toLowerCase()}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.description), label: 'รายงาน'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'หน้าแรก'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'โปรไฟล์'),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        onTap: (i) {
          if (i == 1) {
            Navigator.pushNamed(context, '/home', arguments: {'uid': uid});
          } else if (i == 2) {
            Navigator.pushNamed(context, '/profile', arguments: {'uid': uid});
          }
        },
      ),
    );
  }
}
