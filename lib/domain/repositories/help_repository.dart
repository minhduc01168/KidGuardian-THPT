import '../entities/faq_item.dart';

abstract class HelpRepository {
  List<FaqItem> getFaqItems();
  Future<void> sendSupportMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  });
}
