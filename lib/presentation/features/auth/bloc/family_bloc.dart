import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/family_repository.dart';
import 'family_event.dart';
import 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository _familyRepository;
  final AuthRepository _authRepository;

  FamilyBloc({
    required FamilyRepository familyRepository,
    required AuthRepository authRepository,
  })  : _familyRepository = familyRepository,
        _authRepository = authRepository,
        super(FamilyInitial()) {
    on<CreateFamilyRequested>(_onCreateFamilyRequested);
    on<LoadFamilyRequested>(_onLoadFamilyRequested);
    on<GenerateLinkingCodeRequested>(_onGenerateLinkingCodeRequested);
    on<CreateChildAccountRequested>(_onCreateChildAccountRequested);
    on<LinkChildToFamilyRequested>(_onLinkChildToFamilyRequested);
  }

  Future<void> _onCreateFamilyRequested(
    CreateFamilyRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());
    try {
      final family = await _familyRepository.createFamily(event.parentUid);
      emit(FamilyCreated(family: family));
    } catch (e) {
      emit(FamilyError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLoadFamilyRequested(
    LoadFamilyRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());
    try {
      final family = await _familyRepository.getFamilyByParent(event.parentUid);
      if (family != null) {
        emit(FamilyLoaded(family: family));
      } else {
        emit(const FamilyError(message: 'Chưa tạo gia đình'));
      }
    } catch (e) {
      emit(FamilyError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGenerateLinkingCodeRequested(
    GenerateLinkingCodeRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());
    try {
      final code = await _familyRepository.generateLinkingCode(event.familyId);
      emit(LinkingCodeGenerated(linkingCode: code));
    } catch (e) {
      emit(FamilyError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateChildAccountRequested(
    CreateChildAccountRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());
    try {
      final child = await _authRepository.createChildAccount(
        event.name,
        event.age,
        event.familyId,
      );

      await _familyRepository.addChildToFamily(event.familyId, child.uid);

      final family = await _familyRepository.getFamily(event.familyId);
      final linkingCode = family?.linkingCode ?? '';

      emit(ChildAccountCreated(child: child, linkingCode: linkingCode));
    } catch (e) {
      emit(FamilyError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLinkChildToFamilyRequested(
    LinkChildToFamilyRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());
    try {
      // Check if child already has a family
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null && currentUser.familyId != null) {
        emit(const FamilyError(message: 'Tài khoản đã được liên kết với gia đình khác'));
        return;
      }

      final family = await _familyRepository.getFamilyByLinkingCode(
        event.linkingCode,
      );

      if (family == null) {
        emit(const FamilyError(message: 'Mã liên kết không hợp lệ'));
        return;
      }

      await _familyRepository.addChildToFamily(family.familyId, event.childUid);
      await _authRepository.linkChildToFamily(event.childUid, family.familyId);

      final updatedFamily = await _familyRepository.getFamily(family.familyId);
      if (updatedFamily != null) {
        emit(ChildLinkedToFamily(family: updatedFamily));
      } else {
        emit(const FamilyError(message: 'Không thể liên kết tài khoản'));
      }
    } catch (e) {
      emit(FamilyError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
}
