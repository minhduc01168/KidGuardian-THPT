import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../domain/entities/family.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/family_repository.dart';
import '../../auth/bloc/family_bloc.dart';
import '../../auth/bloc/family_event.dart';
import '../../auth/bloc/family_state.dart';
import '../../auth/screens/create_child_screen.dart';

class FamilyManagementScreen extends StatefulWidget {
  final User user;

  const FamilyManagementScreen({super.key, required this.user});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  Family? _family;
  List<User> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    if (widget.user.familyId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final familyRepo = context.read<FamilyRepository>();
      final family = await familyRepo.getFamily(widget.user.familyId!);

      if (family != null && mounted) {
        final List<User> children = [];
        final firestore = FirebaseFirestore.instance;

        for (final childUid in family.childUids) {
          final doc = await firestore.collection('users').doc(childUid).get();
          if (doc.exists) {
            children.add(User(
              uid: doc.id,
              email: doc['email'] ?? '',
              displayName: doc['displayName'] ?? '',
              role: UserRole.child,
              familyId: doc['familyId'],
              linkedTo: doc['linkedTo'],
              createdAt: (doc['createdAt'] as Timestamp).toDate(),
            ));
          }
        }

        if (mounted) {
          setState(() {
            _family = family;
            _children = children;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmRemoveChild(User child) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xóa tài khoản con'),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${child.displayName} khỏi gia đình?\n\n'
          'Dữ liệu liên quan sẽ được dọn dẹp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _removeChild(child);
            },
            child: Text(
              'Xóa',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _removeChild(User child) {
    if (_family == null) return;
    context.read<FamilyBloc>().add(RemoveChildFromFamilyRequested(
          familyId: _family!.familyId,
          childUid: child.uid,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý gia đình'),
      ),
      body: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is ChildRemovedFromFamily) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã xóa tài khoản con khỏi gia đình'),
                backgroundColor: AppColors.success,
              ),
            );
            _loadFamilyData();
          }
        },
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadFamilyData,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildFamilyHeader(),
          SizedBox(height: 24),
          _buildChildrenSection(),
        ],
      ),
    );
  }

  Widget _buildFamilyHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 12),
          Text(
            'Gia đình của bạn',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${_children.length} tài khoản con',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          if (_family != null && _family!.linkingCode != null && _family!.linkingCode!.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mã liên kết: ',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    _family!.linkingCode!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hướng dẫn kết nối:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. Cài đặt KidGuardian trên máy của con.\n'
                    '2. Chọn đăng ký tài khoản với vai trò "Con".\n'
                    '3. Đăng nhập và nhập Mã liên kết ở trên.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildrenSection() {
    if (_children.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.child_care,
                size: 64,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'Chưa có tài khoản con',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Thêm tài khoản con để bắt đầu giám sát',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách con',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        ..._children.map((child) => _buildChildCard(child)),
      ],
    );
  }

  Widget _buildChildCard(User child) {
    final isLinked = child.familyId != null;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.childPrimary.withOpacity(0.2),
              child: Icon(
                Icons.child_care,
                size: 28,
                color: AppColors.childPrimary,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    child.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLinked
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLinked ? 'Đã liên kết' : 'Chưa liên kết',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color:
                            isLinked ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () => _confirmRemoveChild(child),
              tooltip: 'Xóa',
            ),
          ],
        ),
      ),
    );
  }


