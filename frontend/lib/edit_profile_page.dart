// lib/edit_profile_page.dart
import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key}); // ✅
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('แก้ไขโปรไฟล์'),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(radius: 50, backgroundColor: Colors.grey[300], child: Icon(Icons.landscape)), // Placeholder
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'ชื่อเต็ม'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'อีเมล'),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'รหัสผ่าน'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'ทะเบียนรถ'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Add save profile logic here (e.g., update API)
                Navigator.pop(context);
              },
              child: Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }
}