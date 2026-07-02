import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mylifepartner/config/env.dart';
import 'package:mylifepartner/providers/chat_provider.dart';
import 'package:mylifepartner/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

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
  Timer? _pollTimer;
  int _lastElapsedSeconds = 0;
  bool _isEnding = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  void _startPolling() {
    if (_pollTimer != null) return;

    // Reset start time to when the opposite user actually joined
    _startTime = DateTime.now();
    _lastElapsedSeconds = 0;

    // Poll immediately
    _checkLimit();

    // Poll periodically every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkLimit();
    });
  }

  Future<void> _checkLimit() async {
    if (!mounted || _isEnding) return;

    final callType = widget.isVideoCall ? 'video' : 'audio';
    int? consumeSeconds;

    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    consumeSeconds = elapsed - _lastElapsedSeconds;
    if (consumeSeconds < 0) consumeSeconds = 0;
    _lastElapsedSeconds = elapsed;

    try {
      await ChatApiService.checkCallAccess(
        type: callType,
        consumeSeconds: consumeSeconds,
      );
    } catch (e) {
      if (!mounted || _isEnding) return;

      _isEnding = true;
      _pollTimer?.cancel();

      String errorMsg = 'Call ended: limit reached.';
      if (e is DioException &&
          e.response?.data != null &&
          e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
      );

      // Programmatically end call by popping navigation
      Navigator.of(context).pop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<ChatProvider>();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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
        events: ZegoUIKitPrebuiltCallEvents(
          user: ZegoCallUserEvents(
            onEnter: (user) {
              if (user.id == widget.otherUserId) {
                _startPolling();
              }
            },
            onLeave: (user) {
              if (user.id == widget.otherUserId) {
                _pollTimer?.cancel();
                _pollTimer = null;
              }
            },
          ),
        ),
        config:
            (widget.isVideoCall
                  ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                  : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall())
              ..avatarBuilder =
                  (BuildContext context, Size size, user, Map extraInfo) {
                    final avatarUrl = user?.id == widget.userID
                        ? widget.localUserAvatar
                        : widget.remoteUserAvatar;
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
