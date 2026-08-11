import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/services/zego_service.dart';

/// Represents an incoming call invitation.
class IncomingCall {
  final String callId;
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final bool isVideo;

  const IncomingCall({
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.isVideo,
  });
}

/// Represents an outgoing call (caller is waiting for callee to respond).
class OutgoingCall {
  final String callId;
  final String calleeId;
  final String calleeName;
  final String? calleeAvatar;
  final bool isVideo;

  const OutgoingCall({
    required this.callId,
    required this.calleeId,
    required this.calleeName,
    this.calleeAvatar,
    required this.isVideo,
  });
}

enum CallState {
  idle,
  initiating,
  ringing,
  incoming,
  connecting,
  connected,
  rejected,
  cancelled,
  missed,
  ended,
  failed,
}

/// Manages call signaling state – incoming/outgoing invitations.
class CallProvider extends ChangeNotifier {
  StreamSubscription? _zimSubscription;
  IncomingCall? _incomingCall;
  OutgoingCall? _outgoingCall;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  Timer? _incomingCallTimer; // Auto-dismiss if caller never cancels

  CallState _callState = CallState.idle;
  CallState get callState => _callState;

  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get currentUserAvatar => _currentUserAvatar;

  /// Whether the caller's invitation was declined by the callee.
  bool get wasDeclined => _callState == CallState.rejected;

  /// Whether the callee accepted the call (caller should navigate).
  bool get wasAccepted => _callState == CallState.connected || _callState == CallState.connecting;

  IncomingCall? get incomingCall => _incomingCall;
  bool get hasIncomingCall => _incomingCall != null && _callState == CallState.incoming;

  OutgoingCall? get outgoingCall => _outgoingCall;
  bool get hasOutgoingCall => _outgoingCall != null;

  void configure({required String userId, required String userName}) {
    _currentUserId = userId;
    _currentUserName = userName;
  }

  /// Load current user's avatar from the backend endpoint.
  Future<void> loadUserAvatar() async {
    try {
      final repository = ProfileRepository();
      final images = await repository.getUserImages();
      final primary =
          images.where((img) => img.isPrimary).firstOrNull ??
          images.firstOrNull;
      if (primary != null) {
        _currentUserAvatar = primary.imageUrl;
      }
    } catch (_) {
      // Ignore
    }
  }

  /// Initialize global ZIM listeners on app start
  void initListeners() {
    _zimSubscription?.cancel();
    _zimSubscription = ZegoService.instance.onMessageReceived.listen(
      _handleMessage,
    );
  }

  /// Start listening to ZIM messages for call signaling. Kept for backward compatibility.
  void startListening() {
    initListeners();
  }

  void _updateState(CallState newState) {
    if (_callState == newState) return;
    _callState = newState;
    notifyListeners();
  }

  void _handleMessage(ZegoZIMMessage msg) {
    if (!msg.content.startsWith('{')) return;

    try {
      final data = jsonDecode(msg.content) as Map<String, dynamic>;
      final type = data['type'] as String?;
      if (type == null) return;

      switch (type) {
        case 'call_invite':
          // Dedup: ignore if the same callId is already ringing
          if (_incomingCall?.callId == data['callId'] as String?) break;
          
          // Check if message is stale (older than 45 seconds)
          final now = DateTime.now().millisecondsSinceEpoch;
          final msgTime = msg.timestamp; // msg.timestamp is in ms
          if (now - msgTime > 45000) {
            debugPrint('[CallProvider] Ignored stale call invite from ${msg.fromUserId}');
            break;
          }

          _incomingCall = IncomingCall(
            callId: data['callId'] as String,
            callerId: msg.fromUserId,
            callerName: data['callerName'] as String? ?? 'Unknown',
            callerAvatar: data['callerAvatar'] as String?,
            isVideo: data['isVideo'] as bool? ?? false,
          );
          
          _updateState(CallState.incoming);
          
          // Auto-dismiss after 30 s if caller never sends call_cancel
          _incomingCallTimer?.cancel();
          _incomingCallTimer = Timer(const Duration(seconds: 30), () {
            if (_callState == CallState.incoming) {
              _incomingCall = null;
              _updateState(CallState.missed);
              Future.delayed(const Duration(milliseconds: 500), () => _updateState(CallState.idle));
            }
          });
          break;

        case 'call_decline':
          // Guard: only apply if callId matches our outgoing call
          if (data['callId'] != _outgoingCall?.callId) break;
          _outgoingCall = null;
          _updateState(CallState.rejected);
          Future.delayed(const Duration(milliseconds: 1000), () => _updateState(CallState.idle));
          break;

        case 'call_accept':
          // Guard: only apply if callId matches our outgoing call
          if (data['callId'] != _outgoingCall?.callId) break;
          _updateState(CallState.connected);
          break;

        case 'call_cancel':
          // Guard: only apply if callId matches our incoming call
          if (data['callId'] != _incomingCall?.callId) break;
          _incomingCallTimer?.cancel();
          _incomingCall = null;
          _updateState(CallState.cancelled);
          Future.delayed(const Duration(milliseconds: 500), () => _updateState(CallState.idle));
          break;
      }
    } catch (_) {
      // Not a call-signaling message — ignore.
    }
  }

  /// Generate a unique call ID from two user IDs + current timestamp.
  String generateCallId(String userA, String userB) {
    final ids = [int.parse(userA), int.parse(userB)]..sort();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'call_${ids[0]}_${ids[1]}_$ts';
  }

  /// Caller initiates a call — sends invitation and tracks outgoing state.
  Future<void> initiateCall({
    required String otherUserId,
    required String otherUserName,
    String? calleeAvatar,
    required bool isVideo,
  }) async {
    if (_currentUserId == null) return;
    final callId = generateCallId(_currentUserId!, otherUserId);

    _outgoingCall = OutgoingCall(
      callId: callId,
      calleeId: otherUserId,
      calleeName: otherUserName,
      calleeAvatar: calleeAvatar,
      isVideo: isVideo,
    );
    
    _updateState(CallState.ringing);

    await ZegoService.instance.sendCallInvitation(
      toUserId: otherUserId,
      callerName: _currentUserName ?? 'User $_currentUserId',
      callerAvatar: _currentUserAvatar,
      callId: callId,
      isVideo: isVideo,
    );
  }

  /// Caller cancels the outgoing call.
  void cancelOutgoingCall() {
    if (_outgoingCall == null) return;

    ZegoService.instance.sendCallResponse(
      toUserId: _outgoingCall!.calleeId,
      callId: _outgoingCall!.callId,
      responseType: 'call_cancel',
    );

    _outgoingCall = null;
    _updateState(CallState.cancelled);
    Future.delayed(const Duration(milliseconds: 500), () => _updateState(CallState.idle));
  }

  /// Clear outgoing call state after navigating to call screen.
  void clearOutgoingCall() {
    _outgoingCall = null;
    _updateState(CallState.idle);
  }

  /// Callee accepts the incoming call.
  void acceptCall() {
    if (_incomingCall == null) return;

    ZegoService.instance.sendCallResponse(
      toUserId: _incomingCall!.callerId,
      callId: _incomingCall!.callId,
      responseType: 'call_accept',
    );
    
    _updateState(CallState.connecting);
  }

  /// Clear incoming call state (after navigation or dismissal).
  void clearIncomingCall() {
    _incomingCall = null;
    _updateState(CallState.idle);
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
    _updateState(CallState.rejected);
    Future.delayed(const Duration(milliseconds: 500), () => _updateState(CallState.idle));
  }

  @override
  void dispose() {
    _zimSubscription?.cancel();
    _incomingCallTimer?.cancel();
    super.dispose();
  }

  /// Exposes [_handleMessage] for unit testing without requiring ZIM SDK.
  /// Only call this from test files.
  @visibleForTesting
  void testHandleMessage(ZegoZIMMessage msg) => _handleMessage(msg);
}
