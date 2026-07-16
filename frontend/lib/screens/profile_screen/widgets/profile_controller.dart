import 'package:flutter/material.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/models/user_image.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/services/user_repository.dart';
import 'package:life_partner_again/widgets/bottomsheet/custom_bottom_sheet.dart';

mixin ProfileControllerState<T extends StatefulWidget> on State<T>, RouteAware {
  final UserRepository userRepository = UserRepository();
  final ProfileRepository profileRepository = ProfileRepository();

  User? user;
  UserImage? primaryImage;
  bool isLoading = true;
  bool isUpdatingPrivacy = false;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  void subscribeToRoute(RouteObserver<ModalRoute<void>> routeObserver) {
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  void unsubscribeFromRoute(RouteObserver<ModalRoute<void>> routeObserver) {
    routeObserver.unsubscribe(this);
  }

  @override
  void didPopNext() {
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedUser = await userRepository.getUser();
      final images = await profileRepository.getUserImages();

      UserImage? primaryImg;
      try {
        primaryImg = images.firstWhere((img) => img.isPrimary);
      } catch (_) {
        if (images.isNotEmpty) {
          primaryImg = images.first;
        }
      }

      setState(() {
        user = fetchedUser;
        primaryImage = primaryImg;
      });
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void togglePrivacy(bool newValue) {
    if (isUpdatingPrivacy) return;

    final isEnabling = newValue;

    CustomBottomSheet.show(
      context: context,
      type: BottomSheetType.confirmation,
      title: isEnabling ? 'Enable Privacy?' : 'Disable Privacy?',
      message: isEnabling
          ? 'Your profile photos will be blurred for everyone except matches you approve.'
          : 'Your profile photos will be visible to everyone on the platform.',
      primaryButtonText: isEnabling ? 'Enable' : 'Disable',
      onPrimaryPressed: () async {
        Navigator.pop(context); // close sheet

        setState(() {
          isUpdatingPrivacy = true;
        });

        try {
          await profileRepository.updatePrivacySettings(newValue);
          await fetchProfileData();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              isUpdatingPrivacy = false;
            });
          }
        }
      },
      secondaryButtonText: 'Cancel',
      onSecondaryPressed: () {
        Navigator.pop(context);
      },
      imagePath: 'assets/images/illustrations/privacy.png',
    );
  }
}
