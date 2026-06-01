import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/help_bloc.dart';
import '../bloc/help_event.dart';
import '../bloc/help_state.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    super.initState();
    context.read<HelpBloc>().add(LoadFaq());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Câu hỏi thường gặp'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<HelpBloc, HelpState>(
        builder: (context, state) {
          if (state is HelpLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is HelpError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<HelpBloc>().add(LoadFaq());
                    },
                    child: Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is FaqLoaded) {
            final categories = ['Tất cả', ...state.categories];
            final filteredItems = _selectedCategory == 'Tất cả'
                ? state.faqItems
                : state.faqItems
                    .where((item) => item.category == _selectedCategory)
                    .toList();

            return Column(
              children: [
                // Category filter
                Container(
                  height: 50,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primaryLight,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // FAQ list
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      final isExpanded = state.expandedIndex == index;

                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          key: Key(index.toString()),
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            context
                                .read<HelpBloc>()
                                .add(ToggleFaqItem(index: index));
                          },
                          leading: Icon(
                            Icons.help_outline,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            item.question,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    item.answer,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return SizedBox.shrink();
        },
      ),
    );
  }
}
