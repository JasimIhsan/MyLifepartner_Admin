import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/providers/call_provider.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/screens/chat_screen/call_screen.dart';

/// Screen shown to the caller while waiting for the callee to accept/decline.
class OutgoingCallScreen extends StatefulWidget {
  final String calleeName;
  final String? calleeAvatar;
  final bool isVideoCall;

  const OutgoingCallScreen({
    super.key,
    required this.calleeName,
    this.calleeAvatar,
    required this.isVideoCall,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onCancel() {
    final provider = context.read<CallProvider>();
    if (provider.outgoingCall != null) {
      final callType = provider.outgoingCall!.isVideo ? 'video' : 'audio';
      final payload = jsonEncode({
        'type': 'CALL_LOG',
        'callType': callType,
        'status': 'canceled',
        'duration': 0,
      });
      context.read<ChatProvider>().sendMessage(
        receiverId: int.parse(provider.outgoingCall!.calleeId),
        content: payload,
        messageType: 'CALL_LOG',
      );
    }
    provider.cancelOutgoingCall();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, provider, _) {
        // Callee accepted → navigate to the actual call screen.
        if (provider.wasAccepted && provider.outgoingCall != null) {
          final call = provider.outgoingCall!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.clearOutgoingCall();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => CallScreen(
                  callID: call.callId,
                  userID: provider.currentUserId ?? '',
                  userName: provider.currentUserName ?? 'User',
                  localUserAvatar: provider.currentUserAvatar,
                  remoteUserAvatar: widget.calleeAvatar,
                  isVideoCall: call.isVideo,
                  isCaller: true,
                  otherUserId: call.calleeId,
                ),
              ),
            );
          });
        }

        // Callee declined → show feedback and pop.
        if (provider.wasDeclined) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.clearOutgoingCall();
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.call_end_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('${widget.calleeName} declined the call'),
                    ],
                  ),
                  backgroundColor: const Color(0xFFFF3B30),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: SafeArea(
            child: SizedBox.expand(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                const Spacer(flex: 2),

                // Call type label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isVideoCall
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                        color: Colors.white54,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isVideoCall
                            ? 'Video Call'
                            : 'Voice Call',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Animated avatar
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
                          AppColors.primary.withValues(alpha: 0.7),
                          AppColors.primaryDark,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: widget.calleeAvatar != null
                          ? CircleAvatar(
                              radius: 53,
                              backgroundImage: NetworkImage(widget.calleeAvatar!),
                              backgroundColor: Colors.transparent,
                            )
                          : Text(
                              widget.calleeName.isNotEmpty
                                  ? widget.calleeName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Callee name
                Text(
                  widget.calleeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // "Calling..." label
                const Text(
                  'Calling…',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                  ),
                ),

                const Spacer(flex: 3),

                // Cancel button
                GestureDetector(
                  onTap: _onCancel,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B30)
                              .withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
