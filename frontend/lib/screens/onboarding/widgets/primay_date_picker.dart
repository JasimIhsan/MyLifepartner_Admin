import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';

enum ActiveColumn { day, month, year }

class PrimayDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateChanged;
  final DateTime? minDate;
  final DateTime? maxDate;

  const PrimayDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
    this.minDate,
    this.maxDate,
  });

  @override
  State<PrimayDatePicker> createState() => _PrimayDatePickerState();
}

class _PrimayDatePickerState extends State<PrimayDatePicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  late final DateTime _effectiveMinDate;
  late final DateTime _effectiveMaxDate;

  ActiveColumn _activeColumn = ActiveColumn.year;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();

    _effectiveMinDate = widget.minDate ?? DateTime(1920, 1, 1);
    _effectiveMaxDate = widget.maxDate ?? DateTime.now();

    DateTime baseDate =
        widget.initialDate ??
        DateTime.now().subtract(const Duration(days: 365 * 25));

    if (baseDate.isBefore(_effectiveMinDate)) {
      baseDate = _effectiveMinDate;
    } else if (baseDate.isAfter(_effectiveMaxDate)) {
      baseDate = _effectiveMaxDate;
    }

    _selectedYear = baseDate.year;
    _selectedMonth = baseDate.month;
    _selectedDay = baseDate.day;

    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _effectiveMinDate.year,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  void _updateDate({int? year, int? month, int? day}) {
    int proposedYear = year ?? _selectedYear;
    int proposedMonth = month ?? _selectedMonth;
    int proposedDay = day ?? _selectedDay;

    final maxDays = _getDaysInMonth(proposedYear, proposedMonth);
    if (proposedDay > maxDays) {
      proposedDay = maxDays;
    }

    DateTime proposedDate = DateTime(proposedYear, proposedMonth, proposedDay);

    if (proposedDate.isBefore(_effectiveMinDate)) {
      proposedDate = _effectiveMinDate;
    } else if (proposedDate.isAfter(_effectiveMaxDate)) {
      proposedDate = _effectiveMaxDate;
    }

    setState(() {
      _selectedYear = proposedDate.year;
      _selectedMonth = proposedDate.month;
      _selectedDay = proposedDate.day;
    });

    _syncScrollControllers();
    HapticFeedback.selectionClick();
  }

  void _syncScrollControllers() {
    final yearIndex = _selectedYear - _effectiveMinDate.year;
    final monthIndex = _selectedMonth - 1;
    final dayIndex = _selectedDay - 1;

    if (_yearController.hasClients &&
        _yearController.selectedItem != yearIndex) {
      _yearController.jumpToItem(yearIndex);
    }
    if (_monthController.hasClients &&
        _monthController.selectedItem != monthIndex) {
      _monthController.jumpToItem(monthIndex);
    }
    if (_dayController.hasClients && _dayController.selectedItem != dayIndex) {
      _dayController.jumpToItem(dayIndex);
    }
  }

  void _focusColumn(ActiveColumn column) {
    setState(() {
      _activeColumn = column;
    });
    HapticFeedback.lightImpact();
  }

  Widget _buildDisplayCard({
    required String value,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : (isDark
                            ? const Color(0xFF444444)
                            : Theme.of(context).dividerColor),
                  width: isActive ? 1.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : (isDark
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color ??
                                  AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white60
                    : Theme.of(context).textTheme.bodyMedium?.color ??
                          AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
      ),
      margin: const EdgeInsets.symmetric(vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final dividerColor = isDark
        ? const Color(0xFF2C2C2C)
        : Theme.of(context).dividerColor;

    final totalYears = _effectiveMaxDate.year - _effectiveMinDate.year + 1;
    final totalDays = _getDaysInMonth(_selectedYear, _selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 4.5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF444444) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Cancel, Select Date, Done
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white70
                          : Theme.of(context).textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  "Select Date",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyLarge?.color ??
                              AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final date = DateTime(
                      _selectedYear,
                      _selectedMonth,
                      _selectedDay,
                    );
                    widget.onDateChanged(date);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Done",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Header Display Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildDisplayCard(
                  value: '$_selectedDay',
                  label: 'Day',
                  isActive: _activeColumn == ActiveColumn.day,
                  onTap: () => _focusColumn(ActiveColumn.day),
                ),
                const SizedBox(width: 12),
                _buildDisplayCard(
                  value: _shortMonths[_selectedMonth - 1],
                  label: 'Month',
                  isActive: _activeColumn == ActiveColumn.month,
                  onTap: () => _focusColumn(ActiveColumn.month),
                ),
                const SizedBox(width: 12),
                _buildDisplayCard(
                  value: '$_selectedYear',
                  label: 'Year',
                  isActive: _activeColumn == ActiveColumn.year,
                  onTap: () => _focusColumn(ActiveColumn.year),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Divider
          Divider(color: dividerColor, height: 1, thickness: 1),

          // Column Pickers
          Container(
            height: 220,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Day Column
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _dayController,
                    itemExtent: 44,
                    looping: true,
                    selectionOverlay: _buildSelectionOverlay(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _activeColumn = ActiveColumn.day;
                      });
                      _updateDate(day: index + 1);
                    },
                    children: List.generate(totalDays, (index) {
                      final isSelected = (index + 1) == _selectedDay;
                      return Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: isSelected ? 20 : 16,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? (isDark
                                      ? Colors.white
                                      : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            AppColors.textPrimary)
                                : (isDark
                                      ? Colors.white38
                                      : Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            AppColors.textSecondary.withValues(
                                              alpha: 0.3,
                                            )),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Vertical Divider
                Container(width: 1, height: 160, color: dividerColor),

                // Month Column
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _monthController,
                    itemExtent: 44,
                    looping: true,
                    selectionOverlay: _buildSelectionOverlay(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _activeColumn = ActiveColumn.month;
                      });
                      _updateDate(month: index + 1);
                    },
                    children: List.generate(12, (index) {
                      final isSelected = (index + 1) == _selectedMonth;
                      return Center(
                        child: Text(
                          _months[index],
                          style: TextStyle(
                            fontSize: isSelected ? 20 : 16,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? (isDark
                                      ? Colors.white
                                      : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            AppColors.textPrimary)
                                : (isDark
                                      ? Colors.white38
                                      : Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            AppColors.textSecondary.withValues(
                                              alpha: 0.3,
                                            )),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // Vertical Divider
                Container(width: 1, height: 160, color: dividerColor),

                // Year Column
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearController,
                    itemExtent: 44,
                    looping: false,
                    selectionOverlay: _buildSelectionOverlay(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _activeColumn = ActiveColumn.year;
                      });
                      _updateDate(year: _effectiveMinDate.year + index);
                    },
                    children: List.generate(totalYears, (index) {
                      final year = _effectiveMinDate.year + index;
                      final isSelected = year == _selectedYear;
                      return Center(
                        child: Text(
                          '$year',
                          style: TextStyle(
                            fontSize: isSelected ? 20 : 16,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? (isDark
                                      ? Colors.white
                                      : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color ??
                                            AppColors.textPrimary)
                                : (isDark
                                      ? Colors.white38
                                      : Theme.of(
                                              context,
                                            ).textTheme.bodyMedium?.color ??
                                            AppColors.textSecondary.withValues(
                                              alpha: 0.3,
                                            )),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
