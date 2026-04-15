import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mylifepartner/services/zego_service.dart';

/// Represents an incoming call invitation.
class IncomingCall {
  final String callId;
  final String callerId;
  final String callerName;
  final bool isVideo;

  const IncomingCall({
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.isVideo,
  });
}

/// Manages call signaling state – incoming invitations, accept/decline flow.
class CallProvider extends ChangeNotifier {
  StreamSubscription? _zimSubscription;
  IncomingCall? _incomingCall;
  String? _currentUserId;
  String? _currentUserName;

  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;

  /// Whether the caller's invitation was declined by the callee.
  bool _wasDeclined = false;
  bool get wasDeclined => _wasDeclined;

  IncomingCall? get incomingCall => _incomingCall;
  bool get hasIncomingCall => _incomingCall != null;

  void configure({required String userId, required String userName}) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  /// Start listening to ZIM messages for call signaling.
  void startListening() {
    _zimSubscription?.cancel();
    _zimSubscription =
        ZegoService.instance.onMessageReceived.listen(_handleMessage);
  }

  void _handleMessage(ZegoZIMMessage msg) {
    // Only process JSON call-signaling messages.
    if (!msg.content.startsWith('{')) return;

    try {
      final data = jsonDecode(msg.content) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == null) return;

      switch (type) {
        case 'call_invite':
          _incomingCall = IncomingCall(
            callId: data['callId'] as String,
            callerId: msg.fromUserId,
            callerName: data['callerName'] as String? ?? 'Unknown',
            isVideo: data['isVideo'] as bool? ?? false,
          );
          notifyListeners();
          break;

        case 'call_decline':
          _wasDeclined = true;
          notifyListeners();
          // Auto-clear after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            _wasDeclined = false;
            notifyListeners();
          });
          break;

        case 'call_accept':
          // Callee accepted — caller is already on CallScreen, nothing to do.
          break;

        case 'call_cancel':
          // Caller cancelled before callee answered.
          _incomingCall = null;
          notifyListeners();
          break;
      }
    } catch (_) {
      // Not a call-signaling message — ignore.
    }
  }

  /// Generate a deterministic call ID from two user IDs.
  String generateCallId(String userA, String userB) {
    final ids = [int.parse(userA), int.parse(userB)]..sort();
    return 'call_${ids[0]}_${ids[1]}';
  }

  /// Caller initiates a call — sends invitation signal via ZIM.
  Future<void> initiateCall({
    required String otherUserId,
    required bool isVideo,
  }) async {
    if (_currentUserId == null) return;
    final callId = generateCallId(_currentUserId!, otherUserId);

    await ZegoService.instance.sendCallInvitation(
      toUserId: otherUserId,
      callerName: _currentUserName ?? 'User $_currentUserId',
      callId: callId,
      isVideo: isVideo,
    );
  }

  /// Callee accepts the incoming call.
  void acceptCall() {
    if (_incomingCall == null) return;

    ZegoService.instance.sendCallResponse(
      toUserId: _incomingCall!.callerId,
      callId: _incomingCall!.callId,
      responseType: 'call_accept',
    );

    // The overlay reads incomingCall to navigate, so don't clear it yet.
    // It will be cleared after navigation.
  }

  /// Clear incoming call state (after navigation or dismissal).
  void clearIncomingCall() {
    _incomingCall = null;
    notifyListeners();
  }

  /// Callee declines the incoming call.
  void declineCall() {
    if (_incomingCall == null) return;

    ZegoService.instance.sendCallResponse(
      toUserId: _incomingCall!.callerId,
      callId: _incomingCall!.callId,
      responseType: 'call_decline',
    );

    _incomingCall = null;
    notifyListeners();
  }

  /// Reset declined state (e.g. when leaving call screen).
  void clearDeclined() {
    _wasDeclined = false;
  }

  @override
  void dispose() {
    _zimSubscription?.cancel();
    super.dispose();
  }
}
