import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/country_helper.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/screens/edit_profile_screen/web/widgets/web_edit_profile_components.dart';
import 'package:life_partner_again/screens/edit_profile_screen/web/widgets/web_edit_profile_dialogs.dart';
import 'package:life_partner_again/screens/edit_profile_screen/widgets/edit_profile_controller.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

class WebEditProfileScreen extends StatefulWidget {
  final User user;

  const WebEditProfileScreen({super.key, required this.user});

  @override
  State<WebEditProfileScreen> createState() => _WebEditProfileScreenState();
}

class _WebEditProfileScreenState extends State<WebEditProfileScreen>
    with EditProfileControllerState<WebEditProfileScreen> {
  @override
  User get user => widget.user;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _basicInfoKey = GlobalKey();
  final GlobalKey _aboutMeKey = GlobalKey();
  final GlobalKey _educationCareerKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _familyKey = GlobalKey();
  final GlobalKey _lifestyleKey = GlobalKey();
  final GlobalKey _languagesKey = GlobalKey();

  int _selectedNavIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key, int index) {
    setState(() => _selectedNavIndex = index);
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  Future<void> _handleWebBackPress() async {
    if (!isDirty) {
      context.pop();
    } else {
      final shouldDiscard = await WebDiscardDialog.show(context);
      if (shouldDiscard == true && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleWebBackPress();
      },
      child: Scaffold(
        backgroundColor: theme.canvasColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1024;
            return Column(
              children: [
                if (!isWide) _buildTopAppBar(context),
                Expanded(
                  child: isInitialLoading
                      ? _buildInitialLoadingState(context)
                      : (isWide)
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 340,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.only(
                                  left: 32,
                                  top: 28,
                                  bottom: 28,
                                ),
                                child: _buildLeftSidebar(context, isWide: true),
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                padding: const EdgeInsets.only(
                                  right: 32,
                                  top: 28,
                                  bottom: 28,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 860,
                                  ),
                                  child: Form(
                                    key: formKey,
                                    child: _buildFormSections(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 28,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Form(
                                key: formKey,
                                child: Column(
                                  children: [
                                    _buildLeftSidebar(context, isWide: false),
                                    const SizedBox(height: 24),
                                    _buildFormSections(context),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Top App Bar ────────────────────────────────────────────────────────────

  Widget _buildTopAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button & Breadcrumb
          InkWell(
            onTap: _handleWebBackPress,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.8),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Text(
                'Update your personal information, lifestyle, and preferences',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Unsaved Changes Status Badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDirty
                  ? Colors.amber.withValues(alpha: 0.12)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDirty
                    ? Colors.amber.withValues(alpha: 0.4)
                    : Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDirty ? Colors.amber[700] : Colors.green[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isDirty ? 'Unsaved Changes' : 'Saved & Up to Date',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDirty ? Colors.amber[900] : Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Discard Button
          if (isDirty) ...[
            OutlinedButton(
              onPressed: _handleWebBackPress,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                side: BorderSide(color: theme.dividerColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Discard'),
            ),
            const SizedBox(width: 12),
          ],

          // Save Changes Primary Button
          ElevatedButton.icon(
            onPressed: (isDirty && !isLoading) ? saveProfile : null,
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: Text(
              isLoading ? 'Saving Changes…' : 'Save Changes',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.primaryColor.withValues(
                alpha: 0.4,
              ),
              disabledForegroundColor: theme.colorScheme.onPrimary.withValues(
                alpha: 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Initial Loading State ──────────────────────────────────────────────────

  Widget _buildInitialLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 3),
          const SizedBox(height: 18),
          Text(
            'Loading your profile details…',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Left Sidebar (Profile Overview & Navigation) ───────────────────────────

  Widget _buildLeftSidebar(BuildContext context, {bool isWide = false}) {
    final theme = Theme.of(context);

    final navItems = [
      {'title': 'Basic Information', 'icon': Icons.person_outline_rounded},
      {'title': 'About Me', 'icon': Icons.auto_awesome_outlined},
      {'title': 'Education & Career', 'icon': Icons.school_outlined},
      {'title': 'Location Settings', 'icon': Icons.location_on_outlined},
      {
        'title': 'Family & Marital Status',
        'icon': Icons.favorite_outline_rounded,
      },
      {
        'title': 'Lifestyle & Intentions',
        'icon': Icons.self_improvement_outlined,
      },
      {'title': 'Spoken Languages', 'icon': Icons.translate_rounded},
    ];

    final navKeys = [
      _basicInfoKey,
      _aboutMeKey,
      _educationCareerKey,
      _locationKey,
      _familyKey,
      _lifestyleKey,
      _languagesKey,
    ];

    return Column(
      children: [
        // Profile Avatar Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: navigateToManagePictures,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor.withValues(alpha: 0.25),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: primaryImage != null
                            ? CachedAppImage(
                                imageId: primaryImage!.imageId,
                                presignedImageUrl:
                                    primaryImage!.presignedImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: theme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              )
                            : loadingImage
                            ? Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.primaryColor,
                                ),
                              )
                            : Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: theme.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.surface,
                          width: 2.5,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.user.name ?? 'Your Name',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.user.email ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: navigateToManagePictures,
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text(
                    'Manage Photos',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(
                      color: theme.primaryColor.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isWide) ...[
          const SizedBox(height: 20),
          // Section Anchor Navigator Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.6),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Text(
                    'SECTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodySmall?.color,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                ...List.generate(navItems.length, (idx) {
                  final item = navItems[idx];
                  final isSelected = _selectedNavIndex == idx;

                  return InkWell(
                    onTap: () => _scrollToSection(navKeys[idx], idx),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primaryColor.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 18,
                            color: isSelected
                                ? theme.primaryColor
                                : theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? theme.primaryColor
                                    : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        // ),
        if (isWide) ...[
          const SizedBox(height: 24),
          _buildStickyActions(context),
        ],
      ],
    );
  }

  Widget _buildStickyActions(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedOpacity(
      opacity: isDirty ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isDirty && !isLoading) ? saveProfile : null,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isLoading ? 'Saving...' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: (isDirty && !isLoading) ? _handleWebBackPress : null,
              style: TextButton.styleFrom(
                foregroundColor: theme.textTheme.bodyLarge?.color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Discard Changes',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Right Form Sections ────────────────────────────────────────────────────

  Widget _buildFormSections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Basic Information Card
        Container(
          key: _basicInfoKey,
          child: WebSectionCard(
            title: 'Basic Information',
            subtitle: 'Manage your name, gender, and date of birth',
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                // Name Field
                WebFormFieldContainer(
                  label: 'Full Name',
                  isRequired: true,
                  helperText:
                      'Your name will be visible to your prospective matches',
                  child: WebTextInput(
                    controller: nameController,
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.badge_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Gender Field
                WebFormFieldContainer(
                  label: 'Gender',
                  helperText: 'Select your biological gender',
                  child: WebOptionSelectorGroup(
                    options: const [
                      {
                        'label': 'Male',
                        'value': 'MALE',
                        'icon': Icons.male_rounded,
                      },
                      {
                        'label': 'Female',
                        'value': 'FEMALE',
                        'icon': Icons.female_rounded,
                      },
                    ],
                    selectedValue: gender,
                    onSelected: (val) {
                      setState(() => gender = val);
                      checkIfDirty();
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Date of Birth & Calculated Age Grid
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: WebFormFieldContainer(
                            label: 'Date of Birth',
                            helperText: 'Must be at least 18 years old',
                            child: WebClickablePickerField(
                              value: dateController.text.isNotEmpty
                                  ? dateController.text
                                  : null,
                              hintText: 'Select your birth date',
                              prefixIcon: Icons.calendar_today_outlined,
                              onTap: selectDateOfBirth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: WebFormFieldContainer(
                            label: 'Calculated Age',
                            helperText: 'Auto-calculated from birth date',
                            child: WebTextInput(
                              controller: ageController,
                              hintText: '--',
                              readOnly: true,
                              prefixIcon: Icons.cake_outlined,
                              suffixIcon: ageController.text.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: Center(
                                        widthFactor: 1,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'years old',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(
                                                context,
                                              ).primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 50.ms),

        // 2. About Me Card
        Container(
          key: _aboutMeKey,
          child: WebSectionCard(
            title: 'About Me',
            subtitle:
                'Express your story, personality, values, and relationship expectations',
            icon: Icons.auto_awesome_outlined,
            child: WebFormFieldContainer(
              label: 'Bio & Self Description',
              helperText:
                  'Write a few paragraphs about what makes you unique and what kind of life partner you are looking for',
              child: WebTextInput(
                controller: bioController,
                hintText:
                    'Share your story, values, passions, and relationship goals...',
                minLines: 4,
                maxLines: 8,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
        ).animate().fadeIn(delay: 100.ms),

        // 3. Education & Career Card
        Container(
          key: _educationCareerKey,
          child: WebSectionCard(
            title: 'Education & Career',
            subtitle:
                'Provide your educational qualifications and current profession',
            icon: Icons.school_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Highest Education
                WebFormFieldContainer(
                  label: 'Highest Education Level',
                  helperText:
                      'Select the highest degree or credential you have completed',
                  child: WebOptionSelectorGroup(
                    options: const [
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
                      {
                        'label': 'Other',
                        'value': 'OTHER',
                        'icon': Icons.more_horiz_outlined,
                      },
                    ],
                    selectedValue: highestEducation,
                    onSelected: (val) {
                      setState(() => highestEducation = val);
                      checkIfDirty();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Profession / Career
                WebFormFieldContainer(
                  label: 'Profession / Job Title',
                  helperText: 'Search or specify your current profession',
                  child: WebClickablePickerField(
                    value: occupationController.text.isNotEmpty
                        ? occupationController.text
                        : null,
                    hintText: 'Click to search or enter profession',
                    prefixIcon: Icons.work_outline_rounded,
                    onTap: () async {
                      final selected = await WebProfessionPickerDialog.show(
                        context,
                        initialValue: occupationController.text,
                      );
                      if (selected != null) {
                        setState(() {
                          occupationController.text = selected;
                        });
                        checkIfDirty();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 150.ms),

        // 4. Location Card
        Container(
          key: _locationKey,
          child: WebSectionCard(
            title: 'Location Settings',
            subtitle: 'Set your country of residence and city',
            icon: Icons.location_on_outlined,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country
                Expanded(
                  flex: 3,
                  child: WebFormFieldContainer(
                    label: 'Country of Residence',
                    isRequired: true,
                    helperText: 'Select your country',
                    child: WebClickablePickerField(
                      value: country,
                      hintText: 'Select your country',
                      prefixIcon: Icons.public_rounded,
                      customLeading:
                          country != null &&
                              CountryHelper.getCode(country) != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: CountryFlag.fromCountryCode(
                                CountryHelper.getCode(country)!,
                                height: 18,
                                width: 24,
                              ),
                            )
                          : null,
                      onTap: () async {
                        final selected = await WebCountryPickerDialog.show(
                          context,
                          selected: country,
                        );
                        if (selected != null) {
                          setState(() => country = selected);
                          checkIfDirty();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // State/Province
                Expanded(
                  flex: 2,
                  child: WebFormFieldContainer(
                    label: 'State/Province',
                    helperText: 'Your state or province',
                    child: WebTextInput(
                      controller: stateController,
                      hintText: 'State',
                      prefixIcon: Icons.map_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // City
                Expanded(
                  flex: 2,
                  child: WebFormFieldContainer(
                    label: 'City',
                    helperText: 'Your current city or region',
                    child: WebTextInput(
                      controller: cityController,
                      hintText: 'Enter your city name',
                      prefixIcon: Icons.location_city_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms),

        // 5. Family & Marital Status Card
        Container(
          key: _familyKey,
          child: WebSectionCard(
            title: 'Family & Marital Status',
            subtitle:
                'Clarify your current marital standing and children details',
            icon: Icons.favorite_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Marital Status
                WebFormFieldContainer(
                  label: 'Marital Status',
                  helperText: 'Your current marital situation',
                  child: WebOptionSelectorGroup(
                    options: const [
                      {
                        'label': 'Awaiting Divorce',
                        'value': 'AWAITING_DIVORCE',
                        'icon': Icons.pending_actions_rounded,
                      },
                      {
                        'label': 'Divorced',
                        'value': 'DIVORCED',
                        'icon': Icons.call_split_rounded,
                      },
                      {
                        'label': 'Widowed',
                        'value': 'WIDOWED',
                        'icon': Icons.favorite_border_rounded,
                      },
                      {
                        'label': 'Separated',
                        'value': 'SEPARATED',
                        'icon': Icons.safety_divider_rounded,
                      },
                    ],
                    selectedValue: maritalStatus,
                    onSelected: (val) {
                      setState(() => maritalStatus = val);
                      checkIfDirty();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Children Status
                WebFormFieldContainer(
                  label: 'Children Status',
                  helperText:
                      'Do you have children, and do they live with you?',
                  child: WebOptionSelectorGroup(
                    options: const [
                      {
                        'label': 'Living with me',
                        'value': 'LIVING_WITH_ME',
                        'icon': Icons.child_friendly_rounded,
                      },
                      {
                        'label': 'Not living with me',
                        'value': 'NOT_LIVING_WITH_ME',
                        'icon': Icons.child_care_rounded,
                      },
                      {
                        'label': 'No children',
                        'value': 'NO_CHILDREN',
                        'icon': Icons.do_not_disturb_alt_rounded,
                      },
                    ],
                    selectedValue: childrenStatus,
                    onSelected: (val) {
                      setState(() => childrenStatus = val);
                      checkIfDirty();
                    },
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 250.ms),

        // 6. Lifestyle & Intentions Card
        Container(
          key: _lifestyleKey,
          child: WebSectionCard(
            title: 'Lifestyle & Intentions',
            subtitle: 'Specify your partner search goal and personal habits',
            icon: Icons.self_improvement_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Looking For
                WebFormFieldContainer(
                  label: 'Looking For / Relationship Goal',
                  helperText:
                      'What kind of connection are you seeking on Life Partner Again?',
                  child: WebOptionSelectorGroup(
                    options: const [
                      {
                        'label': 'Marriage',
                        'value': 'MARRIAGE',
                        'icon': Icons.favorite_rounded,
                      },
                      {
                        'label': 'Long-term relationship',
                        'value': 'LONG_TERM_RELATIONSHIP',
                        'icon': Icons.volunteer_activism_rounded,
                      },
                    ],
                    selectedValue: lookingFor,
                    onSelected: (val) {
                      setState(() => lookingFor = val);
                      checkIfDirty();
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Smoking & Drinking Grid
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Smoking
                    Expanded(
                      child: WebFormFieldContainer(
                        label: 'Smoking Habit',
                        child: WebOptionSelectorGroup(
                          options: const [
                            {
                              'label': 'Never',
                              'value': 'NEVER',
                              'icon': Icons.smoke_free_rounded,
                            },
                            {
                              'label': 'Occasionally',
                              'value': 'OCCASIONALLY',
                              'icon': Icons.smoking_rooms_rounded,
                            },
                            {
                              'label': 'Socially',
                              'value': 'SOCIALLY',
                              'icon': Icons.groups_rounded,
                            },
                            {
                              'label': 'Regularly',
                              'value': 'REGULARLY',
                              'icon': Icons.smoking_rooms_rounded,
                            },
                          ],
                          selectedValue: smokingHabit,
                          onSelected: (val) {
                            setState(() => smokingHabit = val);
                            checkIfDirty();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Drinking
                    Expanded(
                      child: WebFormFieldContainer(
                        label: 'Drinking Habit',
                        child: WebOptionSelectorGroup(
                          options: const [
                            {
                              'label': 'Never',
                              'value': 'NEVER',
                              'icon': Icons.no_drinks_rounded,
                            },
                            {
                              'label': 'Occasionally',
                              'value': 'OCCASIONALLY',
                              'icon': Icons.local_bar_rounded,
                            },
                            {
                              'label': 'Socially',
                              'value': 'SOCIALLY',
                              'icon': Icons.groups_rounded,
                            },
                            {
                              'label': 'Regularly',
                              'value': 'REGULARLY',
                              'icon': Icons.wine_bar_rounded,
                            },
                          ],
                          selectedValue: drinkingHabit,
                          onSelected: (val) {
                            setState(() => drinkingHabit = val);
                            checkIfDirty();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),

        // 7. Spoken Languages Card
        Container(
          key: _languagesKey,
          child: WebSectionCard(
            title: 'Spoken Languages',
            subtitle:
                'Add all languages you speak comfortably to facilitate seamless communication',
            icon: Icons.translate_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (languages.isNotEmpty) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: languages.map((lang) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  languages.remove(lang);
                                });
                                checkIfDirty();
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).canvasColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No languages selected yet. Add languages so potential matches know how to reach you.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Add / Edit Languages Button
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await WebLanguagePickerDialog.show(
                      context,
                      selectedLanguages: languages,
                    );
                    if (selected != null) {
                      setState(() {
                        languages = selected;
                      });
                      checkIfDirty();
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    languages.isEmpty
                        ? 'Select Spoken Languages'
                        : 'Edit Selected Languages (${languages.length})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 350.ms),

        const SizedBox(height: 32),

        // Bottom Save Changes Callout Bar
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDirty
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.4)
                  : Theme.of(context).dividerColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isDirty
                    ? Icons.edit_note_rounded
                    : Icons.check_circle_outline_rounded,
                color: isDirty
                    ? Theme.of(context).primaryColor
                    : Colors.green[600],
                size: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDirty
                          ? 'You have unsaved changes'
                          : 'Profile is up to date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      isDirty
                          ? 'Click Save Changes to commit updates to your live profile.'
                          : 'All changes have been successfully saved.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDirty) ...[
                OutlinedButton(
                  onPressed: _handleWebBackPress,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Discard'),
                ),
                const SizedBox(width: 12),
              ],
              ElevatedButton.icon(
                onPressed: (isDirty && !isLoading) ? saveProfile : null,
                icon: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  isLoading ? 'Saving Changes…' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
