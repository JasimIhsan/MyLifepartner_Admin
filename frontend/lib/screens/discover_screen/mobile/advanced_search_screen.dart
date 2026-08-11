import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/discovery_filter.dart';
import 'package:life_partner_again/providers/discovery_provider.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  late DiscoveryFilter _filter;
  RangeValues _ageRange = const RangeValues(18, 60);

  final List<String> _maritalOptions = [
    'AWAITING_DIVORCE',
    'DIVORCED',
    'WIDOWED',
    'SEPARATED',
    'NEVER_MARRIED',
  ];

  final List<String> _smokingOptions = [
    'NEVER',
    'OCCASIONALLY',
    'SOCIALLY',
    'REGULARLY',
  ];

  final List<String> _drinkingOptions = [
    'NEVER',
    'OCCASIONALLY',
    'SOCIALLY',
    'REGULARLY',
  ];

  @override
  void initState() {
    super.initState();
    _filter = context.read<DiscoveryProvider>().filter.copyWith();
    if (_filter.ageFrom != null && _filter.ageTo != null) {
      _ageRange = RangeValues(
        _filter.ageFrom!.toDouble(),
        _filter.ageTo!.toDouble(),
      );
    }
  }

  void _applyFilters() {
    _filter.ageFrom = _ageRange.start.round();
    _filter.ageTo = _ageRange.end.round();
    context.read<DiscoveryProvider>().applyFilter(_filter);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _filter = DiscoveryFilter();
      _ageRange = const RangeValues(18, 60);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(
          'Advanced Search',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: Text(
              'Reset',
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Age Range'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_ageRange.start.round()} years'),
                        Text('${_ageRange.end.round()} years'),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 80,
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.2),
                      onChanged: (values) {
                        setState(() {
                          _ageRange = values;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Marital Status'),
                    _buildChips(_maritalOptions, _filter.maritalStatuses, (
                      val,
                    ) {
                      setState(() {
                        if (_filter.maritalStatuses.contains(val)) {
                          _filter.maritalStatuses.remove(val);
                        } else {
                          _filter.maritalStatuses.add(val);
                        }
                      });
                    }),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Smoking Habit'),
                    _buildChips(_smokingOptions, _filter.smokingStatuses, (
                      val,
                    ) {
                      setState(() {
                        if (_filter.smokingStatuses.contains(val)) {
                          _filter.smokingStatuses.remove(val);
                        } else {
                          _filter.smokingStatuses.add(val);
                        }
                      });
                    }),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Drinking Habit'),
                    _buildChips(_drinkingOptions, _filter.drinkingStatuses, (
                      val,
                    ) {
                      setState(() {
                        if (_filter.drinkingStatuses.contains(val)) {
                          _filter.drinkingStatuses.remove(val);
                        } else {
                          _filter.drinkingStatuses.add(val);
                        }
                      });
                    }),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text(
                        'Verified Profiles Only',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      value: _filter.verifiedOnly,
                      activeTrackColor: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
                      activeThumbColor: Theme.of(context).primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _filter.verifiedOnly = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: CustomButton(
                text: 'Apply Filters',
                onPressed: _applyFilters,
                borderRadius: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color:
              Theme.of(context).textTheme.bodyLarge?.color ??
              AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildChips(
    List<String> options,
    List<String> selected,
    Function(String) onTap,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected.contains(opt);
        return ChoiceChip(
          label: Text(
            opt.replaceAll('_', ' '),
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).textTheme.bodyLarge?.color ??
                        AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
          selected: isSelected,
          selectedColor: Theme.of(context).primaryColor,
          backgroundColor: Theme.of(context).colorScheme.surface,
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
          ),
          onSelected: (_) => onTap(opt),
        );
      }).toList(),
    );
  }
}
