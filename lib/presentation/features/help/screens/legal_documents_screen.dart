import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class LegalDocumentsScreen extends StatefulWidget {
  final String title;
  final String documentType;

  const LegalDocumentsScreen({
    super.key,
    required this.title,
    required this.documentType,
  });

  @override
  State<LegalDocumentsScreen> createState() => _LegalDocumentsScreenState();
}

class _LegalDocumentsScreenState extends State<LegalDocumentsScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_getDocumentContent());
  }

  String _getDocumentContent() {
    if (widget.documentType == 'terms') {
      return _getTermsOfService();
    } else {
      return _getPrivacyPolicy();
    }
  }

  String _getTermsOfService() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      line-height: 1.6;
      color: #333;
      padding: 16px;
      max-width: 800px;
      margin: 0 auto;
    }
    h1 {
      color: #2196F3;
      font-size: 24px;
      border-bottom: 2px solid #2196F3;
      padding-bottom: 8px;
    }
    h2 {
      color: #1976D2;
      font-size: 20px;
      margin-top: 24px;
    }
    h3 {
      color: #424242;
      font-size: 18px;
      margin-top: 16px;
    }
    p {
      margin-bottom: 12px;
    }
    ul {
      margin-bottom: 12px;
      padding-left: 24px;
    }
    li {
      margin-bottom: 8px;
    }
    .highlight {
      background-color: #E3F2FD;
      padding: 12px;
      border-radius: 8px;
      margin-bottom: 16px;
    }
    .last-updated {
      color: #757575;
      font-style: italic;
      margin-top: 24px;
    }
  </style>
</head>
<body>
  <h1>Điều khoản sử dụng</h1>
  <p class="last-updated">Cập nhật lần cuối: 01/01/2026</p>

  <div class="highlight">
    <p><strong>Lưu ý:</strong> Vui lòng đọc kỹ các điều khoản sử dụng trước khi sử dụng ứng dụng KidGuardian (Đồng Hành Số).</p>
  </div>

  <h2>1. Chấp nhận điều khoản</h2>
  <p>Bằng việc truy cập và sử dụng ứng dụng KidGuardian, bạn đồng ý tuân thủ và bị ràng buộc bởi các điều khoản sử dụng này. Nếu bạn không đồng ý với bất kỳ phần nào của điều khoản, vui lòng không sử dụng ứng dụng.</p>

  <h2>2. Mô tả dịch vụ</h2>
  <p>KidGuardian là ứng dụng quản lý thời gian sử dụng thiết bị di động cho trẻ em, cung cấp các tính năng bao gồm:</p>
  <ul>
    <li>Giám sát thời gian sử dụng ứng dụng</li>
    <li>Quản lý và khóa ứng dụng</li>
    <li>Cảnh báo từ khóa nhạy cảm</li>
    <li>Quản lý yêu cầu thời gian sử dụng</li>
    <li>Báo cáo và thống kê sử dụng</li>
  </ul>

  <h2>3. Tài khoản người dùng</h2>
  <h3>3.1 Đăng ký tài khoản</h3>
  <p>Để sử dụng đầy đủ tính năng, bạn cần tạo tài khoản với thông tin chính xác và đầy đủ. Bạn chịu trách nhiệm bảo mật thông tin tài khoản của mình.</p>

  <h3>3.2 Trách nhiệm của phụ huynh</h3>
  <p>Phụ huynh chịu trách nhiệm:</p>
  <ul>
    <li>Giám sát việc sử dụng ứng dụng của con em</li>
    <li>Đảm bảo thông tin tài khoản được bảo mật</li>
    <li>Sử dụng ứng dụng có trách nhiệm và phù hợp</li>
  </ul>

  <h2>4. Quyền riêng tư</h2>
  <p>Việc thu thập và sử dụng thông tin cá nhân được quy định trong Chính sách bảo mật của chúng tôi. Bằng việc sử dụng ứng dụng, bạn đồng ý với việc thu thập và sử dụng thông tin theo chính sách đó.</p>

  <h2>5. Sử dụng đúng mục đích</h2>
  <p>Bạn đồng ý không:</p>
  <ul>
    <li>Sử dụng ứng dụng cho mục đích bất hợp pháp</li>
    <li>Can thiệp vào hoạt động của ứng dụng</li>
    <li>Truy cập trái phép vào hệ thống</li>
    <li>Chia sẻ tài khoản với người khác</li>
  </ul>

  <h2>6. Giới hạn trách nhiệm</h2>
  <p>KidGuardian không chịu trách nhiệm về:</p>
  <ul>
    <li>Thiệt hại gián tiếp hoặc hệ quả</li>
    <li>Mất mát dữ liệu do sự cố kỹ thuật</li>
    <li>Quyết định của người dùng dựa trên thông tin từ ứng dụng</li>
  </ul>

  <h2>7. Thay đổi điều khoản</h2>
  <p>Chúng tôi có quyền cập nhật điều khoản sử dụng bất kỳ lúc nào. Các thay đổi sẽ có hiệu lực ngay khi được đăng tải trên ứng dụng.</p>

  <h2>8. Liên hệ</h2>
  <p>Nếu bạn có câu hỏi về điều khoản sử dụng, vui lòng liên hệ:</p>
  <p>Email: support@kidguardian.vn</p>

  <p class="last-updated">Điều khoản này được cập nhật lần cuối vào ngày 01/01/2026.</p>
</body>
</html>
''';
  }

  String _getPrivacyPolicy() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
      line-height: 1.6;
      color: #333;
      padding: 16px;
      max-width: 800px;
      margin: 0 auto;
    }
    h1 {
      color: #2196F3;
      font-size: 24px;
      border-bottom: 2px solid #2196F3;
      padding-bottom: 8px;
    }
    h2 {
      color: #1976D2;
      font-size: 20px;
      margin-top: 24px;
    }
    h3 {
      color: #424242;
      font-size: 18px;
      margin-top: 16px;
    }
    p {
      margin-bottom: 12px;
    }
    ul {
      margin-bottom: 12px;
      padding-left: 24px;
    }
    li {
      margin-bottom: 8px;
    }
    .highlight {
      background-color: #E8F5E9;
      padding: 12px;
      border-radius: 8px;
      margin-bottom: 16px;
    }
    .important {
      background-color: #FFF3E0;
      padding: 12px;
      border-radius: 8px;
      margin-bottom: 16px;
    }
    .last-updated {
      color: #757575;
      font-style: italic;
      margin-top: 24px;
    }
  </style>
</head>
<body>
  <h1>Chính sách bảo mật</h1>
  <p class="last-updated">Cập nhật lần cuối: 01/01/2026</p>

  <div class="highlight">
    <p><strong>Cam kết:</strong> KidGuardian cam kết bảo vệ quyền riêng tư và thông tin cá nhân của bạn và con em bạn.</p>
  </div>

  <h2>1. Thông tin chúng tôi thu thập</h2>
  <h3>1.1 Thông tin cá nhân</h3>
  <p>Khi đăng ký tài khoản, chúng tôi thu thập:</p>
  <ul>
    <li>Họ và tên</li>
    <li>Địa chỉ email</li>
    <li>Mật khẩu (được mã hóa)</li>
    <li>Vai trò (phụ huynh hoặc con)</li>
  </ul>

  <h3>1.2 Thông tin sử dụng</h3>
  <p>Trong quá trình sử dụng, chúng tôi thu thập:</p>
  <ul>
    <li>Thời gian sử dụng ứng dụng</li>
    <li>Danh sách ứng dụng được giám sát</li>
    <li>Lịch sử hoạt động</li>
    <li>Yêu cầu và phản hồi</li>
  </ul>

  <h3>1.3 Thông tin thiết bị</h3>
  <p>Chúng tôi có thể thu thập thông tin thiết bị bao gồm:</p>
  <ul>
    <li>Loại thiết bị và hệ điều hành</li>
    <li>Định danh thiết bị</li>
    <li>Thông tin phiên bản ứng dụng</li>
  </ul>

  <h2>2. Mục đích sử dụng thông tin</h2>
  <p>Chúng tôi sử dụng thông tin thu thập để:</p>
  <ul>
    <li>Cung cấp và duy trì dịch vụ</li>
    <li>Quản lý tài khoản người dùng</li>
    <li>Gửi thông báo và cảnh báo</li>
    <li>Cải thiện chất lượng dịch vụ</li>
    <li>Đảm bảo an toàn và bảo mật</li>
  </ul>

  <h2>3. Chia sẻ thông tin</h2>
  <div class="important">
    <p><strong>Quan trọng:</strong> Chúng tôi không bán hoặc chia sẻ thông tin cá nhân của bạn cho bên thứ ba vì mục đích thương mại.</p>
  </div>
  <p>Thông tin có thể được chia sẻ trong các trường hợp:</p>
  <ul>
    <li>Khi có yêu cầu từ cơ quan pháp luật</li>
    <li>Để bảo vệ quyền lợi của KidGuardian</li>
    <li>Với sự đồng ý của người dùng</li>
  </ul>

  <h2>4. Bảo mật thông tin</h2>
  <p>Chúng tôi áp dụng các biện pháp bảo mật bao gồm:</p>
  <ul>
    <li>Mã hóa dữ liệu nhạy cảm</li>
    <li>Xác thực hai yếu tố (tùy chọn)</li>
    <li>Giám sát hoạt động bất thường</li>
    <li>Cập nhật bảo mật định kỳ</li>
  </ul>

  <h2>5. Quyền của người dùng</h2>
  <p>Bạn có quyền:</p>
  <ul>
    <li>Truy cập thông tin cá nhân</li>
    <li>Yêu cầu chỉnh sửa thông tin</li>
    <li>Yêu cầu xóa tài khoản</li>
    <li>Từ chối nhận thông báo marketing</li>
  </ul>

  <h2>6. Bảo vệ thông tin trẻ em</h2>
  <p>KidGuardian đặc biệt chú trọng bảo vệ thông tin của trẻ em:</p>
  <ul>
    <li>Thu thập thông tin tối thiểu cần thiết</li>
    <li>Không sử dụng thông tin trẻ em cho mục đích quảng cáo</li>
    <li>Cho phép phụ huynh kiểm soát thông tin con em</li>
    <li>Tuân thủ các quy định về bảo vệ trẻ em</li>
  </ul>

  <h2>7. Lưu trữ dữ liệu</h2>
  <p>Dữ liệu được lưu trữ trên các máy chủ an toàn và được bảo vệ bằng các biện pháp bảo mật tiên tiến. Chúng tôi lưu trữ dữ liệu trong thời gian cần thiết để cung cấp dịch vụ.</p>

  <h2>8. Thay đổi chính sách</h2>
  <p>Chúng tôi có thể cập nhật chính sách bảo mật này. Các thay đổi quan trọng sẽ được thông báo đến người dùng.</p>

  <h2>9. Liên hệ</h2>
  <p>Nếu bạn có câu hỏi về chính sách bảo mật, vui lòng liên hệ:</p>
  <p>Email: privacy@kidguardian.vn</p>

  <p class="last-updated">Chính sách này được cập nhật lần cuối vào ngày 01/01/2026.</p>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
