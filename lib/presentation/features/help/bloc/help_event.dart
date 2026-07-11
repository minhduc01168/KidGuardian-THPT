abstract class HelpEvent {}

class LoadFaq extends HelpEvent {}

class SendSupportMessage extends HelpEvent {
  final String name;
  final String email;
  final String subject;
  final String message;

  SendSupportMessage({
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
  });
}

class LoadAppInfo extends HelpEvent {}

class ToggleFaqItem extends HelpEvent {
  final int index;

  ToggleFaqItem({required this.index});
}
