import 'package:flutter/material.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/models/match_recommendation.dart';
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
import 'package:life_partner_again/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:life_partner_again/screens/edit_profile_screen/edit_profile_screen.dart';
import 'package:life_partner_again/screens/manage_profile_images_screens/manage_profile_pictures_screen.dart';
import 'package:life_partner_again/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:life_partner_again/screens/splash_screen/splash_screen.dart';
import 'package:life_partner_again/screens/subscription_screen/subscription_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String password = '/password';
  static const String onboarding = '/onboarding';
  static const String profileCompletion = '/profile-completion';
  static const String partnerPreference = '/partner-preference';
  static const String selfieVerification = '/selfie-verification';
  static const String profileImageUpload = '/profile-image-upload';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String matches = '/matches';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String lpaGuide = '/lpa-guide';
  static const String chatDetail = '/chat-detail';
  static const String profileDetail = '/profile/:profileId';
  static const String editProfile = '/edit-profile';
  static const String manageProfilePictures = '/manage-profile-pictures';
  static const String subscription = '/subscription';
  static const String imageAccessRequests = '/image-access-requests';
  static const String mediaPreview = '/media-preview';
  static const String call = '/call';
  static const String outgoingCall = '/outgoing-call';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case landing:
        return MaterialPageRoute(
          builder: (_) => const LandingScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case otp:
        final args = settings.arguments as OtpArguments;
        return MaterialPageRoute(
          builder: (_) => OtpPage(
            email: args.email,
            isExistingUser: args.isExistingUser,
            isPasswordReset: args.isPasswordReset,
          ),
          settings: settings,
        );
      case password:
        final args = settings.arguments as PasswordArguments;
        return MaterialPageRoute(
          builder: (_) => PasswordScreen(
            email: args.email,
            isExistingUser: args.isExistingUser,
            isPasswordReset: args.isPasswordReset,
          ),
          settings: settings,
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingFlowScreen(),
          settings: settings,
        );
      case profileCompletion:
        return MaterialPageRoute(
          builder: (_) => const ProfileCompletionScreen(),
          settings: settings,
        );
      case partnerPreference:
        return MaterialPageRoute(
          builder: (_) => const PartnerPreferenceScreen(),
          settings: settings,
        );
      case selfieVerification:
        return MaterialPageRoute(
          builder: (_) => const SelfieVerificationScreen(),
          settings: settings,
        );
      case profileImageUpload:
        return MaterialPageRoute(
          builder: (_) => const ProfileImageUploadScreen(),
          settings: settings,
        );
      case home:
      case discover:
      case matches:
      case chat:
      case profile:
        int initialIndex = 0;
        if (settings.name == matches) initialIndex = 1;
        if (settings.name == chat) initialIndex = 2;
        if (settings.name == profile) initialIndex = 3;
        return MaterialPageRoute(
          builder: (_) => HomePage(initialIndex: initialIndex),
          settings: settings,
        );
      case lpaGuide:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: SafeArea(child: LpaGuideScreen())),
          settings: settings,
        );
      case chatDetail:
        final args = settings.arguments as ChatDetailArguments;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            profile: args.profile,
            currentUserId: args.currentUserId,
          ),
          settings: settings,
        );

      case editProfile:
        final user = settings.arguments as User;
        return MaterialPageRoute(
          builder: (_) => EditProfileScreen(user: user),
          settings: settings,
        );
      case manageProfilePictures:
        return MaterialPageRoute(
          builder: (_) => const ManageProfilePicturesScreen(),
          settings: settings,
        );
      case subscription:
        return MaterialPageRoute(
          builder: (_) => const SubscriptionScreen(),
          settings: settings,
        );
      default:
        return null;
    }
  }
}

class OtpArguments {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  OtpArguments({
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });
}

class PasswordArguments {
  final String email;
  final bool isExistingUser;
  final bool isPasswordReset;

  PasswordArguments({
    required this.email,
    required this.isExistingUser,
    this.isPasswordReset = false,
  });
}

class ChatDetailArguments {
  final MatchRecommendation profile;
  final int currentUserId;

  ChatDetailArguments({required this.profile, required this.currentUserId});
}

class MediaPreviewArguments {
  final String path;
  final String type;
  final VoidCallback onSend;

  MediaPreviewArguments({required this.path, required this.type, required this.onSend});
}

class OutgoingCallArguments {
  final String calleeName;
  final String? calleeAvatar;
  final bool isVideoCall;

  OutgoingCallArguments({required this.calleeName, this.calleeAvatar, required this.isVideoCall});
}

class CallArguments {
  final String callID;
  final String userID;
  final String userName;
  final String? localUserAvatar;
  final String? remoteUserAvatar;
  final bool isVideoCall;
  final bool isCaller;
  final String otherUserId;

  CallArguments({
    required this.callID,
    required this.userID,
    required this.userName,
    this.localUserAvatar,
    this.remoteUserAvatar,
    this.isVideoCall = false,
    this.isCaller = false,
    required this.otherUserId,
  });
}
