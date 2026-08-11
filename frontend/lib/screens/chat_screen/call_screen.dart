import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/config/env.dart';
import 'package:life_partner_again/providers/chat_provider.dart';
import 'package:life_partner_again/services/chat_service.dart';
import 'package:life_partner_again/services/zego_service.dart';
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
  Timer? _tokenRenewalTimer; // Scheduled 15 min before the 3-hour token expires
  int _lastElapsedSeconds = 0;
  bool _isEnding = false;
  String? _zegoToken;
  bool _isLoadingToken = true; // Always fetch a backend token

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _fetchToken(); // Always fetch — token mode used on all platforms
  }

  Future<void> _fetchToken() async {
    try {
      final data = await ChatApiService.getZegoToken();
      if (data != null && data['token'] != null) {
        if (mounted) {
          setState(() {
            _zegoToken = data['token'];
            _isLoadingToken = false;
          });
          // Schedule proactive renewal 15 min before the 3h token expires
          _scheduleTokenRenewal();
        }
      } else {
        throw Exception('Token not found in response');
      }
    } catch (e) {
      debugPrint('[CallScreen] Failed to fetch token: $e');
      if (mounted) {
        setState(() {
          _isLoadingToken = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize call: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        context.pop();
      }
    }
  }

  /// Schedules a proactive ZIM token renewal 15 minutes before expiry.
  /// Token lifetime is 3 hours; renewal fires at 2h45m.
  /// After renewing, it reschedules itself so sessions of any length stay valid.
  void _scheduleTokenRenewal() {
    _tokenRenewalTimer?.cancel();
    // 3 hours − 15 minutes = 2h45m = 9900 seconds
    _tokenRenewalTimer = Timer(const Duration(seconds: 9900), () async {
      if (!mounted) return;
      debugPrint('[CallScreen] Proactive token renewal triggered');
      try {
        final data = await ChatApiService.renewZegoToken();
        if (data != null && data['token'] != null) {
          final newToken = data['token'] as String;
          await ZegoService.instance.renewToken(newToken);
          debugPrint('[CallScreen] Token renewed, rescheduling next renewal');
          // Reschedule so a very long session keeps renewing
          if (mounted) _scheduleTokenRenewal();
        }
      } catch (e) {
        debugPrint('[CallScreen] Token renewal failed (non-fatal): $e');
        // Non-fatal: ZIM will still work until actual expiry; retry in 10 min
        if (mounted) {
          _tokenRenewalTimer = Timer(const Duration(minutes: 10), () {
            if (mounted) _scheduleTokenRenewal();
          });
        }
      }
    });
  }

  void _startPolling() {
    // Cancel any stale timer before starting a new one
    _pollTimer?.cancel();
    _pollTimer = null;

    // Reset elapsed counter to when the peer actually joined
    _startTime = DateTime.now();
    _lastElapsedSeconds = 0;

    // Poll immediately, then every 5 seconds
    _checkLimit();
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
      context.pop();
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
    _tokenRenewalTimer?.cancel();
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
    if (_isLoadingToken) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: Env.zegoAppId,
        appSign: '', // Always blank — token-only mode
        token: _zegoToken ?? '',
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
