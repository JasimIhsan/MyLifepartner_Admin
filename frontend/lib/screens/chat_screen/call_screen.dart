import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:mylifepartner/config/env.dart';
import 'package:mylifepartner/core/app_colors.dart';

class CallScreen extends StatelessWidget {
  final String callID;
  final String userID;
  final String userName;
  final bool isVideoCall;

  const CallScreen({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.isVideoCall = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: Env.zegoAppId,
        appSign: Env.zegoAppSign,
        userID: userID,
        userName: userName,
        callID: callID,
        config: isVideoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
        onDispose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Helper to launch a call between two users
  static void startCall(
    BuildContext context, {
    required String currentUserId,
    required String currentUserName,
    required String otherUserId,
    required bool isVideoCall,
  }) {
    // Generate a deterministic callID from both user IDs
    final ids = [int.parse(currentUserId), int.parse(otherUserId)]..sort();
    final callID = 'call_${ids[0]}_${ids[1]}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          callID: callID,
          userID: currentUserId,
          userName: currentUserName,
          isVideoCall: isVideoCall,
        ),
      ),
    );
  }
}
