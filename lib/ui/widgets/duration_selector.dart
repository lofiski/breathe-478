import 'package:flutter/material.dart';

/// Lets the user either pick a quick preset or drag to any custom minute
/// value; null means "unlimited" (session runs until stopped manually).
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
  });

  static const List<int> quickPresets = [5, 10, 15, 20];
  static const int minMinutes = 1;
  static const int maxMinutes = 60;

  final int? selectedMinutes;
  final ValueChanged<int?> onChanged;

  bool get _isUnlimited => selectedMinutes == null;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final minutes in quickPresets)
              ChoiceChip(
                label: Text('$minutes 分钟'),
                selected: selectedMinutes == minutes,
                onSelected: (_) => onChanged(minutes),
              ),
            ChoiceChip(
              label: const Text('不限时'),
              selected: _isUnlimited,
              onSelected: (_) => onChanged(null),
            ),
          ],
        ),
        if (!_isUnlimited) ...[
          const SizedBox(height: 4),
          Text(
            '自定义时长：$selectedMinutes 分钟',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: selectedMinutes!.clamp(minMinutes, maxMinutes).toDouble(),
            min: minMinutes.toDouble(),
            max: maxMinutes.toDouble(),
            divisions: maxMinutes - minMinutes,
            label: '$selectedMinutes 分钟',
            onChanged: (value) => onChanged(value.round()),
          ),
        ],
      ],
    );
  }
}
