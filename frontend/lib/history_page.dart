import 'package:flutter/material.dart';
 
class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar
      appBar: AppBar(
        title: Text("บันทึกการเข้า - ออก ของนิสิต"),
        backgroundColor: Colors.purple,
      ),
 
      // เนื้อหาหลัก
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
 
            // Card: รายการที่ 1 (เข้า)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เลขทะเบียน: กมค 9999 พะเยา'),
                    SizedBox(height: 8.0),
                    Text('วันที่: 3 มีนาคม'),
                    SizedBox(height: 8.0),
                    Text('เวลา: 10.00 น.'),
                    SizedBox(height: 8.0),
                    Text('สถานะ: เข้า'),
                  ],
                ),
              ),
            ),
 
            SizedBox(height: 16.0),
 
            // Card: รายการที่ 2 (ออก)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('เลขทะเบียน: กมค 9999 พะเยา'),
                    SizedBox(height: 8.0),
                    Text('วันที่: 3 มีนาคม'),
                    SizedBox(height: 8.0),
                    Text('เวลา: 15.00 น.'),
                    SizedBox(height: 8.0),
                    Text('สถานะ: ออก'),
                  ],
                ),
              ),
            ),
 
            // เพิ่ม Card อื่น ๆ ได้ที่นี่ตามต้องการ
          ],
        ),
      ),
    );
  }
}
 
 