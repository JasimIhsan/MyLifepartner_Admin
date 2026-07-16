import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/screens/chat_screen/chat_detail_screen.dart';
import 'package:life_partner_again/screens/home_screen/home_screen.dart';
import 'package:life_partner_again/screens/landing_screen/landing_screen.dart';
import 'package:life_partner_again/screens/login_screen/login_screen.dart';
import 'package:life_partner_again/screens/lpa_guide_screen/lpa_guide_screen.dart';
import 'package:life_partner_again/screens/onboarding/onboarding_flow_screen.dart';
import 'package:life_partner_again/screens/otp_screen/otp_screen.dart';
import 'package:life_partner_again/screens/partner_preference/partner_preference_screen.dart';
import 'package:life_partner_again/screens/password_screen/password_screen.dart';
import 'package:life_partner_again/screens/profile_completion/profile_completion_screen.dart';
import 'package:life_partner_again/screens/profile_detail_screen/profile_detail_screen.dart';
import 'package:life_partner_again/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:life_partner_again/screens/edit_profile_screen/edit_profile_screen.dart';
import 'package:life_partner_again/screens/manage_profile_images_screens/manage_profile_pictures_screen.dart';
import 'package:life_partner_again/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:life_partner_again/screens/subscription_screen/subscription_screen.dart';
import 'package:life_partner_again/screens/splash_screen/splash_screen.dart';
import 'package:life_partner_again/main.dart' show navigatorKey;
import 'package:life_partner_again/screens/chat_screen/widgets/media_preview_screen.dart';
import 'package:life_partner_again/screens/chat_screen/outgoing_call_screen.dart';
import 'package:life_partner_again/screens/chat_screen/call_screen.dart';
import 'package:life_partner_again/screens/image_access_screen/image_access_screen.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final auth = authProvider;
      final isLoggedIn = auth.isLoggedIn;
      final onboarding = auth.onboardingStatus;

      // Define public routes (only unauthenticated users can access)
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.landing,
        AppRoutes.login,
        AppRoutes.otp,
        AppRoutes.password,
      ];

      final isPublicRoute = publicRoutes.contains(state.matchedLocation);

      // 1. Unauthenticated User Guard — redirect to landing for private routes
      if (!isLoggedIn) {
        if (!isPublicRoute) {
          return AppRoutes.landing;
        }
        return null;
      }

      // 2. Authenticated User Guard — redirect away from public routes to home
      if (isPublicRoute) {
        return AppRoutes.home;
      }

      // 3. Onboarding Guard — redirect to pending onboarding step
      if (onboarding != null) {
        if (!onboarding.hasCompletedBasicDetails) {
          if (state.matchedLocation != AppRoutes.onboarding) {
            return AppRoutes.onboarding;
          }
        } else if (!onboarding.hasCompletedPartnerPreference) {
          if (state.matchedLocation != AppRoutes.partnerPreference) {
            return AppRoutes.partnerPreference;
          }
        } else if (!onboarding.hasCompletedImageUpload) {
          if (state.matchedLocation != AppRoutes.profileImageUpload) {
            return AppRoutes.profileImageUpload;
          }
        } else if (onboarding.selfieStatus == null ||
            onboarding.selfieStatus == "NONE") {
          if (state.matchedLocation != AppRoutes.selfieVerification) {
            return AppRoutes.selfieVerification;
          }
        } else {
          // Fully onboarded — prevent going back to onboarding routes
          final onboardingRoutes = [
            AppRoutes.onboarding,
            AppRoutes.partnerPreference,
            AppRoutes.profileImageUpload,
            AppRoutes.selfieVerification,
          ];
          if (onboardingRoutes.contains(state.matchedLocation)) {
            return AppRoutes.home;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final args = state.extra as OtpArguments;
          return OtpPage(
            email: args.email,
            isExistingUser: args.isExistingUser,
            isPasswordReset: args.isPasswordReset,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.password,
        builder: (context, state) {
          final args = state.extra as PasswordArguments;
          return PasswordScreen(
            email: args.email,
            isExistingUser: args.isExistingUser,
            isPasswordReset: args.isPasswordReset,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingFlowScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileCompletion,
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.partnerPreference,
        builder: (context, state) => const PartnerPreferenceScreen(),
      ),
      GoRoute(
        path: AppRoutes.selfieVerification,
        builder: (context, state) => const SelfieVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileImageUpload,
        builder: (context, state) => const ProfileImageUploadScreen(),
      ),
      // Home / Bottom Navigation Tabs Routes
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(initialIndex: 0),
      ),
      GoRoute(
        path: AppRoutes.discover,
        builder: (context, state) => const HomePage(initialIndex: 0),
      ),
      GoRoute(
        path: AppRoutes.matches,
        builder: (context, state) => const HomePage(initialIndex: 1),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const HomePage(initialIndex: 2),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const HomePage(initialIndex: 3),
      ),
      GoRoute(
        path: AppRoutes.lpaGuide,
        builder: (context, state) =>
            const Scaffold(body: SafeArea(child: LpaGuideScreen())),
      ),
      GoRoute(
        path: AppRoutes.chatDetail,
        builder: (context, state) {
          final args = state.extra as ChatDetailArguments;
          return ChatDetailScreen(
            profile: args.profile,
            currentUserId: args.currentUserId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profileDetail,
        builder: (context, state) {
          final args = state.extra as ProfileDetailArguments;
          return ProfileDetailScreen(
            profileId: args.profileId,
            profileName: args.profileName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) {
          final user = state.extra as User;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: AppRoutes.manageProfilePictures,
        builder: (context, state) => const ManageProfilePicturesScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.imageAccessRequests,
        builder: (context, state) => const ImageAccessRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mediaPreview,
        builder: (context, state) {
          final args = state.extra as MediaPreviewArguments;
          return MediaPreviewScreen(
            path: args.path,
            type: args.type,
            onSend: args.onSend,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.outgoingCall,
        builder: (context, state) {
          final args = state.extra as OutgoingCallArguments;
          return OutgoingCallScreen(
            calleeName: args.calleeName,
            calleeAvatar: args.calleeAvatar,
            isVideoCall: args.isVideoCall,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.call,
        builder: (context, state) {
          final args = state.extra as CallArguments;
          return CallScreen(
            callID: args.callID,
            userID: args.userID,
            userName: args.userName,
            localUserAvatar: args.localUserAvatar,
            remoteUserAvatar: args.remoteUserAvatar,
            isVideoCall: args.isVideoCall,
            isCaller: args.isCaller,
            otherUserId: args.otherUserId,
          );
        },
      ),
    ],
  );
}
