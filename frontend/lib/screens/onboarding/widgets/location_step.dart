import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/location_prediction.dart';
import 'package:life_partner_again/providers/location_provider.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import 'package:life_partner_again/screens/onboarding/widgets/searchable_location_selector.dart';
import 'package:life_partner_again/services/location_service.dart';
import 'package:provider/provider.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locProvider = context.read<LocationProvider>();
      if (!locProvider.hasAttemptedInitialLocationDetection &&
          locProvider.selectedCountry == null) {
        locProvider.detectAndFillCurrentLocation();
      }
    });
  }

  void _showSelector({
    required BuildContext context,
    required String title,
    required String hint,
    required bool Function(LocationProvider) getIsSearching,
    required List<LocationPrediction> Function(LocationProvider) getSuggestions,
    required Function(String) onSearch,
    required Function(LocationPrediction) onSelect,
    VoidCallback? onClear,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer<LocationProvider>(
        builder: (context, provider, _) {
          return SearchableLocationSelector(
            title: title,
            hint: hint,
            isSearching: getIsSearching(provider),
            suggestions: List.from(getSuggestions(provider)),
            onSearch: onSearch,
            onSelect: (val) {
              onSelect(val);
              Navigator.pop(context);
            },
            onClear: onClear,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locProvider, _) {
        return Column(
          children: [
            const OnboardingStepTitle(title: "Where do you live?"),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: Image.asset(
                'assets/images/onboarding/location.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),

            // Current Location Action
            _buildCurrentLocationAction(locProvider),
            const SizedBox(height: 20),

            // Country Field
            const OnboardingSectionLabel(text: "Country"),
            _buildSelectorField(
              hint: 'Select your country',
              value: locProvider.selectedCountry?.name,
              errorText: locProvider.countryError,
              onTap: () {
                _showSelector(
                  context: context,
                  title: 'Select Country',
                  hint: 'Search country...',
                  getIsSearching: (p) => p.isSearchingCountry,
                  getSuggestions: (p) => p.countrySuggestions,
                  onSearch: locProvider.searchCountry,
                  onSelect: locProvider.selectCountry,
                  onClear: locProvider.invalidateCountry,
                );
              },
            ),

            // State Field
            const SizedBox(height: 10),
            const OnboardingSectionLabel(text: "State"),
            _buildSelectorField(
              hint: 'Select your state',
              value: locProvider.selectedState?.name,
              errorText: locProvider.stateError,
              enabled: locProvider.selectedCountry != null,
              onTap: () {
                if (locProvider.selectedCountry == null) return;
                _showSelector(
                  context: context,
                  title: 'Select State',
                  hint: 'Search state...',
                  getIsSearching: (p) => p.isSearchingState,
                  getSuggestions: (p) => p.stateSuggestions,
                  onSearch: locProvider.searchState,
                  onSelect: locProvider.selectState,
                  onClear: locProvider.invalidateState,
                );
              },
            ),

            // City Field
            const SizedBox(height: 10),
            const OnboardingSectionLabel(text: "City"),
            _buildSelectorField(
              hint: 'Select your city',
              value: locProvider.selectedCity?.name,
              errorText: locProvider.cityError,
              enabled: locProvider.selectedState != null,
              onTap: () {
                if (locProvider.selectedState == null) return;
                _showSelector(
                  context: context,
                  title: 'Select City',
                  hint: 'Search city...',
                  getIsSearching: (p) => p.isSearchingCity,
                  getSuggestions: (p) => p.citySuggestions,
                  onSearch: locProvider.searchCity,
                  onSelect: locProvider.selectCity,
                  onClear: locProvider.invalidateCity,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentLocationAction(LocationProvider provider) {
    if (provider.currentLocationStatus ==
            CurrentLocationStatus.fetchingCoordinates ||
        provider.currentLocationStatus ==
            CurrentLocationStatus.reverseGeocoding ||
        provider.currentLocationStatus ==
            CurrentLocationStatus.checkingPermission) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: 8),
          Text(
            "Detecting location...",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        TextButton.icon(
          onPressed: () =>
              provider.detectAndFillCurrentLocation(forceReplace: true),
          icon: Icon(
            Icons.my_location,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          label: Text(
            "Use current location",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (provider.currentLocationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              provider.currentLocationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSelectorField({
    required String hint,
    String? value,
    String? errorText,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: enabled ? Colors.white : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: errorText != null ? Colors.red : const Color(0xFFF0E6E6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null
                          ? Theme.of(context).textTheme.bodyLarge?.color ??
                                AppColors.textPrimary
                          : Theme.of(context).textTheme.bodyMedium?.color ??
                                AppColors.textSecondary,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: enabled
                      ? Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary
                      : Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 16),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
