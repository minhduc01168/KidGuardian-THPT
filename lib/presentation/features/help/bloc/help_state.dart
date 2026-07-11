import 'package:equatable/equatable.dart';
import '../../../../domain/entities/faq_item.dart';

abstract class HelpState extends Equatable {
  const HelpState();

  @override
  List<Object?> get props => [];
}

class HelpInitial extends HelpState {}

class HelpLoading extends HelpState {}

class HelpError extends HelpState {
  final String message;

  const HelpError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FaqLoaded extends HelpState {
  final List<FaqItem> faqItems;
  final List<String> categories;
  final int expandedIndex;

  const FaqLoaded({
    required this.faqItems,
    required this.categories,
    this.expandedIndex = -1,
  });

  FaqLoaded copyWith({
    List<FaqItem>? faqItems,
    List<String>? categories,
    int? expandedIndex,
  }) {
    return FaqLoaded(
      faqItems: faqItems ?? this.faqItems,
      categories: categories ?? this.categories,
      expandedIndex: expandedIndex ?? this.expandedIndex,
    );
  }

  @override
  List<Object?> get props => [faqItems, categories, expandedIndex];
}

class SupportMessageSent extends HelpState {}

class AppInfoLoaded extends HelpState {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  const AppInfoLoaded({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  @override
  List<Object?> get props => [appName, packageName, version, buildNumber];
}
