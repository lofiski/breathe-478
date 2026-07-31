import 'package:flutter/material.dart';

/// Null represents "unlimited" (session runs until the user stops it).
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
  });

  static const List<int?> options = [5, 7, 15, null];

  final int? selectedMinutes;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final minutes in options)
          ChoiceChip(
            label: Text(minutes == null ? '不限时' : '$minutes 分钟'),
            selected: selectedMinutes == minutes,
            onSelected: (_) => onChanged(minutes),
          ),
      ],
    );
  }
}
