import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';

class PrimayDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime> onDateChanged;

  const PrimayDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
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

  final int _startYear = 1920;
  late final int _endYear;

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

  @override
  void initState() {
    super.initState();
    _endYear = DateTime.now().year;

    final baseDate =
        widget.initialDate ??
        DateTime.now().subtract(const Duration(days: 365 * 25));
    _selectedYear = baseDate.year;
    _selectedMonth = baseDate.month;
    _selectedDay = baseDate.day;

    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _startYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _dayController = FixedExtentScrollController(initialItem: _selectedDay - 1);

    if (widget.initialDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDateChanged(baseDate);
      });
    }
  }

  @override
  void didUpdateWidget(covariant PrimayDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != null) {
      final newDate = widget.initialDate!;
      if (newDate.year != _selectedYear ||
          newDate.month != _selectedMonth ||
          newDate.day != _selectedDay) {
        setState(() {
          _selectedYear = newDate.year;
          _selectedMonth = newDate.month;

          final maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);
          _selectedDay = newDate.day.clamp(1, maxDays);

          if (_yearController.hasClients) {
            _yearController.jumpToItem(_selectedYear - _startYear);
          }
          if (_monthController.hasClients) {
            _monthController.jumpToItem(_selectedMonth - 1);
          }
          if (_dayController.hasClients) {
            _dayController.jumpToItem(_selectedDay - 1);
          }
        });
      }
    }
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
    setState(() {
      int proposedYear = year ?? _selectedYear;
      int proposedMonth = month ?? _selectedMonth;
      int proposedDay = day ?? _selectedDay;

      // First clamp proposedDay to max days of the proposed month/year
      final maxDaysProposed = _getDaysInMonth(proposedYear, proposedMonth);
      proposedDay = proposedDay.clamp(1, maxDaysProposed);

      // Prevent choosing future dates relative to today
      final now = DateTime.now();
      if (proposedYear >= now.year) {
        proposedYear = now.year;
        if (proposedMonth >= now.month) {
          proposedMonth = now.month;
          if (proposedDay > now.day) {
            proposedDay = now.day;
          }
        }
      }

      _selectedYear = proposedYear;
      _selectedMonth = proposedMonth;
      _selectedDay = proposedDay;

      // Sync and animate wheel scroll controllers to current/clamped positions
      if (_yearController.hasClients) {
        final targetIndex = _selectedYear - _startYear;
        if (_yearController.selectedItem != targetIndex) {
          _yearController.animateToItem(
            targetIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
      if (_monthController.hasClients) {
        final targetIndex = _selectedMonth - 1;
        if (_monthController.selectedItem != targetIndex) {
          _monthController.animateToItem(
            targetIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
      if (_dayController.hasClients) {
        final targetIndex = _selectedDay - 1;
        if (_dayController.selectedItem != targetIndex) {
          _dayController.animateToItem(
            targetIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });

    final date = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    widget.onDateChanged(date);
    HapticFeedback.selectionClick();

    // Auto-scroll to the bottom of the ancestor scrollable to make age validation visible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final scrollable = Scrollable.maybeOf(context);
        if (scrollable != null) {
          scrollable.position.animateTo(
            scrollable.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxDays = _getDaysInMonth(_selectedYear, _selectedMonth);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content clipped to rounded corners
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CupertinoPicker(
                          scrollController: _monthController,
                          itemExtent: 44,
                          magnification: 1.1,
                          squeeze: 1.25,
                          diameterRatio: 1.5,
                          selectionOverlay: _buildSelectionOverlay(),
                          onSelectedItemChanged: (index) {
                            _updateDate(month: index + 1);
                          },
                          children: List.generate(_months.length, (index) {
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
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: CupertinoPicker(
                          scrollController: _dayController,
                          itemExtent: 44,
                          magnification: 1.1,
                          squeeze: 1.25,
                          diameterRatio: 1.5,
                          selectionOverlay: _buildSelectionOverlay(),
                          onSelectedItemChanged: (index) {
                            _updateDate(day: index + 1);
                          },
                          children: List.generate(maxDays, (index) {
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
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: CupertinoPicker(
                          scrollController: _yearController,
                          itemExtent: 44,
                          magnification: 1.1,
                          squeeze: 1.25,
                          diameterRatio: 1.5,
                          selectionOverlay: _buildSelectionOverlay(),
                          onSelectedItemChanged: (index) {
                            _updateDate(year: _startYear + index);
                          },
                          children: List.generate((_endYear - _startYear) + 1, (
                            index,
                          ) {
                            final year = _startYear + index;
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
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.white,
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top-level border overlay to ensure rounded corners are visible and not hidden
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderColor, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      margin: const EdgeInsets.symmetric(vertical: 2),
    );
  }
}
