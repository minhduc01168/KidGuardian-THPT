import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/help_bloc.dart';
import 'faq_screen.dart';
import 'contact_support_screen.dart';
import 'app_info_screen.dart';
import 'legal_documents_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trợ giúp & Hỗ trợ'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Câu hỏi thường gặp'),
          Card(
            child: ListTile(
              leading: Icon(Icons.question_answer, color: AppColors.primary),
              title: Text('FAQ'),
              subtitle: Text('Tìm câu trả lời cho các câu hỏi thường gặp'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<HelpBloc>(),
                      child: FaqScreen(),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),
          _buildSectionHeader('Liên hệ'),
          Card(
            child: ListTile(
              leading: Icon(Icons.email, color: AppColors.accent),
              title: Text('Liên hệ hỗ trợ'),
              subtitle: Text('Gửi yêu cầu hỗ trợ đến đội ngũ Kura'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<HelpBloc>(),
                      child: ContactSupportScreen(),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),
          _buildSectionHeader('Thông tin'),
          Card(
            child: ListTile(
              leading: Icon(Icons.info, color: AppColors.warning),
              title: Text('Thông tin ứng dụng'),
              subtitle: Text('Phiên bản và thông tin chi tiết'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: context.read<HelpBloc>(),
                      child: AppInfoScreen(),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 24),
          _buildSectionHeader('Pháp lý'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.description, color: AppColors.textSecondary),
                  title: Text('Điều khoản sử dụng'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalDocumentsScreen(
                          title: 'Điều khoản sử dụng',
                          documentType: 'terms',
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1, indent: 16),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: AppColors.textSecondary),
                  title: Text('Chính sách bảo mật'),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalDocumentsScreen(
                          title: 'Chính sách bảo mật',
                          documentType: 'privacy',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
