import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:life_partner_again/main.dart' show navigatorKey;
import 'package:life_partner_again/providers/call_provider.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/widgets/cached_app_image.dart';

/// Full-screen overlay shown when an incoming call is received.
class IncomingCallOverlay extends StatefulWidget {
  const IncomingCallOverlay({super.key});

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onAccept(CallProvider provider) {
    final call = provider.incomingCall;
    if (call == null) return;

    provider.acceptCall();

    // Use navigatorKey to push onto MaterialApp's navigator.
    navigatorKey.currentContext?.push(
      '/call/${call.callId}',
      extra: CallArguments(
        callID: call.callId,
        userID: provider.currentUserId ?? '',
        userName: provider.currentUserName ?? 'User',
        localUserAvatarImageId: provider.currentUserAvatarImageId,
        localUserAvatar: provider.currentUserAvatar,
        localUserAvatarIsBlurred: provider.currentUserAvatarIsBlurred,
        remoteUserAvatarImageId: call.callerAvatarImageId,
        remoteUserAvatar: call.callerAvatar,
        remoteUserAvatarIsBlurred: call.callerAvatarIsBlurred,
        isVideoCall: call.isVideo,
        isCaller: false,
        otherUserId: call.callerId,
      ),
    );

    provider.clearIncomingCall();
  }

  void _onDecline(CallProvider provider) {
    if (provider.incomingCall != null) {
      final callType = provider.incomingCall!.isVideo ? 'video' : 'audio';
      final payload = jsonEncode({
        'type': 'CALL_LOG',
        'callType': callType,
        'status': 'declined',
        'duration': 0,
      });
      context.read<ChatProvider>().sendMessage(
        receiverId: int.parse(provider.incomingCall!.callerId),
        content: payload,
        messageType: 'CALL_LOG',
      );
    }
    provider.declineCall();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, _) {
        if (!provider.hasIncomingCall) {
          return const SizedBox.shrink();
        }

        final call = provider.incomingCall!;

        return Material(
          color: Colors.black.withValues(alpha: 0.85),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Call type label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        call.isVideo
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        call.isVideo
                            ? 'Incoming Video Call'
                            : 'Incoming Voice Call',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Pulsing avatar
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                          Theme.of(context).primaryColorDark,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(child: _buildCallerAvatar(call)),
                  ),
                ),

                const SizedBox(height: 24),

                // Caller name
                Text(
                  call.callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Ringing label
                Text(
                  'is calling you…',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 15,
                  ),
                ),

                const Spacer(flex: 3),

                // Accept / Decline buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CallActionButton(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        color: const Color(0xFFFF3B30),
                        onTap: () => _onDecline(provider),
                      ),
                      _CallActionButton(
                        icon: Icons.call_rounded,
                        label: 'Accept',
                        color: const Color(0xFF34C759),
                        onTap: () => _onAccept(provider),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallerAvatar(IncomingCall call) {
    if (call.callerAvatarImageId != null || call.callerAvatar != null) {
      return ClipOval(
        child: CachedAppImage(
          imageId: call.callerAvatarImageId,
          presignedImageUrl: call.callerAvatar,
          isBlurred: call.callerAvatarIsBlurred,
          width: 106,
          height: 106,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildInitialAvatar(call.callerName),
          errorWidget: (_, __, ___) => _buildInitialAvatar(call.callerName),
        ),
      );
    }

    return _buildInitialAvatar(call.callerName);
  }

  Widget _buildInitialAvatar(String name) {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 44,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
