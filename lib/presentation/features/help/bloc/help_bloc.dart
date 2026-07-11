import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../domain/repositories/help_repository.dart';
import 'help_event.dart';
import 'help_state.dart';

class HelpBloc extends Bloc<HelpEvent, HelpState> {
  final HelpRepository _helpRepository;

  HelpBloc({required HelpRepository helpRepository})
      : _helpRepository = helpRepository,
        super(HelpInitial()) {
    on<LoadFaq>(_onLoadFaq);
    on<SendSupportMessage>(_onSendSupportMessage);
    on<LoadAppInfo>(_onLoadAppInfo);
    on<ToggleFaqItem>(_onToggleFaqItem);
  }

  Future<void> _onLoadFaq(LoadFaq event, Emitter<HelpState> emit) async {
    emit(HelpLoading());
    try {
      final faqItems = _helpRepository.getFaqItems();
      final categories = faqItems.map((e) => e.category).toSet().toList();
      emit(FaqLoaded(faqItems: faqItems, categories: categories));
    } catch (e) {
      emit(HelpError(message: e.toString()));
    }
  }

  Future<void> _onSendSupportMessage(
    SendSupportMessage event,
    Emitter<HelpState> emit,
  ) async {
    emit(HelpLoading());
    try {
      await _helpRepository.sendSupportMessage(
        name: event.name,
        email: event.email,
        subject: event.subject,
        message: event.message,
      );
      emit(SupportMessageSent());
    } catch (e) {
      emit(HelpError(message: e.toString()));
    }
  }

  Future<void> _onLoadAppInfo(LoadAppInfo event, Emitter<HelpState> emit) async {
    emit(HelpLoading());
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      emit(AppInfoLoaded(
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
      ));
    } catch (e) {
      emit(HelpError(message: e.toString()));
    }
  }

  void _onToggleFaqItem(ToggleFaqItem event, Emitter<HelpState> emit) {
    if (state is FaqLoaded) {
      final currentState = state as FaqLoaded;
      final newExpandedIndex =
          currentState.expandedIndex == event.index ? -1 : event.index;
      emit(currentState.copyWith(expandedIndex: newExpandedIndex));
    }
  }
}
