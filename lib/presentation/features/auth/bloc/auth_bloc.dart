import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/services/notification_service.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../../../../domain/repositories/family_repository.dart';
import '../../../../domain/entities/user.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final FamilyRepository _familyRepository;
  final NotificationService _notificationService;
  StreamSubscription? _authSubscription;
  

  AuthBloc({
    required AuthRepository authRepository,
    required FamilyRepository familyRepository,
    required NotificationService notificationService,
  })  : _authRepository = authRepository,
        _familyRepository = familyRepository,
        _notificationService = notificationService,
        super(AuthInitial()) {
    
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<LinkChildToFamily>(_onLinkChildToFamily);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    
    // Listen to auth state changes
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      add(AuthStateChanged(user: user));
    });
  }
  
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      print('Attempting login for: ${event.email}');
      var user = await _authRepository.login(event.email, event.password);
      print('Login successful for user: ${user.uid}');
      
      // Auto-create family for parent on first login
      if (user.role == UserRole.parent && user.familyId == null) {
        print('Parent has no family, auto-creating...');
        final family = await _familyRepository.createFamily(user.uid);
        print('Family created: ${family.familyId}, linking code: ${family.linkingCode}');
        // Re-fetch user to get updated familyId
        final updatedUser = await _authRepository.getCurrentUser();
        if (updatedUser != null) {
          user = updatedUser;
        }
      }
      
      // Register notification token (non-blocking)
      _notificationService.registerToken(user.uid).catchError((e) {
        print('Failed to register notification token: $e');
      });
      
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Login error: $errorMessage');
      emit(AuthError(message: errorMessage));
    }
  }
  
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      print('Attempting registration for: ${event.email}');
      final user = await _authRepository.register(
        event.email,
        event.password,
        event.name,
        event.role,
      );
      print('Registration successful for user: ${user.uid}');
      
      // Auto-create family for parent immediately after registration
      if (user.role == UserRole.parent && user.familyId == null) {
        print('Parent registered, auto-creating family...');
        await _familyRepository.createFamily(user.uid);
      }
      
      // Không gọi logout nữa, để Firebase tự động login.
      // Luồng điều hướng sẽ được xử lý qua _onAuthStateChanged.
      // Không cần emit AuthRegistrationSuccess nữa vì AuthStateChanged sẽ emit AuthAuthenticated.
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      print('Registration error: $errorMessage');
      emit(AuthError(message: errorMessage));
    }
  }
  
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }
  
  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(event.email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
  
  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    
    if (event.user != null) {
      _notificationService.registerToken(event.user!.uid);
      emit(AuthAuthenticated(user: event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }
  
  Future<void> _onLinkChildToFamily(
    LinkChildToFamily event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Resolve linking code to familyId
      final family = await _familyRepository.getFamilyByLinkingCode(event.linkingCode);
      if (family == null) {
        emit(AuthError(message: 'Mã liên kết không hợp lệ'));
        return;
      }
      
      await _authRepository.linkChildToFamily(event.childUid, family.familyId);
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Không thể liên kết tài khoản'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
  
  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.updateProfile(event.uid, displayName: event.displayName);
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Không thể cập nhật thông tin'));
      }
    } catch (e) {
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
    }
  }
  
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
