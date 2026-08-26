import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/country_helper.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/screens/edit_profile_screen/widgets/edit_profile_controller.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import 'package:life_partner_again/services/job_service.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

class MobileEditProfileScreen extends StatefulWidget {
  final User user;
  const MobileEditProfileScreen({super.key, required this.user});

  @override
  State<MobileEditProfileScreen> createState() =>
      _MobileEditProfileScreenState();
}

class _MobileEditProfileScreenState extends State<MobileEditProfileScreen>
    with EditProfileControllerState<MobileEditProfileScreen> {
  @override
  User get user => widget.user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDiscardBottomSheet(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: theme.canvasColor,
          body: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverAppBar(
                backgroundColor: theme.canvasColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: theme.textTheme.bodyLarge?.color,
                    size: 20,
                  ),
                  onPressed: handleBackPress,
                ),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                actions: [
                  AnimatedOpacity(
                    opacity: isDirty ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: TextButton(
                        onPressed: (isDirty && !isLoading) ? saveProfile : null,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.primaryColor,
                                ),
                              )
                            : Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: theme.primaryColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: isInitialLoading
                    ? SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: theme.primaryColor,
                                strokeWidth: 2.5,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading your profile…',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPhotoHeader(context),
                            const SizedBox(height: 8),
                            _buildSection(
                              context,
                              label: 'PERSONAL DETAILS',
                              icon: Icons.person_outline_rounded,
                              children: [
                                _buildFormField(
                                  context,
                                  label: 'Name',
                                  child: _buildTextInput(
                                    controller: nameController,
                                    hint: 'Your full name',
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'Gender',
                                  child: _buildTapField(
                                    context,
                                    value: gender,
                                    hint: 'Select gender',
                                    onTap: () => _showGenderPicker(context),
                                  ),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'Date of Birth',
                                  child: _buildTapField(
                                    context,
                                    value: dateController.text.isEmpty
                                        ? null
                                        : dateController.text,
                                    hint: 'Select date',
                                    trailingLabel: ageController.text.isEmpty
                                        ? null
                                        : '${ageController.text} yrs',
                                    onTap: selectDateOfBirth,
                                  ),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'Marital Status',
                                  child: _buildTapField(
                                    context,
                                    value: maritalStatus,
                                    hint: 'Select status',
                                    onTap: () =>
                                        _showMaritalStatusPicker(context),
                                  ),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'Children',
                                  isLast: true,
                                  child: _buildTapField(
                                    context,
                                    value: childrenStatus,
                                    hint: 'Select status',
                                    onTap: () =>
                                        _showChildrenStatusPicker(context),
                                  ),
                                ),
                              ],
                            ),
                            _buildSection(
                              context,
                              label: 'ABOUT ME',
                              icon: Icons.auto_awesome_outlined,
                              children: [_buildTextArea(context)],
                            ),
                            _buildSection(
                              context,
                              label: 'EDUCATION & CAREER',
                              icon: Icons.school_outlined,
                              children: [
                                _buildFormField(
                                  context,
                                  label: 'Education',
                                  child: _buildTapField(
                                    context,
                                    value: highestEducation,
                                    hint: 'Select level',
                                    onTap: () => _showEducationPicker(context),
                                  ),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'Profession',
                                  isLast: true,
                                  child: _buildTapField(
                                    context,
                                    value: occupationController.text.isEmpty
                                        ? null
                                        : occupationController.text,
                                    hint: 'Select profession',
                                    onTap: () => _showProfessionPicker(context),
                                  ),
                                ),
                              ],
                            ),
                            _buildSection(
                              context,
                              label: 'LOCATION',
                              icon: Icons.place_outlined,
                              children: [
                                _buildFormField(
                                  context,
                                  label: 'Country',
                                  child: _buildCountryTapField(context),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'State/Province',
                                  child: _buildTextInput(
                                    controller: stateController,
                                    hint: 'Your state or province',
                                  ),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'City',
                                  isLast: true,
                                  child: _buildTextInput(
                                    controller: cityController,
                                    hint: 'Your city',
                                  ),
                                ),
                              ],
                            ),
                            _buildSection(
                              context,
                              label: 'RELATIONSHIP',
                              icon: Icons.favorite_rounded,
                              children: [
                                _buildFormField(
                                  context,
                                  label: 'Looking For',
                                  child: _buildTapField(
                                    context,
                                    value: lookingFor,
                                    hint: 'What are you seeking?',
                                    onTap: () => _showLookingForPicker(context),
                                  ),
                                ),
                                // _buildFormField(
                                //   context,
                                //   label: 'Timeline',
                                //   isLast: true,
                                //   child: _buildTapField(
                                //     context,
                                //     value: relationshipTimeline,
                                //     hint: 'Your timeline',
                                //     onTap: () => _showTimelinePicker(context),
                                //   ),
                                // ),
                              ],
                            ),
                            _buildSection(
                              context,
                              label: 'LIFESTYLE',
                              icon: Icons.self_improvement_outlined,
                              children: [
                                _buildFormField(
                                  context,
                                  label: 'Smoking',
                                  child: _buildTapField(
                                    context,
                                    value: smokingHabit,
                                    hint: 'Smoking habit',
                                    onTap: () => _showSmokingPicker(context),
                                  ),
                                ),
                                _buildFormField(
                                  context,
                                  label: 'Drinking',
                                  isLast: true,
                                  child: _buildTapField(
                                    context,
                                    value: drinkingHabit,
                                    hint: 'Drinking habit',
                                    onTap: () => _showDrinkingPicker(context),
                                  ),
                                ),
                              ],
                            ),
                            _buildSection(
                              context,
                              label: 'LANGUAGES',
                              icon: Icons.translate_rounded,
                              children: [
                                _buildFormField(
                                  context,
                                  label: 'Languages',
                                  isLast: true,
                                  child: _buildLanguagesTapField(context),
                                ),
                              ],
                            ),
                            SizedBox(
                              height:
                                  MediaQuery.of(context).padding.bottom + 40,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
          // bottomNavigationBar: AnimatedContainer(
          //   duration: const Duration(milliseconds: 300),
          //   height: isDirty ? MediaQuery.of(context).padding.bottom + 80 : 0,
          //   child: isDirty
          //       ? Container(
          //           color: theme.scaffoldBackgroundColor,
          //           padding: EdgeInsets.fromLTRB(
          //             20,
          //             12,
          //             20,
          //             MediaQuery.of(context).padding.bottom + 12,
          //           ),
          //           child: SizedBox(
          //             height: 52,
          //             child: ElevatedButton(
          //               onPressed: (isDirty && !isLoading) ? saveProfile : null,
          //               style: ElevatedButton.styleFrom(
          //                 backgroundColor: theme.primaryColor,
          //                 foregroundColor: cs.onPrimary,
          //                 elevation: 0,
          //                 shadowColor: Colors.transparent,
          //                 shape: RoundedRectangleBorder(
          //                   borderRadius: BorderRadius.circular(14),
          //                 ),
          //               ),
          //               child: isLoading
          //                   ? SizedBox(
          //                       width: 22,
          //                       height: 22,
          //                       child: CircularProgressIndicator(
          //                         strokeWidth: 2,
          //                         color: cs.onPrimary,
          //                       ),
          //                     )
          //                   : const Text(
          //                       'Save Changes',
          //                       style: TextStyle(
          //                         fontSize: 16,
          //                         fontWeight: FontWeight.w600,
          //                         letterSpacing: 0.2,
          //                       ),
          //                     ),
          //             ),
          //           ),
          //         )
          //       : const SizedBox.shrink(),
          // ),
        ),
      ),
    );
  }

  Widget _buildPhotoHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: navigateToManagePictures,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.2),
                          theme.primaryColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.25),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: primaryImage != null
                          ? CachedAppImage(
                              imageId: primaryImage!.imageId,
                              presignedImageUrl:
                                  primaryImage!.presignedImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 44,
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                            )
                          : loadingImage
                          ? Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.primaryColor,
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 44,
                                color: theme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                    ),
                  ),
                  // Container(
                  //   width: 30,
                  //   height: 30,
                  //   decoration: BoxDecoration(
                  //     color: theme.primaryColor,
                  //     shape: BoxShape.circle,
                  //     border: Border.all(
                  //       color: theme.scaffoldBackgroundColor,
                  //       width: 2,
                  //     ),
                  //   ),
                  //   child: Icon(
                  //     Icons.camera_alt_rounded,
                  //     color: theme.colorScheme.onPrimary,
                  //     size: 14,
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.user.name ?? '',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.user.email ?? '',
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: navigateToManagePictures,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.primaryColor.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 14,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Manage Photos',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String label,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: theme.primaryColor),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.6,
                    ),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Column(children: children),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFormField(
    BuildContext context, {
    required String label,
    required Widget child,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.6,
            indent: 16,
            endIndent: 0,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
        ),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildTextArea(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(15),
      child: TextFormField(
        controller: bioController,
        minLines: 3,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: theme.textTheme.bodyLarge?.color,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: 'Write a few words about yourself...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
            fontWeight: FontWeight.normal,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 2),
        ),
      ),
    );
  }

  Widget _buildTapField(
    BuildContext context, {
    required String? value,
    required String hint,
    required VoidCallback onTap,
    String? trailingLabel,
  }) {
    final theme = Theme.of(context);
    final hasValue =
        value != null && value.isNotEmpty && !value.startsWith('Select ');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              hasValue ? _formatEnum(value) : hint,
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                color: hasValue
                    ? theme.textTheme.bodyLarge?.color
                    : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailingLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                trailingLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ],
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryTapField(BuildContext context) {
    return _buildTapField(
      context,
      value: country,
      hint: 'Select country',
      onTap: () async {
        final selected = await showModalBottomSheet<String>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _CountryPickerSheet(selected: country),
        );
        if (selected != null) {
          setState(() => country = selected);
          checkIfDirty();
        }
      },
    );
  }

  Widget _buildLanguagesTapField(BuildContext context) {
    final theme = Theme.of(context);
    final hasLanguages = languages.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showLanguagePicker(context),
      child: hasLanguages
          ? Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...languages.map(
                  (lang) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      lang,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.7),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select languages',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.4,
                  ),
                ),
              ],
            ),
    );
  }

  String _formatEnum(String value) {
    if (value.isEmpty || value.startsWith('Select ')) return value;
    const map = {
      'BACHELORS': "Bachelor's Degree",
      'MASTERS': "Master's Degree",
      'DOCTORATE': "Doctorate / PhD",
      'DIPLOMA_CERTIFICATE': "Diploma / Certificate",
      'AWAITING_DIVORCE': "Awaiting Divorce",
      'LIVING_WITH_ME': "Living With Me",
      'NOT_LIVING_WITH_ME': "Not Living With Me",
      'NO_CHILDREN': "No Children",
      'HIGH_SCHOOL': "High School",
      'LONG_TERM_RELATIONSHIP': "Long-term Relationship",
    };
    if (map.containsKey(value)) return map[value]!;
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
        )
        .join(' ');
  }

  void _showBottomPicker(
    String title,
    List<Map<String, dynamic>> options,
    String? currentValue,
    Function(String) onSelect,
  ) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).canvasColor,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options[index];
                  return OnboardingSelectionTile(
                    label: option['label'],
                    value: option['value'],
                    selectedValue: currentValue,
                    icon: option['icon'],
                    onTap: () {
                      onSelect(option['value']);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenderPicker(BuildContext context) {
    _showBottomPicker(
      'Select Gender',
      [
        {'label': 'Male', 'value': 'MALE', 'icon': Icons.male},
        {'label': 'Female', 'value': 'FEMALE', 'icon': Icons.female},
      ],
      gender,
      (val) {
        setState(() => gender = val);
        checkIfDirty();
      },
    );
  }

  void _showMaritalStatusPicker(BuildContext context) {
    _showBottomPicker(
      'Select Marital Status',
      [
        {
          'label': 'Awaiting Divorce',
          'value': 'AWAITING_DIVORCE',
          'icon': Icons.pending_actions,
        },
        {'label': 'Divorced', 'value': 'DIVORCED', 'icon': Icons.call_split},
        {'label': 'Widowed', 'value': 'WIDOWED', 'icon': Icons.favorite_border},
        {
          'label': 'Separated',
          'value': 'SEPARATED',
          'icon': Icons.safety_divider,
        },
      ],
      maritalStatus,
      (val) {
        setState(() => maritalStatus = val);
        checkIfDirty();
      },
    );
  }

  void _showChildrenStatusPicker(BuildContext context) {
    _showBottomPicker(
      'Children Status',
      [
        {
          'label': 'Living with me',
          'value': 'LIVING_WITH_ME',
          'icon': Icons.child_friendly,
        },
        {
          'label': 'Not living with me',
          'value': 'NOT_LIVING_WITH_ME',
          'icon': Icons.child_care,
        },
        {
          'label': 'No children',
          'value': 'NO_CHILDREN',
          'icon': Icons.do_not_disturb_alt,
        },
      ],
      childrenStatus,
      (val) {
        setState(() => childrenStatus = val);
        checkIfDirty();
      },
    );
  }

  void _showEducationPicker(BuildContext context) {
    _showBottomPicker(
      'Highest Education',
      [
        {
          'label': 'High School',
          'value': 'HIGH_SCHOOL',
          'icon': Icons.account_balance_outlined,
        },
        {
          'label': 'Diploma / Certificate',
          'value': 'DIPLOMA_CERTIFICATE',
          'icon': Icons.workspace_premium_outlined,
        },
        {
          'label': "Bachelor's Degree",
          'value': 'BACHELORS',
          'icon': Icons.school_outlined,
        },
        {
          'label': "Master's Degree",
          'value': 'MASTERS',
          'icon': Icons.history_edu_outlined,
        },
        {
          'label': 'Doctorate / PhD',
          'value': 'DOCTORATE',
          'icon': Icons.military_tech_outlined,
        },
        {'label': 'Other', 'value': 'OTHER', 'icon': Icons.more_horiz_outlined},
      ],
      highestEducation,
      (val) {
        setState(() => highestEducation = val);
        checkIfDirty();
      },
    );
  }

  void _showLookingForPicker(BuildContext context) {
    _showBottomPicker(
      'Looking For',
      [
        {'label': 'Marriage', 'value': 'MARRIAGE', 'icon': Icons.favorite},
        {
          'label': 'Long-term relationship',
          'value': 'LONG_TERM_RELATIONSHIP',
          'icon': Icons.favorite_border,
        },
      ],
      lookingFor,
      (val) {
        setState(() => lookingFor = val);
        checkIfDirty();
      },
    );
  }

  void _showSmokingPicker(BuildContext context) {
    _showBottomPicker(
      'Smoking Habit',
      [
        {'label': 'Never', 'value': 'NEVER', 'icon': Icons.smoke_free},
        {
          'label': 'Occasionally',
          'value': 'OCCASIONALLY',
          'icon': Icons.smoking_rooms,
        },
        {'label': 'Socially', 'value': 'SOCIALLY', 'icon': Icons.groups},
        {
          'label': 'Regularly',
          'value': 'REGULARLY',
          'icon': Icons.smoking_rooms,
        },
      ],
      smokingHabit,
      (val) {
        setState(() => smokingHabit = val);
        checkIfDirty();
      },
    );
  }

  void _showDrinkingPicker(BuildContext context) {
    _showBottomPicker(
      'Drinking Habit',
      [
        {'label': 'Never', 'value': 'NEVER', 'icon': Icons.no_drinks},
        {
          'label': 'Occasionally',
          'value': 'OCCASIONALLY',
          'icon': Icons.local_bar,
        },
        {'label': 'Socially', 'value': 'SOCIALLY', 'icon': Icons.groups},
        {'label': 'Regularly', 'value': 'REGULARLY', 'icon': Icons.wine_bar},
      ],
      drinkingHabit,
      (val) {
        setState(() => drinkingHabit = val);
        checkIfDirty();
      },
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final commonLanguages = [
      'Arabic',
      'Bengali',
      'Cantonese',
      'Dutch',
      'English',
      'French',
      'German',
      'Greek',
      'Gujarati',
      'Hindi',
      'Indonesian',
      'Italian',
      'Japanese',
      'Kannada',
      'Korean',
      'Malay',
      'Malayalam',
      'Mandarin Chinese',
      'Marathi',
      'Odia',
      'Persian',
      'Polish',
      'Portuguese',
      'Punjabi',
      'Romanian',
      'Russian',
      'Spanish',
      'Swahili',
      'Tagalog',
      'Tamil',
      'Telugu',
      'Thai',
      'Turkish',
      'Ukrainian',
      'Urdu',
      'Vietnamese',
    ]..sort();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) => Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spoken Languages',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: theme.textTheme.titleLarge?.color,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (languages.isNotEmpty)
                          Text(
                            '${languages.length} selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                      ),
                      child: const Text(
                        'Done',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonLanguages.map((lang) {
                        final isSelected = languages.contains(lang);
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              if (isSelected) {
                                languages.remove(lang);
                              } else {
                                languages.add(lang);
                              }
                            });
                            setState(() {});
                            checkIfDirty();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor.withValues(alpha: 0.12)
                                  : theme.colorScheme.surface,
                              border: Border.all(
                                color: isSelected
                                    ? theme.primaryColor.withValues(alpha: 0.6)
                                    : theme.dividerColor.withValues(alpha: 0.7),
                                width: isSelected ? 1.5 : 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lang,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? theme.primaryColor
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfessionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfessionPickerSheet(
        initialValue: occupationController.text,
        onSelect: (val) {
          setState(() {
            occupationController.text = val;
          });
          checkIfDirty();
        },
      ),
    );
  }
}

// ── Country Picker Sheet ──────────────────────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final String? selected;
  const _CountryPickerSheet({this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<String> _filtered = _kCountries;

  void _onSearch(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _kCountries
          : _kCountries
                .where((c) => c.toLowerCase().contains(q.toLowerCase()))
                .toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.canvasColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Country',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: _onSearch,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search country...',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: theme.dividerColor,
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final c = _filtered[i];
                  final isSelected = c == widget.selected;
                  final code = CountryHelper.getCode(c);
                  return ListTile(
                    leading: code != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CountryFlag.fromCountryCode(
                              code,
                              height: 18,
                              width: 24,
                            ),
                          )
                        : const Icon(Icons.public_rounded, size: 20),
                    title: Text(
                      c,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? theme.primaryColor
                            : theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            color: theme.primaryColor,
                            size: 18,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, c),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profession Picker Sheet ───────────────────────────────────────────────────

class _ProfessionPickerSheet extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onSelect;
  const _ProfessionPickerSheet({
    required this.initialValue,
    required this.onSelect,
  });

  @override
  State<_ProfessionPickerSheet> createState() => _ProfessionPickerSheetState();
}

class _ProfessionPickerSheetState extends State<_ProfessionPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _jobs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchJobs('');
  }

  Future<void> _fetchJobs(String query) async {
    setState(() => _isLoading = true);
    try {
      final jobs = await JobService.searchJobs(query);
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Profession',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: _fetchJobs,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search profession...',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: theme.dividerColor,
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : _jobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.work_off_outlined,
                            color: theme.dividerColor,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No results found',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollCtrl,
                      itemCount: _jobs.length,
                      itemBuilder: (_, i) {
                        final job = _jobs[i];
                        return ListTile(
                          title: Text(
                            job.name,
                            style: const TextStyle(fontSize: 15),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          dense: true,
                          onTap: () {
                            widget.onSelect(job.name);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            if (_searchController.text.trim().isNotEmpty) ...[
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Add "${_searchController.text.trim()}"'),
                  onPressed: () {
                    widget.onSelect(_searchController.text.trim());
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(
                      color: theme.primaryColor.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Countries ─────────────────────────────────────────────────────────────────

const List<String> _kCountries = [
  'Afghanistan',
  'Albania',
  'Algeria',
  'Andorra',
  'Angola',
  'Antigua and Barbuda',
  'Argentina',
  'Armenia',
  'Australia',
  'Austria',
  'Azerbaijan',
  'Bahamas',
  'Bahrain',
  'Bangladesh',
  'Barbados',
  'Belarus',
  'Belgium',
  'Belize',
  'Benin',
  'Bhutan',
  'Bolivia',
  'Bosnia and Herzegovina',
  'Botswana',
  'Brazil',
  'Brunei',
  'Bulgaria',
  'Burkina Faso',
  'Burundi',
  'Cabo Verde',
  'Cambodia',
  'Cameroon',
  'Canada',
  'Central African Republic',
  'Chad',
  'Chile',
  'China',
  'Colombia',
  'Comoros',
  'Congo',
  'Costa Rica',
  'Croatia',
  'Cuba',
  'Cyprus',
  'Czech Republic',
  'Denmark',
  'Djibouti',
  'Dominica',
  'Dominican Republic',
  'Ecuador',
  'Egypt',
  'El Salvador',
  'Equatorial Guinea',
  'Eritrea',
  'Estonia',
  'Eswatini',
  'Ethiopia',
  'Fiji',
  'Finland',
  'France',
  'Gabon',
  'Gambia',
  'Georgia',
  'Germany',
  'Ghana',
  'Greece',
  'Grenada',
  'Guatemala',
  'Guinea',
  'Guinea-Bissau',
  'Guyana',
  'Haiti',
  'Honduras',
  'Hungary',
  'Iceland',
  'India',
  'Indonesia',
  'Iran',
  'Iraq',
  'Ireland',
  'Israel',
  'Italy',
  'Jamaica',
  'Japan',
  'Jordan',
  'Kazakhstan',
  'Kenya',
  'Kiribati',
  'Kuwait',
  'Kyrgyzstan',
  'Laos',
  'Latvia',
  'Lebanon',
  'Lesotho',
  'Liberia',
  'Libya',
  'Liechtenstein',
  'Lithuania',
  'Luxembourg',
  'Madagascar',
  'Malawi',
  'Malaysia',
  'Maldives',
  'Mali',
  'Malta',
  'Marshall Islands',
  'Mauritania',
  'Mauritius',
  'Mexico',
  'Micronesia',
  'Moldova',
  'Monaco',
  'Mongolia',
  'Montenegro',
  'Morocco',
  'Mozambique',
  'Myanmar',
  'Namibia',
  'Nauru',
  'Nepal',
  'Netherlands',
  'New Zealand',
  'Nicaragua',
  'Niger',
  'Nigeria',
  'North Korea',
  'North Macedonia',
  'Norway',
  'Oman',
  'Pakistan',
  'Palau',
  'Palestine',
  'Panama',
  'Papua New Guinea',
  'Paraguay',
  'Peru',
  'Philippines',
  'Poland',
  'Portugal',
  'Qatar',
  'Romania',
  'Russia',
  'Rwanda',
  'Saint Kitts and Nevis',
  'Saint Lucia',
  'Saint Vincent and the Grenadines',
  'Samoa',
  'San Marino',
  'Sao Tome and Principe',
  'Saudi Arabia',
  'Senegal',
  'Serbia',
  'Seychelles',
  'Sierra Leone',
  'Singapore',
  'Slovakia',
  'Slovenia',
  'Solomon Islands',
  'Somalia',
  'South Africa',
  'South Korea',
  'South Sudan',
  'Spain',
  'Sri Lanka',
  'Sudan',
  'Suriname',
  'Sweden',
  'Switzerland',
  'Syria',
  'Taiwan',
  'Tajikistan',
  'Tanzania',
  'Thailand',
  'Timor-Leste',
  'Togo',
  'Tonga',
  'Trinidad and Tobago',
  'Tunisia',
  'Turkey',
  'Turkmenistan',
  'Tuvalu',
  'Uganda',
  'Ukraine',
  'United Arab Emirates',
  'United Kingdom',
  'United States',
  'Uruguay',
  'Uzbekistan',
  'Vanuatu',
  'Venezuela',
  'Vietnam',
  'Yemen',
  'Zambia',
  'Zimbabwe',
];
