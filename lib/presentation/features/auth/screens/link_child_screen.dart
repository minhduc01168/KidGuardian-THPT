import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/family_bloc.dart';
import '../bloc/family_event.dart';
import '../bloc/family_state.dart';

class LinkChildScreen extends StatefulWidget {
  const LinkChildScreen({super.key});

  @override
  State<LinkChildScreen> createState() => _LinkChildScreenState();
}

class _LinkChildScreenState extends State<LinkChildScreen> {
  final List<TextEditingController> _digitControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  @override
  void dispose() {
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handleCodeChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    final code = _digitControllers.map((c) => c.text).join();
    if (code.length == 6 && RegExp(r'^[A-Z0-9]{6}$').hasMatch(code)) {
      _handleLinkChild(code);
    }
  }

  void _handleLinkChild(String code) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<FamilyBloc>().add(LinkChildToFamilyRequested(
            linkingCode: code,
            childUid: authState.user.uid,
          ));
    }
  }

  void _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final text = data!.text!.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      if (text.length == 6) {
        for (var i = 0; i < 6; i++) {
          _digitControllers[i].text = text[i];
        }
        _handleLinkChild(text);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mã liên kết phải có 6 ký tự (chữ hoa và số)'),
              backgroundColor: AppColors.warning,
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
        title: Text('Liên kết tài khoản'),
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
          } else if (state is ChildLinkedToFamily) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Liên kết thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.link,
                  size: 80,
                  color: AppColors.childPrimary,
                ),
                SizedBox(height: 24),
                Text(
                  'Nhập mã liên kết',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhập mã 6 ký tự mà phụ huynh đã cung cấp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 50,
                      child: TextFormField(
                        controller: _digitControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.text,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        inputFormatters: [
                          UpperCaseTextFormatter(),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[A-Z0-9]'),
                          ),
                        ],
                        onChanged: (value) =>
                            _handleCodeChanged(index, value),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    onPressed: _handlePaste,
                    icon: Icon(Icons.paste),
                    label: Text('Dán mã từ bộ nhớ tạm'),
                  ),
                ),
                SizedBox(height: 32),

                BlocBuilder<FamilyBloc, FamilyState>(
                  builder: (context, state) {
                    return SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: state is FamilyLoading
                            ? null
                            : () {
                                final code = _digitControllers
                                    .map((c) => c.text)
                                    .join();
                                if (code.length == 6 &&
                                    RegExp(r'^[A-Z0-9]{6}$')
                                        .hasMatch(code)) {
                                  _handleLinkChild(code);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Vui lòng nhập mã 6 ký tự (chữ hoa và số)'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                }
                              },
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
                                'Liên kết',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),

                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mã liên kết được tạo bởi phụ huynh khi tạo tài khoản cho bạn. Hãy hỏi phụ huynh nếu bạn chưa có mã.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
