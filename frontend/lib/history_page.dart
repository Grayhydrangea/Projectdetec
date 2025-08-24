// lib/history_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ParkingListPage extends StatefulWidget {
  final String? uid; // ถ้าไม่ส่งมา จะ fallback ไป currentUser
  const ParkingListPage({super.key, this.uid});

  @override
  State<ParkingListPage> createState() => _ParkingListPageState();
}

class _ParkingListPageState extends State<ParkingListPage> {
  // ===== วันที่ / โหมด =====
  String _selectedDay = '1';
  String _selectedMonthTh = 'มกราคม';
  String _selectedYearBuddhist = '2568';
  bool _filterByMonth = false;

  // สวิตช์ staff: เปิดดูทั้งหมด (ไม่กรองเวลา)
  bool _noTimeFilterForStaff = false;

  // ===== bottom nav =====
  int _selectedIndex = 0;

  // ===== role & search =====
  String _role = ''; // student | guard | security | admin
  bool _loadingRole = true;

  final TextEditingController _plateSearchCtl = TextEditingController();
  String _plateQuery = ''; // lowercase

  // ===== helpers =====
  static const List<String> _thaiMonths = [
    'มกราคม','กุมภาพันธ์','มีนาคม','เมษายน','พฤษภาคม','มิถุนายน',
    'กรกฎาคม','สิงหาคม','กันยายน','ตุลาคม','พฤศจิกายน','ธันวาคม',
  ];
  static const Map<String, int> _thaiMonthToNum = {
    'มกราคม':1,'กุมภาพันธ์':2,'มีนาคม':3,'เมษายน':4,'พฤษภาคม':5,'มิถุนายน':6,
    'กรกฎาคม':7,'สิงหาคม':8,'กันยายน':9,'ตุลาคม':10,'พฤศจิกายน':11,'ธันวาคม':12,
  };
  final List<String> _yearOptionsBuddhist = ['2568','2567','2566','2565'];

  String? get _effectiveUid {
    if (widget.uid != null && widget.uid!.isNotEmpty) return widget.uid!;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  bool get _isStaff =>
      _role == 'guard' || _role == 'security' || _role == 'admin';

  @override
  void initState() {
    super.initState();
    _initRoleFromClaims();
    _plateSearchCtl.addListener(() {
      setState(() => _plateQuery = _plateSearchCtl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _plateSearchCtl.dispose();
    super.dispose();
  }

  /// ดึง role จาก Custom Claims บน IdToken
  Future<void> _initRoleFromClaims() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final res = await user.getIdTokenResult(true); // force refresh
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

  void _goHome() {
    final uid = _effectiveUid;
    Navigator.pushReplacementNamed(context, '/home', arguments: {'uid': uid});
  }

  void _goProfile() {
    final uid = _effectiveUid;
    Navigator.pushReplacementNamed(context, '/profile', arguments: {'uid': uid});
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _goHome();
    if (index == 1) _goProfile();
  }

  (DateTime start, DateTime end) _selectedRange() {
    final month = _thaiMonthToNum[_selectedMonthTh]!;
    final yearCE = (int.tryParse(_selectedYearBuddhist) ?? 2568) - 543;

    if (_filterByMonth) {
      final start = DateTime(yearCE, month, 1, 0, 0, 0);
      final end = DateTime(yearCE, month + 1, 1, 0, 0, 0);
      return (start, end);
    } else {
      final day = int.tryParse(_selectedDay) ?? 1;
      final start = DateTime(yearCE, month, day, 0, 0, 0);
      final end = start.add(const Duration(days: 1));
      return (start, end);
    }
  }

  /// คิวรีจาก attendance โดย "ล็อก locationId = gate1" เสมอ
  Query<Map<String, dynamic>>? _buildQuery() {
    final uid = _effectiveUid;
    if (uid == null) return null;

    final col = FirebaseFirestore.instance.collection('attendance');

    if (!_isStaff) {
      // student: ต้องกรอง uid ของตัวเอง + เวลา + gate1
      final (start, end) = _selectedRange();
      return col
          .where('locationId', isEqualTo: 'gate1')
          .where('uid', isEqualTo: uid)
          .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('time', isLessThan: Timestamp.fromDate(end))
          .orderBy('time', descending: true);
    }

    // staff: ถ้า “ดูทั้งหมด” -> ไม่กรองเวลา แต่ยังล็อก gate1
    if (_noTimeFilterForStaff) {
      return col
          .where('locationId', isEqualTo: 'gate1')
          .orderBy('time', descending: true)
          .limit(200);
    }

    final (start, end) = _selectedRange();
    return col
        .where('locationId', isEqualTo: 'gate1')
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('time', isLessThan: Timestamp.fromDate(end))
        .orderBy('time', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    final q = _buildQuery();

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.school),
        title: const Text('University of Phayao'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชสิทธิ์',
            onPressed: () async {
              setState(() => _loadingRole = true);
              await _initRoleFromClaims();
              setState(() {}); // re-query
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _initRoleFromClaims();
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (!_loadingRole && _role.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('role: $_role • สถานที่: gate1',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),

            _buildDateFilters(),

            if (!_loadingRole && _isStaff) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ดูทั้งหมด (ไม่กรองเวลา)'),
                  Switch(
                    value: _noTimeFilterForStaff,
                    onChanged: (v) => setState(() => _noTimeFilterForStaff = v),
                  ),
                ],
              ),
              _buildPlateSearch(),
            ],

            if (_loadingRole)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (q == null)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.error, color: Colors.red),
                  title: Text('ไม่พบผู้ใช้'),
                  subtitle: Text('กรุณาเข้าสู่ระบบอีกครั้ง'),
                ),
              )
            else
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: q.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    final err = snapshot.error.toString();
                    final isPerm = err.contains('permission-denied');
                    final isIndex = err.contains('FAILED_PRECONDITION') || err.contains('requires an index');
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.error, color: Colors.red),
                        title: const Text('ข้อผิดพลาด'),
                        subtitle: Text(
                          isPerm
                              ? 'คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้'
                              : isIndex
                                  ? 'คิวรีนี้ต้องสร้าง Composite Index ใน Firestore Console'
                                  : err,
                        ),
                      ),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = _isStaff && _plateQuery.isNotEmpty
                      ? allDocs.where((d) {
                          final m = d.data();
                          final p = (m['plateNormalized'] ?? m['licensePlate'] ?? '')
                              .toString()
                              .toLowerCase();
                          return p.contains(_plateQuery);
                        }).toList()
                      : allDocs;

                  if (docs.isEmpty) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: Text(_filterByMonth
                            ? 'ไม่มีบันทึกในเดือนที่เลือก'
                            : 'ไม่มีบันทึกในวันที่เลือก'),
                        subtitle: const Text('ลองเปลี่ยนวัน/เดือน/ปี แล้วลองใหม่'),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((d) {
                      final m = d.data();
                      final plate = (m['licensePlate'] ?? m['plateNormalized'] ?? '').toString();
                      final loc = (m['locationId'] ?? m['location'] ?? '').toString();
                      final typeRaw = (m['status'] ?? m['type'] ?? '').toString();
                      final ts = m['time'];
                      final time = (ts is Timestamp) ? ts.toDate() : null;

                      final typeTh = (typeRaw.toLowerCase() == 'in' || typeRaw == 'เข้า')
                          ? 'เข้า'
                          : (typeRaw.toLowerCase() == 'out' || typeRaw == 'ออก')
                              ? 'ออก'
                              : typeRaw;

                      final dayLabel = time != null
                          ? '${_two(time.day)} $_selectedMonthTh $_selectedYearBuddhist'
                          : '$_selectedDay $_selectedMonthTh $_selectedYearBuddhist';

                      final timeText = (time != null)
                          ? '${_two(time.hour)}:${_two(time.minute)} น.'
                          : '-';

                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.two_wheeler, color: Colors.amber),
                          title: Text(loc.isNotEmpty ? loc : 'ไม่ระบุสถานที่'),
                          subtitle: Text(
                            'เลขทะเบียน: ${plate.isNotEmpty ? plate : '-'}\n'
                            'วัน: $dayLabel\n'
                            'เวลา: $timeText\n'
                            'สถานะ: $typeTh',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
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
        onTap: _onItemTapped,
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: _filterByMonth ? null : (v) => setState(() => _selectedDay = v!),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedMonthTh,
                    decoration: const InputDecoration(
                      labelText: 'เดือน',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _thaiMonths
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedMonthTh = v!),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedYearBuddhist,
                    decoration: const InputDecoration(
                      labelText: 'ปี',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _yearOptionsBuddhist
                        .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedYearBuddhist = v!),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Icon(Icons.filter_alt_outlined, size: 20),
            const Text('โหมดการกรอง'),
            ChoiceChip(
              label: const Text('รายวัน'),
              selected: !_filterByMonth,
              onSelected: (s) => setState(() => _filterByMonth = false),
            ),
            ChoiceChip(
              label: const Text('รายเดือน'),
              selected: _filterByMonth,
              onSelected: (s) => setState(() => _filterByMonth = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPlateSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('ค้นหาเลขทะเบียน', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _plateSearchCtl,
          decoration: const InputDecoration(
            hintText: 'พิมพ์เลขทะเบียน (เช่น 9729)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
