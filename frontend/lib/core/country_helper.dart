class CountryHelper {
  static String? getCode(String? countryName) {
    if (countryName == null || countryName.trim().isEmpty) return null;

    final name = countryName.trim().toLowerCase();

    if (name.contains('india') || name == 'ind') return 'IN';
    if (name.contains('united states') ||
        name.contains('america') ||
        name == 'usa' ||
        name == 'us') {
      return 'US';
    }
    if (name.contains('united kingdom') ||
        name == 'uk' ||
        name.contains('britain')) {
      return 'GB';
    }
    if (name.contains('canada')) return 'CA';
    if (name.contains('australia') || name == 'aus') return 'AU';
    if (name.contains('united arab emirates') ||
        name == 'uae' ||
        name == 'dubai') {
      return 'AE';
    }
    if (name.contains('saudi arabia') || name == 'ksa') return 'SA';
    if (name.contains('pakistan') || name == 'pak') return 'PK';
    if (name.contains('bangladesh') || name == 'bd') return 'BD';
    if (name.contains('sri lanka')) return 'LK';
    if (name.contains('nepal')) return 'NP';
    if (name.contains('malaysia')) return 'MY';
    if (name.contains('singapore')) return 'SG';
    if (name.contains('new zealand') || name == 'nz') return 'NZ';
    if (name.contains('germany')) return 'DE';
    if (name.contains('france')) return 'FR';
    if (name.contains('italy')) return 'IT';
    if (name.contains('spain')) return 'ES';
    if (name.contains('south africa') || name == 'rsa') return 'ZA';

    return null; // Return null if unsupported, we can hide the flag.
  }
}
