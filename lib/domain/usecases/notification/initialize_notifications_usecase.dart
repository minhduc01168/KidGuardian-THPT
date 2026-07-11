import '../../../domain/repositories/alert_repository.dart';
import '../../../domain/repositories/time_request_repository.dart';

class InitializeNotificationsUseCase {
  final AlertRepository _alertRepository;
  final TimeRequestRepository _timeRequestRepository;

  InitializeNotificationsUseCase(
    this._alertRepository,
    this._timeRequestRepository,
  );

  Future<void> execute({required String familyId}) async {
    if (familyId.isEmpty) {
      throw Exception('Family ID không hợp lệ');
    }

    // Start listening to alerts
    _alertRepository.getAlertsStream(familyId);

    // Start listening to time requests
    _timeRequestRepository.getRequestsStream(familyId);
  }
}
