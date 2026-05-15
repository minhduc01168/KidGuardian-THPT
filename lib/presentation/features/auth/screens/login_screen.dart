import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ));
    }
  }
  
  void _handleResetPassword() {
    if (_emailController.text.isNotEmpty) {
      context.read<AuthBloc>().add(ResetPasswordRequested(
        email: _emailController.text.trim(),
      ));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã gửi email đặt lại mật khẩu'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Icon(
                      Icons.shield_rounded,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: 16),
                    
                    // App name
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      AppStrings.appTagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 48),
                    
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
                    SizedBox(height: 8),
                    
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _handleResetPassword,
                        child: Text(AppStrings.forgotPassword),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Login button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: state is AuthLoading ? null : _handleLogin,
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
                                    AppStrings.login,
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    
                    // Register link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppStrings.noAccount),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(AppStrings.register),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
