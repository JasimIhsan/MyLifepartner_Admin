import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';

class Country {
  final String name;
  final String code;
  const Country(this.name, this.code);
}

const List<Country> kCountries = [
  Country('India', 'IN'),
  Country('United States', 'US'),
  Country('United Kingdom', 'GB'),
  Country('Canada', 'CA'),
  Country('Australia', 'AU'),
  Country('Germany', 'DE'),
  Country('France', 'FR'),
  Country('Italy', 'IT'),
  Country('Spain', 'ES'),
  Country('Brazil', 'BR'),
];

class CountryPickerSheet extends StatefulWidget {
  final String? selected;
  const CountryPickerSheet({super.key, this.selected});
  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();

  List<Country> _filtered = kCountries;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? kCountries
          : kCountries
                .where((c) => c.name.toLowerCase().contains(q.toLowerCase()))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              // top drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 16),

              // title
              const Text(
                'Select Country',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              // 🔍 search box
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Search your country…',
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 📃 country list
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final country = _filtered[i];
                    final isSelected = country.name == widget.selected;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Row(
                        children: [
                          // 🌍 flag
                          CountryFlag.fromCountryCode(
                            country.code,
                            height: 20,
                            width: 28,
                          ),

                          const SizedBox(width: 12),

                          // country name
                          Expanded(
                            child: Text(
                              country.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ✔ selected indicator
                      trailing: isSelected
                          ? const Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: 20,
                            )
                          : null,

                      // 👉 select
                      onTap: () => Navigator.pop(context, country.name),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
