import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:life_partner_again/services/zego_service.dart';
import 'package:life_partner_again/services/profile_repository.dart';

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

/// Manages call signaling state – incoming/outgoing invitations.
class CallProvider extends ChangeNotifier {
  StreamSubscription? _zimSubscription;
  IncomingCall? _incomingCall;
  OutgoingCall? _outgoingCall;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;

  String? get currentUserId => _currentUserId;
  String? get currentUserName => _currentUserName;
  String? get currentUserAvatar => _currentUserAvatar;

  /// Whether the caller's invitation was declined by the callee.
  bool _wasDeclined = false;
  bool get wasDeclined => _wasDeclined;

  /// Whether the callee accepted the call (caller should navigate).
  bool _wasAccepted = false;
  bool get wasAccepted => _wasAccepted;

  IncomingCall? get incomingCall => _incomingCall;
  bool get hasIncomingCall => _incomingCall != null;

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

  /// Start listening to ZIM messages for call signaling.
  void startListening() {
    _zimSubscription?.cancel();
    _zimSubscription = ZegoService.instance.onMessageReceived.listen(
      _handleMessage,
    );
  }

  void _handleMessage(ZegoZIMMessage msg) {
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
            callerAvatar: data['callerAvatar'] as String?,
            isVideo: data['isVideo'] as bool? ?? false,
          );
          notifyListeners();
          break;

        case 'call_decline':
          // Callee declined — caller sees feedback.
          _wasDeclined = true;
          _outgoingCall = null;
          notifyListeners();
          break;

        case 'call_accept':
          // Callee accepted — caller navigates to call screen.
          _wasAccepted = true;
          notifyListeners();
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
    _wasDeclined = false;
    _wasAccepted = false;
    notifyListeners();

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
    notifyListeners();
  }

  /// Clear outgoing call state after navigating to call screen.
  void clearOutgoingCall() {
    _outgoingCall = null;
    _wasAccepted = false;
    _wasDeclined = false;
    notifyListeners();
  }

  /// Callee accepts the incoming call.
  void acceptCall() {
    if (_incomingCall == null) return;

    ZegoService.instance.sendCallResponse(
      toUserId: _incomingCall!.callerId,
      callId: _incomingCall!.callId,
      responseType: 'call_accept',
    );
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

  @override
  void dispose() {
    _zimSubscription?.cancel();
    super.dispose();
  }
}
