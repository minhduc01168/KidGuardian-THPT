import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/presentation/blocs/keyword_management/keyword_management_bloc.dart';

class KeywordManagementScreen extends StatelessWidget {
  final String familyId;

  const KeywordManagementScreen({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => KeywordManagementBloc()
        ..add(LoadKeywords(familyId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý từ khóa'),
          actions: [
            BlocBuilder<KeywordManagementBloc, KeywordManagementState>(
              builder: (context, state) {
                if (state is KeywordManagementLoaded) {
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'reset') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Đặt lại mặc định'),
                            content: const Text('Bạn có muốn đặt lại danh sách từ khóa mặc định không?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Hủy'),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.read<KeywordManagementBloc>().add(
                                    ResetToDefaults(familyId),
                                  );
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Đặt lại'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'reset',
                        child: Row(
                          children: [
                            Icon(Icons.restore),
                            SizedBox(width: 8),
                            Text('Đặt lại mặc định'),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<KeywordManagementBloc, KeywordManagementState>(
          builder: (context, state) {
            if (state is KeywordManagementLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is KeywordManagementError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            }
            if (state is KeywordManagementLoaded) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _AddKeywordInput(familyId: familyId),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Từ khóa đang theo dõi:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: state.keywords.isEmpty
                        ? const Center(
                            child: Text(
                              'Chưa có từ khóa nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: state.keywords.map((keyword) {
                                return Chip(
                                  label: Text(keyword),
                                  deleteIcon: const Icon(Icons.close, size: 18),
                                  onDeleted: () {
                                    context.read<KeywordManagementBloc>().add(
                                      RemoveKeyword(familyId: familyId, keyword: keyword),
                                    );
                                  },
                                  backgroundColor: Colors.red.shade50,
                                  side: BorderSide(color: Colors.red.shade200),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AddKeywordInput extends StatefulWidget {
  final String familyId;
  const _AddKeywordInput({required this.familyId});

  @override
  State<_AddKeywordInput> createState() => _AddKeywordInputState();
}

class _AddKeywordInputState extends State<_AddKeywordInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final keyword = _controller.text.trim();
    if (keyword.isNotEmpty) {
      context.read<KeywordManagementBloc>().add(
        AddKeyword(familyId: widget.familyId, keyword: keyword),
      );
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Nhập từ khóa mới...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onSubmitted: (_) => _addKeyword(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _addKeyword,
          icon: const Icon(Icons.add),
          label: const Text('Thêm'),
        ),
      ],
    );
  }
}
