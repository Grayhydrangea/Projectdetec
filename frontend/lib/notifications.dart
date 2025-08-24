// lib/notifications_page.dart
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key}); // ✅
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('การแจ้งเตือน'),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.two_wheeler)),
            title: Text('การจอดรถสำเร็จ 3'),
            subtitle: Text('วันที่ดีมากๆ !'),
            trailing: Text('วัน 11:30'),
          ),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.two_wheeler)),
            title: Text('การจอดรถสำเร็จ'),
            subtitle: Text('Nice Try !'),
            trailing: Text('พ. 17:30'),
          ),
          // Add more notifications; fetch from API or local storage in real app
        ],
      ),
    );
  }
}