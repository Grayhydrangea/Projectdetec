import 'package:flutter/material.dart';
 
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text('การตั้งค่า'),
        backgroundColor: Colors.purple,
      ),
 
      // เนื้อหา
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // ปุ่มแก้ไขบัญชีส่วนตัว
            ElevatedButton(
              onPressed: () {
                // TODO: ฟังก์ชันการแก้ไขบัญชีผู้ใช้
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.white),
                  SizedBox(width: 16),
                  Text(
                    'แก้ไขบัญชีส่วนตัว',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
 
            SizedBox(height: 16),
 
            // ปุ่มตั้งค่าการแจ้งเตือน พร้อม Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'ตั้งค่าการแจ้งเตือน',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  DropdownButton<String>(
                    value: 'เปิด',
                    dropdownColor: Colors.white,
                    iconEnabledColor: Colors.white,
                    underline: SizedBox(), // เอาเส้นใต้ของ Dropdown ออก
                    items: <String>['เปิด', 'ปิด']
                        .map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      // TODO: ทำการเปลี่ยนแปลงสถานะที่เลือก
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
 