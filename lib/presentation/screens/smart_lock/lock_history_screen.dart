import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_bloc.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_event.dart';
import 'package:kidguardian/presentation/blocs/smart_lock/smart_lock_state.dart';
import 'package:kidguardian/data/models/lock_history_entry_model.dart';
import 'package:kidguardian/presentation/widgets/smart_lock/lock_history_card.dart';
import 'package:intl/intl.dart';

class LockHistoryScreen extends StatefulWidget {
  final String familyId;
  final String childId;

  const LockHistoryScreen({
    super.key,
    required this.familyId,
    required this.childId,
  });

  @override
  State<LockHistoryScreen> createState() => _LockHistoryScreenState();
}

class _LockHistoryScreenState extends State<LockHistoryScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    context
        .read<SmartLockBloc>()
        .add(LoadLockHistory(widget.familyId, widget.childId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử khoá'),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: BlocBuilder<SmartLockBloc, SmartLockState>(
              buildWhen: (previous, current) {
                return current is LockHistoryLoaded ||
                    current is SmartLockLoading;
              },
              builder: (context, state) {
                if (state is SmartLockLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is LockHistoryLoaded) {
                  final filteredHistory = _filterHistory(state.history);

                  if (filteredHistory.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có lịch sử khoá',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      return LockHistoryCard(entry: filteredHistory[index]);
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip('all', 'Tất cả'),
          const SizedBox(width: 8),
          _buildChip('today', 'Hôm nay'),
          const SizedBox(width: 8),
          _buildChip('7days', '7 ngày'),
          const SizedBox(width: 8),
          _buildChip('30days', '30 ngày'),
        ],
      ),
    );
  }

  Widget _buildChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }

  List<LockHistoryEntryModel> _filterHistory(
    List<LockHistoryEntryModel> history,
  ) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'today':
        return history.where((entry) {
          return entry.lockedAt.year == now.year &&
              entry.lockedAt.month == now.month &&
              entry.lockedAt.day == now.day;
        }).toList();
      case '7days':
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return history
            .where((entry) => entry.lockedAt.isAfter(sevenDaysAgo))
            .toList();
      case '30days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        return history
            .where((entry) => entry.lockedAt.isAfter(thirtyDaysAgo))
            .toList();
      default:
        return history;
    }
  }
}
