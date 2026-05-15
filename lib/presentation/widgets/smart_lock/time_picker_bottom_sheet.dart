import 'package:flutter/material.dart';

class TimePickerBottomSheet extends StatefulWidget {
  final Map<String, int> initialLimits;
  final Function(Map<String, int>) onSave;

  const TimePickerBottomSheet({
    super.key,
    required this.initialLimits,
    required this.onSave,
  });

  @override
  State<TimePickerBottomSheet> createState() => _TimePickerBottomSheetState();
}

class _TimePickerBottomSheetState extends State<TimePickerBottomSheet> {
  bool _isEveryday = true;
  int _everydayMinutes = 60;
  final Map<String, int> _customLimits = {
    'monday': 60,
    'tuesday': 60,
    'wednesday': 60,
    'thursday': 60,
    'friday': 60,
    'saturday': 120,
    'sunday': 120,
  };

  final List<String> _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  final Map<String, String> _dayLabels = {
    'monday': 'Thứ 2', 'tuesday': 'Thứ 3', 'wednesday': 'Thứ 4',
    'thursday': 'Thứ 5', 'friday': 'Thứ 6', 'saturday': 'Thứ 7', 'sunday': 'CN'
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialLimits.isNotEmpty) {
      if (widget.initialLimits.containsKey('everyday')) {
        _isEveryday = true;
        _everydayMinutes = widget.initialLimits['everyday']!;
      } else {
        _isEveryday = false;
        widget.initialLimits.forEach((key, value) {
          if (_customLimits.containsKey(key)) {
            _customLimits[key] = value;
          }
        });
      }
    }
  }

  void _save() {
    if (_isEveryday) {
      widget.onSave(_everydayMinutes == 0 ? {} : {'everyday': _everydayMinutes});
    } else {
      widget.onSave(Map.from(_customLimits));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: mediaQuery.viewInsets.bottom + 16,
        ),
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cài đặt giới hạn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
              ],
            ),
            SwitchListTile(
              title: const Text('Mỗi ngày như nhau'),
              value: _isEveryday,
              onChanged: (val) {
                setState(() {
                  _isEveryday = val;
                });
              },
            ),
            const Divider(),
            Flexible(
              child: _isEveryday ? _buildEverydayPicker() : _buildCustomDaysPicker(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEverydayPicker() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Thời gian giới hạn (phút)', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 16),
        Slider(
          value: _everydayMinutes.toDouble(),
          min: 0,
          max: 240,
          divisions: 24,
          label: '$_everydayMinutes phút',
          onChanged: (val) {
            setState(() {
              _everydayMinutes = val.toInt();
            });
          },
        ),
        Text('$_everydayMinutes phút', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCustomDaysPicker() {
    return ListView.builder(
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final val = _customLimits[day] ?? 60;
        return ListTile(
          title: Text(_dayLabels[day]!),
          trailing: SizedBox(
            width: 150,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: val > 0 ? () {
                    setState(() { _customLimits[day] = (val - 10).clamp(0, 240); });
                  } : null,
                ),
                Expanded(child: Text('$val p', textAlign: TextAlign.center)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: val <= 230 ? () {
                    setState(() { _customLimits[day] = (val + 10).clamp(0, 240); });
                  } : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
