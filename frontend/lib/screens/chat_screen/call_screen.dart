import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:mylifepartner/config/env.dart';
import 'package:mylifepartner/providers/chat_provider.dart';

class CallScreen extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;
  final String? localUserAvatar;
  final String? remoteUserAvatar;
  final bool isVideoCall;
  final bool isCaller;
  final String otherUserId;

  const CallScreen({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    this.localUserAvatar,
    this.remoteUserAvatar,
    this.isVideoCall = true,
    required this.isCaller,
    required this.otherUserId,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late DateTime _startTime;
  ChatProvider? _chatProvider;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<ChatProvider>();
  }

  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    if (widget.isCaller && _chatProvider != null) {
      final callType = widget.isVideoCall ? 'video' : 'audio';
      final payload = jsonEncode({
        'type': 'CALL_LOG',
        'callType': callType,
        'status': 'completed',
        'duration': duration,
      });
      _chatProvider!.sendMessage(
        receiverId: int.parse(widget.otherUserId),
        content: payload,
        messageType: 'CALL_LOG',
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: Env.zegoAppId,
        appSign: Env.zegoAppSign,
        userID: widget.userID,
        userName: widget.userName,
        callID: widget.callID,
        config: (widget.isVideoCall
            ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
            : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall())
          ..avatarBuilder = (BuildContext context, Size size, user, Map extraInfo) {
            final avatarUrl = user?.id == widget.userID ? widget.localUserAvatar : widget.remoteUserAvatar;
            return user != null && avatarUrl != null
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : const SizedBox();
          }
          ..turnOnMicrophoneWhenJoining = true
          ..useSpeakerWhenJoining = widget.isVideoCall,
      ),
    );
  }
}
