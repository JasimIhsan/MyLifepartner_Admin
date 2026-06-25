import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:zego_zim/zego_zim.dart';
import 'package:mylifepartner/config/env.dart';

/// Singleton service to manage ZEGOCLOUD ZIM (In-app Messaging) lifecycle.
class ZegoService {
  ZegoService._();
  static final ZegoService instance = ZegoService._();

  final _messageController = StreamController<ZegoZIMMessage>.broadcast();
  Stream<ZegoZIMMessage> get onMessageReceived => _messageController.stream;

  bool _isInitialized = false;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  /// Initialize ZIM with app credentials. Call once at app startup.
  void init() {
    if (_isInitialized) return;

    final appConfig = ZIMAppConfig()
      ..appID = Env.zegoAppId
      ..appSign = Env.zegoAppSign;

    ZIM.create(appConfig);
    _isInitialized = true;
    _setupEventHandlers();
    debugPrint('[ZegoService] ZIM initialized');
  }

  ZIM _getZIM() {
    final zim = ZIM.getInstance();
    if (zim == null) {
      debugPrint('[ZegoService] ZIM instance is null, re-initializing...');
      _isInitialized = false;
      init();
      final retryZim = ZIM.getInstance();
      if (retryZim == null) {
        throw StateError(
          'ZIM native instance not available. '
          'Check zegoAppId (${Env.zegoAppId}) and zegoAppSign.',
        );
      }
      return retryZim;
    }
    return zim;
  }

  void _setupEventHandlers() {
    ZIMEventHandler.onPeerMessageReceived = (
      ZIM zim,
      List<ZIMMessage> messageList,
      ZIMMessageReceivedInfo info,
      String fromUserID,
    ) {
      for (final msg in messageList) {
        String content = '';
        String messageType = 'TEXT';

        if (msg is ZIMTextMessage) {
          content = msg.message;
        } else if (msg is ZIMMediaMessage) {
          content = msg.fileDownloadUrl;
          if (msg is ZIMImageMessage) {
            messageType = 'IMAGE';
          } else if (msg is ZIMAudioMessage) {
            messageType = 'AUDIO';
          } else if (msg is ZIMVideoMessage) {
            messageType = 'VIDEO';
          } else {
            messageType = 'FILE';
          }
        }

        _messageController.add(ZegoZIMMessage(
          messageID: msg.messageID.toString(),
          fromUserId: fromUserID,
          content: content,
          messageType: messageType,
          timestamp: msg.timestamp,
        ));
      }
    };
  }

  /// Log in to ZIM. userId must be a string representation of the app user ID.
  Future<void> login(String userId, String userName) async {
    if (_isLoggedIn) return;

    final zim = _getZIM();
    final loginConfig = ZIMLoginConfig()..userName = userName;

    try {
      await zim.login(userId, loginConfig);
      _isLoggedIn = true;
      debugPrint('[ZegoService] Logged in as $userId');
    } catch (e) {
      debugPrint('[ZegoService] Login failed: $e');
      rethrow;
    }
  }

  /// Send a peer text message via ZIM.
  Future<ZIMMessageSentResult?> sendMessage(
    String toUserId,
    String content,
  ) async {
    if (!_isLoggedIn) {
      debugPrint('[ZegoService] Not logged in, cannot send message');
      return null;
    }
    debugPrint('[ZegoService] isLoggedIn=$_isLoggedIn, sending...');

    final zim = _getZIM();
    final textMessage = ZIMTextMessage(message: content);
    final sendConfig = ZIMMessageSendConfig();
    final notification = ZIMMessageSendNotification(
      onMessageAttached: (message) {
        debugPrint('[ZegoService] Message attached, id: ${message.messageID}');
      },
    );

    debugPrint('[ZegoService] Sending to: "$toUserId", content length: ${content.length}');

    try {
      final result = await zim.sendMessage(
        textMessage,
        toUserId,
        ZIMConversationType.peer,
        sendConfig,
        notification,
      );
      return result;
    } catch (e) {
      // ZIM errors like "peer user not exist" (109001) should not block
      // messaging — messages will still be persisted to the backend.
      debugPrint('[ZegoService] ZIM send failed (non-fatal): $e');
      return null;
    }
  }

  /// Send a media message via ZIM (uploads file automatically).
  Future<ZIMMessageSentResult?> sendMediaMessage(
    String toUserId,
    ZIMMediaMessage mediaMessage,
  ) async {
    if (!_isLoggedIn) {
      debugPrint('[ZegoService] Not logged in, cannot send media message');
      return null;
    }

    final zim = _getZIM();
    final sendConfig = ZIMMessageSendConfig();

    try {
      // ignore: deprecated_member_use
      final result = await zim.sendMediaMessage(
        mediaMessage,
        toUserId,
        ZIMConversationType.peer,
        sendConfig,
        ZIMMediaMessageSendNotification(
          onMessageAttached: (message) {},
          onMediaUploadingProgress: (message, currentFileSize, totalFileSize) {},
        ),
      );
      return result;
    } catch (e) {
      debugPrint('[ZegoService] ZIM media send failed (non-fatal): $e');
      return null;
    }
  }

  // ─── Call Signaling ──────────────────────────────────────────────────────

  /// Send a call invitation signal via ZIM.
  Future<void> sendCallInvitation({
    required String toUserId,
    required String callerName,
    String? callerAvatar,
    required String callId,
    required bool isVideo,
  }) async {
    final payload = jsonEncode({
      'type': 'call_invite',
      'callId': callId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'isVideo': isVideo,
    });
    await sendMessage(toUserId, payload);
  }

  /// Send a call response signal (accept / decline / cancel).
  Future<void> sendCallResponse({
    required String toUserId,
    required String callId,
    required String responseType,
  }) async {
    final payload = jsonEncode({
      'type': responseType,
      'callId': callId,
    });
    await sendMessage(toUserId, payload);
  }

  /// Logout and cleanup
  Future<void> logout() async {
    try {
      ZIM.getInstance()?.logout();
      _isLoggedIn = false;
      debugPrint('[ZegoService] Logged out');
    } catch (e) {
      debugPrint('[ZegoService] Logout failed: $e');
    }
  }

  void destroy() {
    _messageController.close();
    ZIM.getInstance()?.destroy();
    _isInitialized = false;
    _isLoggedIn = false;
  }
}

/// Simple wrapper for incoming ZIM messages
class ZegoZIMMessage {
  final String messageID;
  final String fromUserId;
  final String content;
  final String messageType;
  final int timestamp;

  ZegoZIMMessage({
    required this.messageID,
    required this.fromUserId,
    required this.content,
    required this.messageType,
    required this.timestamp,
  });
}
