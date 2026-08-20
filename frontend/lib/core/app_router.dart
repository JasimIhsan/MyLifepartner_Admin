import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/main.dart' show navigatorKey, routeObserver;
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/providers/auth_provider.dart';
import 'package:life_partner_again/screens/blocked_users_screen/blocked_users_screen.dart';
import 'package:life_partner_again/screens/chat_screen/call_screen.dart';
import 'package:life_partner_again/screens/chat_screen/chat_detail_screen.dart';
import 'package:life_partner_again/screens/chat_screen/outgoing_call_screen.dart';
import 'package:life_partner_again/screens/chat_screen/widgets/media_preview_screen.dart';
import 'package:life_partner_again/screens/discover_screen/mobile/browse_profiles_screen.dart';
import 'package:life_partner_again/screens/edit_partner_preference_screen/edit_partner_preference_screen.dart';
import 'package:life_partner_again/screens/edit_profile_screen/edit_profile_screen.dart';
import 'package:life_partner_again/screens/home_screen/home_screen.dart';
import 'package:life_partner_again/screens/image_access_screen/image_access_screen.dart';
import 'package:life_partner_again/screens/landing_screen/landing_screen.dart';
import 'package:life_partner_again/screens/login_screen/login_screen.dart';
import 'package:life_partner_again/screens/lpa_guide_screen/lpa_guide_screen.dart';
import 'package:life_partner_again/screens/manage_profile_images_screens/manage_profile_pictures_screen.dart';
import 'package:life_partner_again/screens/onboarding/onboarding_flow_screen.dart';
import 'package:life_partner_again/screens/otp_screen/otp_screen.dart';
import 'package:life_partner_again/screens/partner_preference/partner_preference_screen.dart';
import 'package:life_partner_again/screens/password_screen/password_screen.dart';
import 'package:life_partner_again/screens/public_web/public_web_router.dart';
import 'package:life_partner_again/screens/public_web/public_web_routes.dart';
import 'package:life_partner_again/screens/profile_completion/profile_completion_screen.dart';
import 'package:life_partner_again/screens/profile_detail_screen/profile_detail_screen.dart';
import 'package:life_partner_again/screens/profile_image_upload/profile_image_upload_screen.dart';
import 'package:life_partner_again/screens/selfie_verification/selfie_verification_screen.dart';
import 'package:life_partner_again/screens/splash_screen/splash_screen.dart';
import 'package:life_partner_again/screens/subscription_screen/billing_history_screen.dart';
import 'package:life_partner_again/screens/subscription_screen/subscription_screen.dart';
import 'package:life_partner_again/widgets/web_main_layout.dart';

const String _webAppPrefix = '/app';

String _webAppPath(String route) => '$_webAppPrefix$route';

bool _isWebAppRoute(String location) {
  return location == _webAppPrefix || location.startsWith('$_webAppPrefix/');
}

String _unprefixWebAppRoute(String location) {
  if (location == _webAppPrefix) return AppRoutes.home;
  if (_isWebAppRoute(location)) {
    return location.substring(_webAppPrefix.length);
  }
  return location;
}

String _surfaceRoute(String route, bool isWebAppRoute) {
  return kIsWeb && isWebAppRoute ? _webAppPath(route) : route;
}

bool _isLegacyWebAppRoute(String location) {
  return const {
    AppRoutes.splash,
    AppRoutes.landing,
    AppRoutes.login,
    AppRoutes.otp,
    AppRoutes.password,
    AppRoutes.onboarding,
    AppRoutes.profileCompletion,
    AppRoutes.partnerPreference,
    AppRoutes.selfieVerification,
    AppRoutes.profileImageUpload,
    AppRoutes.home,
    AppRoutes.discover,
    AppRoutes.matches,
    AppRoutes.chat,
    AppRoutes.profile,
    AppRoutes.lpaGuide,
    AppRoutes.chatDetail,
    AppRoutes.profileDetail,
    AppRoutes.editProfile,
    AppRoutes.editPartnerPreference,
    AppRoutes.manageProfilePictures,
    AppRoutes.subscription,
    AppRoutes.imageAccessRequests,
    AppRoutes.mediaPreview,
    AppRoutes.outgoingCall,
    AppRoutes.call,
    AppRoutes.browseProfiles,
    AppRoutes.billingHistory,
    AppRoutes.blockedUsers,
  }.contains(location);
}

bool _isLegacyWebMainAppRoute(String location) {
  return const {
    AppRoutes.home,
    AppRoutes.discover,
    AppRoutes.matches,
    AppRoutes.chat,
    AppRoutes.profile,
  }.contains(location);
}

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: kIsWeb ? PublicWebRoutes.home : AppRoutes.home,
    observers: [routeObserver],
    refreshListenable: authProvider,
    redirect: (context, state) {
      final auth = authProvider;
      final matchedLocation = state.matchedLocation;
      final isWebAppRoute = kIsWeb && _isWebAppRoute(matchedLocation);
      final appLocation = _unprefixWebAppRoute(matchedLocation);
      final isPublicWebsiteRoute =
          kIsWeb &&
          !isWebAppRoute &&
          PublicWebRoutes.isPublicWebsiteRoute(matchedLocation);

      if (kIsWeb &&
          !isPublicWebsiteRoute &&
          !isWebAppRoute &&
          _isLegacyWebAppRoute(matchedLocation)) {
        if (_isLegacyWebMainAppRoute(matchedLocation)) {
          return PublicWebRoutes.home;
        }
        return state.uri.replace(path: _webAppPath(state.uri.path)).toString();
      }

      if (kIsWeb && matchedLocation == _webAppPrefix) {
        return _webAppPath(AppRoutes.home);
      }

      // 1. Initialization Guard
      if (!auth.isInitialized) {
        if (kIsWeb && isPublicWebsiteRoute) {
          return null;
        }
        if (appLocation != AppRoutes.splash) {
          return _surfaceRoute(AppRoutes.splash, isWebAppRoute);
        }
        return null;
      }

      if (kIsWeb && isPublicWebsiteRoute) {
        return null;
      }

      if (!kIsWeb && isPublicWebsiteRoute) {
        return AppRoutes.landing;
      }

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

      final isPublicRoute = publicRoutes.contains(appLocation);

      // 2. Unauthenticated User Guard
      if (!isLoggedIn) {
        // Redirect to landing if trying to access private route, OR if staying on splash after init
        if (!isPublicRoute || appLocation == AppRoutes.splash) {
          return _surfaceRoute(AppRoutes.landing, isWebAppRoute);
        }
        return null;
      }

      // 3. Authenticated User Guard — redirect away from public routes to home
      // (If onboarding is pending, the next evaluation will redirect from home to onboarding)
      if (isPublicRoute) {
        return _surfaceRoute(AppRoutes.home, isWebAppRoute);
      }

      // 4. Onboarding Guard — redirect to pending onboarding step
      if (onboarding != null) {
        if (!onboarding.hasCompletedBasicDetails) {
          if (appLocation != AppRoutes.onboarding) {
            return _surfaceRoute(AppRoutes.onboarding, isWebAppRoute);
          }
        } else if (!onboarding.hasCompletedPartnerPreference) {
          if (appLocation != AppRoutes.partnerPreference) {
            return _surfaceRoute(AppRoutes.partnerPreference, isWebAppRoute);
          }
        } else if (!onboarding.hasCompletedImageUpload) {
          if (appLocation != AppRoutes.profileImageUpload) {
            return _surfaceRoute(AppRoutes.profileImageUpload, isWebAppRoute);
          }
        } else if (onboarding.selfieStatus == null ||
            onboarding.selfieStatus == "NONE") {
          if (appLocation != AppRoutes.selfieVerification) {
            return _surfaceRoute(AppRoutes.selfieVerification, isWebAppRoute);
          }
        } else {
          // Fully onboarded — prevent going back to onboarding routes
          final onboardingRoutes = [
            AppRoutes.onboarding,
            AppRoutes.partnerPreference,
            AppRoutes.profileImageUpload,
            AppRoutes.selfieVerification,
          ];
          if (onboardingRoutes.contains(appLocation)) {
            return _surfaceRoute(AppRoutes.home, isWebAppRoute);
          }
        }
      }

      return null;
    },
    routes: [
      ...buildPublicWebRoutes(),
      ..._buildWebAppRoutes(),
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
          final args = state.extra as OtpArguments?;
          if (args == null) {
            return _buildErrorScreen(
              context,
              'Session expired or invalid arguments.',
            );
          }
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
          final args = state.extra as PasswordArguments?;
          if (args == null) {
            return _buildErrorScreen(
              context,
              'Session expired or invalid arguments.',
            );
          }
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
      ShellRoute(
        builder: (context, state, child) => WebMainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage(initialIndex: 0)),
          ),
          GoRoute(
            path: AppRoutes.discover,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage(initialIndex: 0)),
          ),
          GoRoute(
            path: AppRoutes.matches,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage(initialIndex: 1)),
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage(initialIndex: 2)),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomePage(initialIndex: 3)),
          ),
          GoRoute(
            path: AppRoutes.lpaGuide,
            builder: (context, state) =>
                const Scaffold(body: SafeArea(child: LpaGuideScreen())),
          ),
          GoRoute(
            path: AppRoutes.chatDetail,
            builder: (context, state) {
              final args = state.extra as ChatDetailArguments?;
              if (args == null) {
                return _buildErrorScreen(context, 'Chat data not found.');
              }
              return ChatDetailScreen(
                profile: args.profile,
                currentUserId: args.currentUserId,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.profileDetail,
            builder: (context, state) {
              return const ProfileDetailScreen();
            },
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            builder: (context, state) {
              final user = state.extra as User?;
              if (user == null) {
                return _buildErrorScreen(context, 'User data not found.');
              }
              return EditProfileScreen(user: user);
            },
          ),
          GoRoute(
            path: AppRoutes.editPartnerPreference,
            builder: (context, state) => const EditPartnerPreferenceScreen(),
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
            path: AppRoutes.browseProfiles,
            builder: (context, state) => const BrowseProfilesScreen(),
          ),
          GoRoute(
            path: AppRoutes.billingHistory,
            builder: (context, state) => const BillingHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.blockedUsers,
            builder: (context, state) => const BlockedUsersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.mediaPreview,
        builder: (context, state) {
          final args = state.extra as MediaPreviewArguments?;
          if (args == null) {
            return _buildErrorScreen(context, 'Media data not found.');
          }
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
          final args = state.extra as OutgoingCallArguments?;
          if (args == null) {
            return _buildErrorScreen(context, 'Call data not found.');
          }
          return OutgoingCallScreen(
            calleeName: args.calleeName,
            calleeAvatarImageId: args.calleeAvatarImageId,
            calleeAvatar: args.calleeAvatar,
            calleeAvatarIsBlurred: args.calleeAvatarIsBlurred,
            isVideoCall: args.isVideoCall,
          );
        },
      ),

      GoRoute(
        path: AppRoutes.call,
        builder: (context, state) {
          final args = state.extra as CallArguments?;
          if (args == null) {
            return _buildErrorScreen(context, 'Call data not found.');
          }
          return CallScreen(
            callID: args.callID,
            userID: args.userID,
            userName: args.userName,
            localUserAvatarImageId: args.localUserAvatarImageId,
            localUserAvatar: args.localUserAvatar,
            localUserAvatarIsBlurred: args.localUserAvatarIsBlurred,
            remoteUserAvatarImageId: args.remoteUserAvatarImageId,
            remoteUserAvatar: args.remoteUserAvatar,
            remoteUserAvatarIsBlurred: args.remoteUserAvatarIsBlurred,
            isVideoCall: args.isVideoCall,
            isCaller: args.isCaller,
            otherUserId: args.otherUserId,
          );
        },
      ),
    ],
  );
}

List<RouteBase> _buildWebAppRoutes() {
  return [
    GoRoute(
      path: _webAppPrefix,
      redirect: (context, state) => _webAppPath(AppRoutes.home),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.splash),
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.landing),
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.login),
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.otp),
      builder: (context, state) {
        final args = state.extra as OtpArguments?;
        if (args == null) {
          return _buildErrorScreen(
            context,
            'Session expired or invalid arguments.',
          );
        }
        return OtpPage(
          email: args.email,
          isExistingUser: args.isExistingUser,
          isPasswordReset: args.isPasswordReset,
        );
      },
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.password),
      builder: (context, state) {
        final args = state.extra as PasswordArguments?;
        if (args == null) {
          return _buildErrorScreen(
            context,
            'Session expired or invalid arguments.',
          );
        }
        return PasswordScreen(
          email: args.email,
          isExistingUser: args.isExistingUser,
          isPasswordReset: args.isPasswordReset,
        );
      },
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.onboarding),
      builder: (context, state) => const OnboardingFlowScreen(),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.profileCompletion),
      builder: (context, state) => const ProfileCompletionScreen(),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.partnerPreference),
      builder: (context, state) => const PartnerPreferenceScreen(),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.selfieVerification),
      builder: (context, state) => const SelfieVerificationScreen(),
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.profileImageUpload),
      builder: (context, state) => const ProfileImageUploadScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => WebMainLayout(child: child),
      routes: [
        GoRoute(
          path: _webAppPath(AppRoutes.home),
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage(initialIndex: 0)),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.discover),
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage(initialIndex: 0)),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.matches),
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage(initialIndex: 1)),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.chat),
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage(initialIndex: 2)),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.profile),
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage(initialIndex: 3)),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.lpaGuide),
          builder: (context, state) =>
              const Scaffold(body: SafeArea(child: LpaGuideScreen())),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.chatDetail),
          builder: (context, state) {
            final args = state.extra as ChatDetailArguments?;
            if (args == null) {
              return _buildErrorScreen(context, 'Chat data not found.');
            }
            return ChatDetailScreen(
              profile: args.profile,
              currentUserId: args.currentUserId,
            );
          },
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.profileDetail),
          builder: (context, state) => const ProfileDetailScreen(),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.editProfile),
          builder: (context, state) {
            final user = state.extra as User?;
            if (user == null) {
              return _buildErrorScreen(context, 'User data not found.');
            }
            return EditProfileScreen(user: user);
          },
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.editPartnerPreference),
          builder: (context, state) => const EditPartnerPreferenceScreen(),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.manageProfilePictures),
          builder: (context, state) => const ManageProfilePicturesScreen(),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.subscription),
          builder: (context, state) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.imageAccessRequests),
          builder: (context, state) => const ImageAccessRequestsScreen(),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.browseProfiles),
          builder: (context, state) => const BrowseProfilesScreen(),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.billingHistory),
          builder: (context, state) => const BillingHistoryScreen(),
        ),
        GoRoute(
          path: _webAppPath(AppRoutes.blockedUsers),
          builder: (context, state) => const BlockedUsersScreen(),
        ),
      ],
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.mediaPreview),
      builder: (context, state) {
        final args = state.extra as MediaPreviewArguments?;
        if (args == null) {
          return _buildErrorScreen(context, 'Media data not found.');
        }
        return MediaPreviewScreen(
          path: args.path,
          type: args.type,
          onSend: args.onSend,
        );
      },
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.outgoingCall),
      builder: (context, state) {
        final args = state.extra as OutgoingCallArguments?;
        if (args == null) {
          return _buildErrorScreen(context, 'Call data not found.');
        }
        return OutgoingCallScreen(
          calleeName: args.calleeName,
          calleeAvatarImageId: args.calleeAvatarImageId,
          calleeAvatar: args.calleeAvatar,
          calleeAvatarIsBlurred: args.calleeAvatarIsBlurred,
          isVideoCall: args.isVideoCall,
        );
      },
    ),
    GoRoute(
      path: _webAppPath(AppRoutes.call),
      builder: (context, state) {
        final args = state.extra as CallArguments?;
        if (args == null) {
          return _buildErrorScreen(context, 'Call data not found.');
        }
        return CallScreen(
          callID: args.callID,
          userID: args.userID,
          userName: args.userName,
          localUserAvatarImageId: args.localUserAvatarImageId,
          localUserAvatar: args.localUserAvatar,
          localUserAvatarIsBlurred: args.localUserAvatarIsBlurred,
          remoteUserAvatarImageId: args.remoteUserAvatarImageId,
          remoteUserAvatar: args.remoteUserAvatar,
          remoteUserAvatarIsBlurred: args.remoteUserAvatarIsBlurred,
          isVideoCall: args.isVideoCall,
          isCaller: args.isCaller,
          otherUserId: args.otherUserId,
        );
      },
    ),
  ];
}

Widget _buildErrorScreen(BuildContext context, String message) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final location = GoRouterState.of(context).matchedLocation;
              context.go(
                _isWebAppRoute(location)
                    ? _webAppPath(AppRoutes.home)
                    : AppRoutes.home,
              );
            },
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  );
}
