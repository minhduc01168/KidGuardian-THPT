import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.parent;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(RegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        role: _selectedRole,
      ));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.register),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đăng ký thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
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
                  // Role selection
                  Text(
                    'Bạn là:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _RoleCard(
                          title: AppStrings.parent,
                          icon: Icons.person,
                          isSelected: _selectedRole == UserRole.parent,
                          onTap: () {
                            setState(() {
                              _selectedRole = UserRole.parent;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _RoleCard(
                          title: AppStrings.child,
                          icon: Icons.child_care,
                          isSelected: _selectedRole == UserRole.child,
                          onTap: () {
                            setState(() {
                              _selectedRole = UserRole.child;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.displayName,
                      prefixIcon: Icon(Icons.person_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập họ tên';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      prefixIcon: Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (value.length < 8) {
                        return 'Mật khẩu phải ít nhất 8 ký tự';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: AppStrings.confirmPassword,
                      prefixIcon: Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng xác nhận mật khẩu';
                      }
                      if (value != _passwordController.text) {
                        return 'Mật khẩu không khớp';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32),
                  
                  // Register button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading ? null : _handleRegister,
                          child: state is AuthLoading
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  AppStrings.register,
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppStrings.hasAccount),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(AppStrings.login),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  
  const _RoleCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
