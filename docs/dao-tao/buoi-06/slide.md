---
marp: true
theme: default
paginate: true
header: 'KidGuardian - Đồng Hành Số'
footer: 'BUỔI 6: Dashboard & Biểu Đồ (Data Visualization)'
style: |
  section {
    background-color: #f8f9fa;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    padding: 40px 50px;
  }
  h1 {
    color: #2c3e50;
    font-size: 2.2em;
    text-align: center;
  }
  h2 {
    color: #34495e;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
    margin-bottom: 20px;
  }
  h3 {
    color: #2980b9;
  }
  .center {
    text-align: center;
  }
  code {
    background-color: #e8eaed;
    border-radius: 4px;
    padding: 2px 4px;
    color: #c0392b;
  }
  pre code {
    color: #333;
    background-color: transparent;
  }
  pre {
    background-color: #f1f3f5;
    border-left: 4px solid #3498db;
  }
---

<!-- _class: lead -->
# 🚀 BUỔI 6: Dashboard & Biểu Đồ (Data Visualization)

**Thời gian:** 2 tiết (90 phút)  
**Mục tiêu:** Sử dụng fl_chart để hiển thị biểu đồ

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học


---
<!-- _class: lead -->
# 📚 PHẦN 1: LÝ THUYẾT (30 phút)

---
## Tại Sao Cần Biểu Đồ?

**Dữ liệu thô:**
```
TikTok: 90 phút
Facebook: 45 phút
YouTube: 30 phút
Instagram: 15 phút
```

**Biểu đồ:**
```
[Dễ nhìn hơn rất nhiều!]
```
---
## Các Loại Biểu Đồ Phổ Biện

| Loại | Mục Đích | Ví Dụ |
|------|----------|-------|
| Pie Chart | Tỷ lệ phần trăm | % sử dụng mỗi app |
| Bar Chart | So sánh | So sánh thời gian theo ngày |
| Line Chart | Xu hướng | Thời gian sử dụng theo tuần |
---
## fl_chart Package

**fl_chart** = Thư viện vẽ biểu đồ trong Flutter

**Hỗ trợ:**
- Pie Chart
- Bar Chart
- Line Chart
- Scatter Chart

---

---
<!-- _class: lead -->
# 📚 PHẦN 2: THỰC HÀNH (60 phút)

---
## Cài Đặt fl_chart

**Thêm vào `pubspec.yaml`:**

```yaml
dependencies:
  fl_chart: ^0.66.0
```

**Chạy:**
```bash
flutter pub get
```
---
## Tạo Data Model

**Tạo file `lib/models/usage_data.dart`:**

```dart
import 'package:flutter/material.dart';

class UsageData {
  final String appName;
  final int minutes;
  final Color color;
  
  UsageData({
    required this.appName,
    required this.minutes,
    required this.color,
  });
}

// Dữ liệu mẫu
List<UsageData> sampleData = [
  UsageData(appName: 'TikTok', minutes: 90, color: Colors.red),
  UsageData(appName: 'Facebook', minutes: 45, color: Colors.blue),
  UsageData(appName: 'YouTube', minutes: 30, color: Colors.purple),
  UsageData(appName: 'Instagram', minutes: 15, color: Colors.pink),
];
```
---
## Tạo Pie Chart Widget

**Tạo file `lib/widgets/usage_pie_chart.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/usage_data.dart';

class UsagePieChart extends StatelessWidget {
  final List<UsageData> data;
  
  UsagePieChart({required this.data});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Thời gian sử dụng theo app',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        
        // Biểu đồ tròn
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: data.map((item) {
                return PieChartSectionData(
                  value: item.minutes.toDouble(),
                  title: '${item.minutes}p',
                  color: item.color,
                  radius: 80,
                  titleStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Chú thích
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: data.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: item.color,
                ),
                SizedBox(width: 8),
                Text(item.appName),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
```
---
## Tạo Bar Chart Widget

**Tạo file `lib/widgets/usage_bar_chart.dart`:**

```dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UsageBarChart extends StatelessWidget {
  final List<UsageData> data;
  
  UsageBarChart({required this.data});
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Thời gian sử dụng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: data.map((e) => e.minutes).reduce((a, b) => a > b ? a : b).toDouble() + 30,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index < data.length) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            data[index].appName,
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      }
                      return Text('');
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}p');
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.minutes.toDouble(),
                      color: entry.value.color,
                      width: 30,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
```
---
## Tạo Dashboard Screen

**Cập nhật `lib/screens/parent_dashboard_screen.dart`:**

```dart
import 'package:flutter/material.dart';
import '../models/usage_data.dart';
import '../widgets/usage_pie_chart.dart';
import '../widgets/usage_bar_chart.dart';

class ParentDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tổng quan
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          'Tổng thời gian',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '3h 00p',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'Giới hạn',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          '2h 00p',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Biểu đồ tròn
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: UsagePieChart(data: sampleData),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Biểu đồ cột
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: UsageBarChart(data: sampleData),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Danh sách chi tiết
            Text(
              'Chi tiết sử dụng',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            
            ...sampleData.map((item) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.color,
                  child: Icon(Icons.apps, color: Colors.white),
                ),
                title: Text(item.appName),
                trailing: Text(
                  '${item.minutes} phút',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
```

---

---
<!-- _class: lead -->
# 📚 PHẦN 3: BÀI TẬP VỀ NHÀ

---
## Bài Tập 1: Thêm Line Chart

**Yêu cầu:**
- Tạo biểu đồ đường (Line Chart)
- Hiển thị xu hướng sử dụng trong 7 ngày
---
## Bài Tập 2: Đọc Data Từ Firestore

**Yêu cầu:**
- Thay vì dùng `sampleData`, đọc dữ liệu thật từ Firestore
- Tính tổng thời gian sử dụng trong ngày
---
## Bài Tập 3: Tìm Hiểu

**Câu hỏi:**
1. Pie Chart phù hợp để hiển thị dữ liệu gì?
2. Bar Chart phù hợp để hiển thị dữ liệu gì?
3. Cách tính phần trăm từ dữ liệu?

---
---
## TÀI LIỆU THAM KHẢO

- fl_chart: https://pub.dev/packages/fl_chart
- fl_chart examples: https://github.com/imaNNeoFighT/fl_chart

---
---
## CÂU HỎI ÔN TẬP

1. fl_chart hỗ trợ những loại biểu đồ nào?
2. PieChartSectionData chứa những thông tin gì?
3. Cách hiển thị chú thích cho biểu đồ?

---

**Buổi Tiếp Theo:** [Buổi 7 - Logic Khóa giờ](../buoi-07/README.md)

---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
