import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/repositories/help_repository.dart';

class HelpRepositoryImpl implements HelpRepository {
  @override
  List<FaqItem> getFaqItems() {
    return const [
      FaqItem(
        question: 'KidGuardian là gì?',
        answer:
            'KidGuardian (Đồng Hành Số) là ứng dụng giúp phụ huynh quản lý thời gian sử dụng mạng xã hội và thiết bị di động của con em. Ứng dụng cung cấp các tính năng như giám sát sử dụng, khóa ứng dụng, cảnh báo từ khóa nhạy cảm, và quản lý yêu cầu thời gian.',
        category: 'Tổng quan',
      ),
      FaqItem(
        question: 'Làm thế nào để thêm tài khoản con?',
        answer:
            'Để thêm tài khoản con, bạn vào tab "Cài đặt" > "Quản lý gia đình" > "Thêm con". Sau đó, nhập thông tin của con và mã liên kết sẽ được tạo ra. Con bạn có thể sử dụng mã này để liên kết tài khoản.',
        category: 'Tổng quan',
      ),
      FaqItem(
        question: 'Làm thế nào để đặt giới hạn thời gian sử dụng?',
        answer:
            'Bạn có thể đặt giới hạn thời gian bằng cách vào "Giám sát" > "Giới hạn thời gian". Tại đây, bạn có thể đặt giới hạn theo từng ứng dụng hoặc theo tổng thời gian sử dụng trong ngày.',
        category: 'Sử dụng',
      ),
      FaqItem(
        question: 'Làm thế nào để khóa ứng dụng của con?',
        answer:
            'Để khóa ứng dụng, vào "Giám sát" > "Khóa ứng dụng". Bạn có thể chọn các ứng dụng muốn khóa ngay lập tức hoặc đặt lịch khóa tự động.',
        category: 'Sử dụng',
      ),
      FaqItem(
        question: 'Cảnh báo từ khóa nhạy cảm hoạt động như thế nào?',
        answer:
            'Hệ thống sẽ tự động quét và phát hiện các từ khóa nhạy cảm khi con sử dụng ứng dụng. Khi phát hiện, phụ huynh sẽ nhận được thông báo ngay lập tức. Bạn có thể quản lý danh sách từ khóa trong phần "Cài đặt" > "Quản lý từ khóa".',
        category: 'Sử dụng',
      ),
      FaqItem(
        question: 'Làm thế nào để con yêu cầu thêm thời gian?',
        answer:
            'Khi hết thời gian sử dụng, con có thể nhấn nút "Xin thêm 15 phút" trên màn hình khóa. Yêu cầu sẽ được gửi đến phụ huynh để duyệt. Phụ huynh có thể cài đặt tự động duyệt trong phần "Tự động duyệt yêu cầu".',
        category: 'Yêu cầu',
      ),
      FaqItem(
        question: 'Làm thế nào để xem báo cáo sử dụng?',
        answer:
            'Bạn có thể xem báo cáo chi tiết trong tab "Tổng quan" với biểu đồ sử dụng theo ngày. Ngoài ra, tính năng "Báo cáo tuần" cung cấp tổng hợp chi tiết về thói quen sử dụng của con.',
        category: 'Báo cáo',
      ),
      FaqItem(
        question: 'Tôi gặp lỗi khi sử dụng ứng dụng, phải làm sao?',
        answer:
            'Nếu gặp lỗi, bạn hãy thử: 1) Đóng và mở lại ứng dụng, 2) Kiểm tra kết nối internet, 3) Cập nhật ứng dụng lên phiên bản mới nhất. Nếu lỗi vẫn tiếp tục, vui lòng liên hệ hỗ trợ qua form "Liên hệ hỗ trợ".',
        category: 'Kỹ thuật',
      ),
      FaqItem(
        question: 'Làm thế nào để cập nhật ứng dụng?',
        answer:
            'Bạn có thể cập nhật ứng dụng thông qua Google Play Store (Android) hoặc App Store (iOS). Chúng tôi khuyến nghị bật tự động cập nhật để luôn có phiên bản mới nhất với các tính năng và bản sửa lỗi tốt nhất.',
        category: 'Kỹ thuật',
      ),
    ];
  }

  @override
  Future<void> sendSupportMessage({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@kidguardian.vn',
      queryParameters: {
        'subject': '[KidGuardian Support] $subject',
        'body': 'Tên: $name\nEmail: $email\n\n$message',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw Exception('Không thể mở ứng dụng email');
    }
  }
}
