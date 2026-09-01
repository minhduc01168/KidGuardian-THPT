import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kidguardian/data/repositories/help_repository_impl.dart';
import 'package:kidguardian/domain/entities/faq_item.dart';

void main() {
  late HelpRepositoryImpl repository;

  setUp(() {
    repository = HelpRepositoryImpl();
  });

  group('HelpRepositoryImpl', () {
    group('getFaqItems', () {
      test('should return a non-empty list of FAQ items', () {
        final items = repository.getFaqItems();

        expect(items, isNotEmpty);
      });

      test('should return FAQ items with valid data', () {
        final items = repository.getFaqItems();

        for (final item in items) {
          expect(item.question, isNotEmpty);
          expect(item.answer, isNotEmpty);
          expect(item.category, isNotEmpty);
        }
      });

      test('should return FAQ items with expected categories', () {
        final items = repository.getFaqItems();

        final categories = items.map((e) => e.category).toSet();
        expect(categories, contains('Tổng quan'));
        expect(categories, contains('Sử dụng'));
        expect(categories, contains('Yêu cầu'));
        expect(categories, contains('Báo cáo'));
        expect(categories, contains('Kỹ thuật'));
      });

      test('should return 9 FAQ items', () {
        final items = repository.getFaqItems();

        expect(items.length, 9);
      });

      test('should return FaqItem instances', () {
        final items = repository.getFaqItems();

        expect(items.every((item) => item is FaqItem), isTrue);
      });

      test('first FAQ item should be about Kura', () {
        final items = repository.getFaqItems();

        expect(items.first.question, contains('Kura'));
      });
    });
  });
}
