import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';

class CreateChildScreen extends StatefulWidget {
  final String familyId;

  const CreateChildScreen({super.key, required this.familyId});

  @override
  State<CreateChildScreen> createState() => _CreateChildScreenState();
}

class _CreateChildScreenState extends State<CreateChildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _generatedLinkingCode;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleCreateChild() {
    if (_formKey.currentState!.validate()) {
      context.read<FamilyBloc>().add(CreateChildAccountRequested(
            name: _nameController.text.trim(),
            age: int.parse(_ageController.text.trim()),
            familyId: widget.familyId,
          ));
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã liên kết'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tạo tài khoản con'),
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
          } else if (state is ChildAccountCreated) {
            setState(() {
              _generatedLinkingCode = state.linkingCode;
            });
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.child_care,
                    size: 80,
                    color: AppColors.childPrimary,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Tạo tài khoản cho con',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Nhập thông tin của con để tạo tài khoản',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 32),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên của con',
                      prefixIcon: Icon(Icons.person_outlined),
                      hintText: 'Nhập tên hiển thị',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên';
                      }
                      if (value.length < 2) {
                        return 'Tên phải có ít nhất 2 ký tự';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),

                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Tuổi',
                      prefixIcon: Icon(Icons.cake_outlined),
                      hintText: 'Nhập tuổi của con',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tuổi';
                      }
                      final age = int.tryParse(value);
                      if (age == null || age < 3 || age > 18) {
                        return 'Tuổi phải từ 3 đến 18';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),

                  BlocBuilder<FamilyBloc, FamilyState>(
                    builder: (context, state) {
                      return SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state is FamilyLoading
                              ? null
                              : _handleCreateChild,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.childPrimary,
                          ),
                          child: state is FamilyLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Tạo tài khoản',
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 32),

                  if (_generatedLinkingCode != null) ...[
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 48,
                            color: AppColors.success,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Tạo tài khoản thành công!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Mã liên kết của con:',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.divider,
                              ),
                            ),
                            child: Text(
                              _generatedLinkingCode!,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Cho con nhập mã này trong ứng dụng để liên kết tài khoản',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _copyToClipboard(_generatedLinkingCode!),
                              icon: Icon(Icons.copy),
                              label: Text('Sao chép mã'),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _nameController.clear();
                          _ageController.clear();
                          setState(() {
                            _generatedLinkingCode = null;
                          });
                        },
                        child: Text('Tạo tài khoản khác'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
