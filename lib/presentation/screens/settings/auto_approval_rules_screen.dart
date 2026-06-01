import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/data/models/auto_approval_rule_model.dart';
import 'package:kidguardian/domain/repositories/rules_repository.dart';
import 'package:kidguardian/presentation/blocs/rules/rules_bloc.dart';

class AutoApprovalRulesScreen extends StatelessWidget {
  final String familyId;
  final List<String> monitoredApps;

  const AutoApprovalRulesScreen({
    super.key,
    required this.familyId,
    this.monitoredApps = const [],
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RulesBloc(
        repository: context.read<RulesRepository>(),
        familyId: familyId,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tự động duyệt yêu cầu'),
        ),
        body: BlocConsumer<RulesBloc, RulesState>(
          listener: (context, state) {
            if (state is RulesSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is RulesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RulesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RulesLoaded) {
              return _buildRulesForm(context, state.rule);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildRulesForm(BuildContext context, AutoApprovalRule rule) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnableSection(context, rule),
          const SizedBox(height: 24),
          if (rule.isEnabled) ...[
            _buildMaxMinutesSection(context, rule),
            const SizedBox(height: 24),
            _buildDailyLimitSection(context, rule),
            const SizedBox(height: 24),
            _buildAppSpecificSection(context, rule),
            const SizedBox(height: 32),
            _buildSaveButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildEnableSection(BuildContext context, AutoApprovalRule rule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: rule.isEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bật tự động duyệt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tự động duyệt yêu cầu khi đáp ứng điều kiện',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isEnabled,
                  onChanged: (value) {
                    context.read<RulesBloc>().add(ToggleRulesEnabled(value));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxMinutesSection(BuildContext context, AutoApprovalRule rule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Số phút tối đa được tự động duyệt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yêu cầu vượt quá số phút này sẽ cần phụ huynh duyệt thủ công',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: rule.maxAutoApproveMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${rule.maxAutoApproveMinutes} phút',
                    onChanged: (value) {
                      context.read<RulesBloc>().add(
                        UpdateMaxMinutes(value.round()),
                      );
                    },
                  ),
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${rule.maxAutoApproveMinutes} phút',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [15, 30, 45, 60].map((minutes) {
                return ChoiceChip(
                  label: Text('$minutes phút'),
                  selected: rule.maxAutoApproveMinutes == minutes,
                  onSelected: (_) {
                    context.read<RulesBloc>().add(UpdateMaxMinutes(minutes));
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLimitSection(BuildContext context, AutoApprovalRule rule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giới hạn tự động duyệt mỗi ngày',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Số lần tối đa được tự động duyệt trong một ngày',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: rule.dailyAutoApproveLimit > 1
                      ? () {
                          context.read<RulesBloc>().add(
                            UpdateDailyLimit(rule.dailyAutoApproveLimit - 1),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    '${rule.dailyAutoApproveLimit}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: rule.dailyAutoApproveLimit < 10
                      ? () {
                          context.read<RulesBloc>().add(
                            UpdateDailyLimit(rule.dailyAutoApproveLimit + 1),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'lần/ngày',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSpecificSection(BuildContext context, AutoApprovalRule rule) {
    final allApps = [
      ...monitoredApps,
      ...rule.appSpecificRules.keys.where((app) => !monitoredApps.contains(app)),
    ];

    if (allApps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Áp dụng cho từng ứng dụng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bật/tắt tự động duyệt cho từng ứng dụng cụ thể',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ...allApps.map((app) {
              final isEnabled = rule.appSpecificRules[app] ?? true;
              return _buildAppToggle(context, app, isEnabled);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppToggle(BuildContext context, String app, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.apps,
            color: isEnabled ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              app,
              style: TextStyle(
                fontSize: 14,
                color: isEnabled ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              context.read<RulesBloc>().add(ToggleAppRule(app, value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<RulesBloc>().add(SaveRules());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B7FE8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Lưu cài đặt',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
