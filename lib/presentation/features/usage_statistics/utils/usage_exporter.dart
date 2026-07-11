import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../../../domain/entities/usage_log.dart';

class UsageExporter {
  static Future<String> exportToCsv(
      List<UsageLog> logs, String dateRange) async {
    final List<List<dynamic>> rows = [
      ['Ngày', 'Ứng dụng', 'Thời gian bắt đầu', 'Thời gian kết thúc', 'Thời lượng (phút)'],
    ];

    for (final log in logs) {
      rows.add([
        log.date,
        log.appName,
        DateFormat('HH:mm').format(log.startTime),
        DateFormat('HH:mm').format(log.endTime),
        log.durationMinutes,
      ]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final fileName =
        'usage_stats_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Thống kê sử dụng - $dateRange',
    );

    return file.path;
  }

  static Future<String> exportToPdf(
      List<UsageLog> logs, String dateRange) async {
    final pdf = pw.Document();

    final Map<String, int> appTotals = {};
    for (final log in logs) {
      appTotals[log.appName] =
          (appTotals[log.appName] ?? 0) + log.durationMinutes;
    }

    final sortedApps = appTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Thống Kê Sử Dụng',
                style: pw.TextStyle(fontSize: 24)),
          ),
          pw.Text('Khoảng thời gian: $dateRange'),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Tổng hợp theo ứng dụng')),
          pw.TableHelper.fromTextArray(
            headers: ['Ứng dụng', 'Thời lượng (phút)', 'Tỷ lệ'],
            data: sortedApps.map((entry) {
              final total = appTotals.values.fold<int>(0, (s, v) => s + v);
              final percentage = total > 0
                  ? (entry.value / total * 100).toStringAsFixed(1)
                  : '0';
              return [entry.key, entry.value.toString(), '$percentage%'];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Chi tiết sử dụng')),
          pw.TableHelper.fromTextArray(
            headers: ['Ngày', 'Ứng dụng', 'Bắt đầu', 'Kết thúc', 'Phút'],
            data: logs
                .map((log) => [
                      log.date,
                      log.appName,
                      DateFormat('HH:mm').format(log.startTime),
                      DateFormat('HH:mm').format(log.endTime),
                      log.durationMinutes.toString(),
                    ])
                .toList(),
          ),
        ],
      ),
    );

    final directory = await getTemporaryDirectory();
    final fileName =
        'usage_stats_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Thống kê sử dụng - $dateRange',
    );

    return file.path;
  }
}
