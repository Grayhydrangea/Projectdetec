import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key}); // ✅ const constructor

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ตัวแปรสำหรับจัดการสถานะการแจ้งเตือน
  String _notificationSetting = 'เปิด'; // ค่าเริ่มต้น
  static const List<String> _options = ['เปิด', 'ปิด'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('การตั้งค่า'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // เปลี่ยนจาก "เปิดปิดการแจ้งเตือน" เป็น "การตั้งค่าการแจ้งเตือน"
          ListTile(
            title: const Text('การตั้งค่าการแจ้งเตือน'),
            trailing: DropdownButton<String>(
              value: _notificationSetting,
              items: _options
                  .map(
                    (v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _notificationSetting = value);
                // TODO: เพิ่มลอจิกเปิด/ปิดการแจ้งเตือนจริงที่นี่ (เช่น SharedPreferences / Firebase Messaging)
              },
            ),
          ),
        ],
      ),
    );
  }
}
