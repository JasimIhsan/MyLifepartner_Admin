import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/screens/edit_profile_screen/widgets/edit_profile_controller.dart';
import 'package:life_partner_again/screens/edit_profile_screen/widgets/edit_profile_ui_helpers.dart';
import 'package:life_partner_again/widgets/header_waves_background.dart';

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
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDiscardBottomSheet(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FAFD),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
                      const HeaderWavesBackground(),
                      Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 8,
                              left: 8,
                              right: 8,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    onPressed: handleBackPress,
                                  ),
                                ),
                                const Text(
                                  'Profile',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: navigateToManagePictures,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: Colors.grey[100],
                                    backgroundImage:
                                        primaryImageUrl != null &&
                                            primaryImageUrl!.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            primaryImageUrl!,
                                          )
                                        : null,
                                    child: loadingImage
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                          )
                                        : (primaryImageUrl == null ||
                                                  primaryImageUrl!.isEmpty
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 54,
                                                  color: Colors.grey,
                                                )
                                              : null),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.user.name ?? '',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email ?? '',
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color ?? AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 20,
                              ),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 24,
                                  bottom:
                                      MediaQuery.of(context).padding.bottom > 0
                                      ? MediaQuery.of(context).padding.bottom
                                      : 24,
                                ),
                                child: Form(
                                  key: formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person_outline_rounded,
                                            color: Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'PERSONAL DETAILS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      MinimalTextField(
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
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: MinimalTextField(
                                              controller: dateController,
                                              label: 'Date of Birth',
                                              hintText: 'Select date',
                                              readOnly: true,
                                              onTap: selectDateOfBirth,
                                            ),
                                          ),
                                          const SizedBox(width: 24),
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
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            color: Theme.of(context).primaryColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'LOCATION SETTINGS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      MinimalCountryPicker(
                                        country: country,
                                        onChanged: (val) {
                                          setState(() {
                                            country = val;
                                          });
                                          checkIfDirty();
                                        },
                                      ),
                                      MinimalTextField(
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
                                      const Spacer(),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: ElevatedButton(
                                          onPressed: (isDirty && !isLoading)
                                              ? saveProfile
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context).primaryColor,
                                            foregroundColor: Colors.white,
                                            disabledBackgroundColor: AppColors
                                                .primary
                                                .withValues(alpha: 0.5),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: isLoading
                                              ? const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.save_outlined,
                                                      color: Colors.white,
                                                      size: 22,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Container(
                                                      width: 1,
                                                      height: 20,
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    const Text(
                                                      'Save Changes',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}