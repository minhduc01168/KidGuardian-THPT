import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user.displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authRepo = context.read<AuthRepository>();
        await authRepo.updateProfile(
          widget.user.uid,
          displayName: _nameController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isEditing = false;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cập nhật thành công'),
              backgroundColor: AppColors.success,
            ),
          );

          context.read<AuthBloc>().add(AuthStateChanged(
                user: User(
                  uid: widget.user.uid,
                  email: widget.user.email,
                  displayName: _nameController.text.trim(),
                  role: widget.user.role,
                  familyId: widget.user.familyId,
                  linkedTo: widget.user.linkedTo,
                  createdAt: widget.user.createdAt,
                ),
              ));
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thông tin cá nhân'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SizedBox(height: 20),
              CircleAvatar(
                radius: 60,
                backgroundColor: widget.user.role == UserRole.parent
                    ? AppColors.primaryLight
                    : AppColors.childPrimary.withOpacity(0.2),
                child: Icon(
                  widget.user.role == UserRole.parent
                      ? Icons.person
                      : Icons.child_care,
                  size: 60,
                  color: widget.user.role == UserRole.parent
                      ? AppColors.primary
                      : AppColors.childPrimary,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.user.role == UserRole.parent
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.childPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.user.role == UserRole.parent
                      ? 'Phụ huynh'
                      : 'Học sinh',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.user.role == UserRole.parent
                        ? AppColors.primary
                        : AppColors.childPrimary,
                  ),
                ),
              ),
              SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin tài khoản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_isEditing) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên',
                            prefixIcon: Icon(Icons.person_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập họ tên';
                            }
                            if (value.length < 2) {
                              return 'Tên phải có ít nhất 2 ký tự';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _nameController.text =
                                        widget.user.displayName;
                                  });
                                },
                                child: Text('Hủy'),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleSaveProfile,
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text('Lưu'),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _InfoRow(
                          icon: Icons.person,
                          label: 'Họ và tên',
                          value: widget.user.displayName,
                        ),
                        Divider(),
                        _InfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: widget.user.email,
                        ),
                        Divider(),
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: 'Ngày tạo',
                          value:
                              '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
                        ),
                        if (widget.user.familyId != null) ...[
                          Divider(),
                          _InfoRow(
                            icon: Icons.family_restroom,
                            label: 'Gia đình',
                            value: 'Đã liên kết',
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bảo mật',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      ListTile(
                        leading: Icon(Icons.lock_outline),
                        title: Text('Đổi mật khẩu'),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Tính năng đang phát triển'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showLogoutDialog(context);
                  },
                  icon: Icon(Icons.logout, color: AppColors.error),
                  label: Text(
                    AppStrings.logout,
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Đăng xuất'),
        content: Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.textSecondary),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
