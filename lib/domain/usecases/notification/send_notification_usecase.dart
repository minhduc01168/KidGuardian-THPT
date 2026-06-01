import '../../../domain/repositories/alert_repository.dart';

class SendNotificationUseCase {
  final AlertRepository _repository;

  SendNotificationUseCase(this._repository);

  Future<void> execute({
    required String familyId,
    required String title,
    required String body,
    String? type,
  }) async {
    if (familyId.isEmpty) {
      throw Exception('Family ID không hợp lệ');
    }
    if (title.isEmpty) {
      throw Exception('Tiêu đề không được để trống');
    }
    if (body.isEmpty) {
      throw Exception('Nội dung không được để trống');
    }

    // The actual notification sending is handled by the notification service
    // This use case validates and prepares the notification data
  }
}
