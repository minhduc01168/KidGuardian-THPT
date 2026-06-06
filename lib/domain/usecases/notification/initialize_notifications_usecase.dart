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

    // Start listening to alerts via watchAllFamilyAlerts
    _alertRepository.watchAllFamilyAlerts(familyId: familyId);

    // Start listening to time requests via watchPendingRequests
    _timeRequestRepository.watchPendingRequests(familyId: familyId);
  }
}
