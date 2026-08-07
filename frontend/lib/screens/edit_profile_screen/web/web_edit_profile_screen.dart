import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/screens/edit_profile_screen/widgets/edit_profile_controller.dart';
import 'package:life_partner_again/screens/edit_profile_screen/widgets/edit_profile_ui_helpers.dart';
import 'package:life_partner_again/widgets/custom_app_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDiscardBottomSheet(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: CustomAppBar(
          title: "Edit Profile",
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textPrimary),
            onPressed: handleBackPress,
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                ),
              ),
              child: Stack(
                children: [
                  // Decorative background pattern
                  Positioned.fill(
                    child: CustomPaint(painter: DotGridPainter()),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Profile Info
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: navigateToManagePictures,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context).primaryColor.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 4,
                                        ),
                                        color: Theme.of(context).colorScheme.surface,
                                      ),
                                      child: CircleAvatar(
                                        radius: 64,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            primaryImageUrl != null &&
                                                primaryImageUrl!.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                primaryImageUrl!,
                                              )
                                            : null,
                                        child: loadingImage
                                            ? CircularProgressIndicator(
                                                color: Theme.of(context).primaryColor,
                                              )
                                            : (primaryImageUrl == null ||
                                                      primaryImageUrl!.isEmpty
                                                  ? const Icon(
                                                      Icons.person,
                                                      size: 64,
                                                      color: AppColors
                                                          .textSecondary,
                                                    )
                                                  : null),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().scale(
                                duration: 400.ms,
                                curve: Curves.easeOutBack,
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.user.name ?? '',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).animate().fadeIn(delay: 100.ms),
                                    const SizedBox(height: 8),
                                    Text(
                                      widget.user.email ?? '',
                                      style: TextStyle(
                                        color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                                        fontSize: 16,
                                      ),
                                    ).animate().fadeIn(delay: 150.ms),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),

                          // Personal Details Section
                          EditProfileSection(
                            title: "PERSONAL DETAILS",
                            icon: Icons.person_outline_rounded,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: MinimalTextField(
                                      controller: nameController,
                                      label: 'Display Name',
                                      hintText: 'Enter your name',
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: MinimalTextField(
                                      controller: dateController,
                                      label: 'Date of Birth',
                                      hintText: 'Select date',
                                      readOnly: true,
                                      onTap: selectDateOfBirth,
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: MinimalTextField(
                                      controller: ageController,
                                      label: 'Calculated Age',
                                      hintText: '--',
                                      enabled: false,
                                      readOnly: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                          const SizedBox(height: 16),

                          // Location Settings Section
                          EditProfileSection(
                            title: "LOCATION SETTINGS",
                            icon: Icons.location_on_outlined,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: MinimalCountryPicker(
                                      country: country,
                                      onChanged: (val) {
                                        setState(() {
                                          country = val;
                                        });
                                        checkIfDirty();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    child: MinimalTextField(
                                      controller: cityController,
                                      label: 'City',
                                      hintText: 'Enter city name',
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Please enter your city';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                          const SizedBox(height: 48),

                          // Save Button
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 200,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: (isDirty && !isLoading)
                                    ? saveProfile
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Theme.of(context).primaryColor
                                      .withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.save_outlined, size: 22),
                                          SizedBox(width: 12),
                                          Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}