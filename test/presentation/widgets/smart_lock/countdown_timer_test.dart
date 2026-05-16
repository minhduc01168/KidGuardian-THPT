import 'package:flutter_test/flutter_test.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/countdown_timer.dart';

void main() {
  group('CountdownTimer helpers', () {
    test('formatRemaining returns correct Vietnamese format for hours minutes seconds', () {
      final remaining = const Duration(hours: 2, minutes: 30, seconds: 45);
      final result = CountdownTimer.formatRemaining(remaining);
      expect(result, 'Còn lại: 2 giờ 30 phút 45 giây');
    });

    test('formatRemaining handles zero duration', () {
      final remaining = Duration.zero;
      final result = CountdownTimer.formatRemaining(remaining);
      expect(result, 'Còn lại: 0 giờ 0 phút 0 giây');
    });

    test('formatRemaining handles only seconds', () {
      final remaining = const Duration(seconds: 5);
      final result = CountdownTimer.formatRemaining(remaining);
      expect(result, 'Còn lại: 0 giờ 0 phút 5 giây');
    });

    test('formatRemaining handles only minutes', () {
      final remaining = const Duration(minutes: 15);
      final result = CountdownTimer.formatRemaining(remaining);
      expect(result, 'Còn lại: 0 giờ 15 phút 0 giây');
    });

    test('formatRemaining handles large hours', () {
      final remaining = const Duration(hours: 23, minutes: 59, seconds: 59);
      final result = CountdownTimer.formatRemaining(remaining);
      expect(result, 'Còn lại: 23 giờ 59 phút 59 giây');
    });

    test('calculateRemaining returns duration until next midnight', () {
      final now = DateTime(2026, 5, 16, 14, 30, 0);
      final remaining = CountdownTimer.calculateRemaining(now);
      expect(remaining, const Duration(hours: 9, minutes: 30));
    });

    test('calculateRemaining returns zero when now equals resetTime', () {
      final now = DateTime(2026, 5, 17, 0, 0, 0);
      final resetTime = DateTime(2026, 5, 17, 0, 0, 0);
      final remaining = CountdownTimer.calculateRemaining(now, resetTime: resetTime);
      expect(remaining, Duration.zero);
    });

    test('calculateRemaining returns 24h at midnight without custom resetTime', () {
      final now = DateTime(2026, 5, 17, 0, 0, 0);
      final remaining = CountdownTimer.calculateRemaining(now);
      expect(remaining, const Duration(hours: 24));
    });

    test('calculateRemaining with custom resetTime', () {
      final now = DateTime(2026, 5, 16, 14, 30, 0);
      final resetTime = DateTime(2026, 5, 17, 0, 0, 0);
      final remaining = CountdownTimer.calculateRemaining(now, resetTime: resetTime);
      expect(remaining, const Duration(hours: 9, minutes: 30));
    });
  });
}
