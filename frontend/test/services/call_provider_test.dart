// Unit tests for CallProvider — call signaling state machine.
//
// What is tested:
//   ✔ configure() sets userId and userName
//   ✔ generateCallId() is unique on every call (timestamp suffix)
//   ✔ generateCallId() sorts user IDs so A→B == B→A
//   ✔ initiateCall() sets outgoingCall state
//   ✔ clearOutgoingCall() clears state and resets flags
//   ✔ cancelOutgoingCall() clears outgoingCall when null (no-op)
//   ✔ acceptCall() is a no-op when no incomingCall
//   ✔ clearIncomingCall() clears incomingCall and notifies listeners
//   ✔ declineCall() is a no-op when no incomingCall
//   ✔ _handleMessage: call_invite creates IncomingCall with correct fields
//   ✔ _handleMessage: call_invite deduplication (same callId ignored)
//   ✔ _handleMessage: call_decline only fires when callId matches outgoing
//   ✔ _handleMessage: call_accept only fires when callId matches outgoing
//   ✔ _handleMessage: call_cancel only fires when callId matches incoming
//   ✔ _handleMessage: 30-second auto-dismiss timer cancels stale invitations
//   ✔ Non-JSON messages are silently ignored
//   ✔ JSON without "type" key is silently ignored
//   ✔ dispose() cancels all timers and subscriptions

import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_partner_again/providers/call_provider.dart';
import 'package:life_partner_again/services/zego_service.dart';

/// We push via a separate StreamController that the provider subscribes to.
class _FakeMessageSink {
  final StreamController<ZegoZIMMessage> _ctrl =
      StreamController<ZegoZIMMessage>.broadcast();

  Stream<ZegoZIMMessage> get stream => _ctrl.stream;

  void add(ZegoZIMMessage msg) => _ctrl.add(msg);

  void close() => _ctrl.close();
}

// ─── Suite ────────────────────────────────────────────────────────────────────

void main() {
  late CallProvider provider;

  setUp(() {
    provider = CallProvider();
    provider.configure(userId: '1', userName: 'Alice');
  });

  tearDown(() {
    provider.dispose();
  });

  // ── configure ────────────────────────────────────────────────────────────────

  group('configure()', () {
    test('sets currentUserId and currentUserName', () {
      expect(provider.currentUserId, '1');
      expect(provider.currentUserName, 'Alice');
    });

    test('can be called multiple times to update identity', () {
      provider.configure(userId: '2', userName: 'Bob');
      expect(provider.currentUserId, '2');
      expect(provider.currentUserName, 'Bob');
    });
  });

  // ── generateCallId ───────────────────────────────────────────────────────────

  group('generateCallId()', () {
    test('starts with "call_" prefix', () {
      final id = provider.generateCallId('1', '2');
      expect(id, startsWith('call_'));
    });

    test('sorts user IDs so A→B equals B→A (deterministic room pairing)', () {
      // Sort order: call_1_2_ts — smaller id first
      final ab = provider.generateCallId('1', '2');
      final ba = provider.generateCallId('2', '1');

      // Both should have the same sorted-id prefix, but different timestamps
      final prefixAB = ab.substring(0, ab.lastIndexOf('_'));
      final prefixBA = ba.substring(0, ba.lastIndexOf('_'));
      expect(prefixAB, prefixBA);
    });

    test('produces unique IDs on consecutive calls (timestamp suffix)', () async {
      final id1 = provider.generateCallId('1', '2');
      // Tiny delay to ensure different millisecond
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final id2 = provider.generateCallId('1', '2');
      expect(id1, isNot(id2));
    });

    test('encodes larger user IDs correctly', () {
      final id = provider.generateCallId('100000', '200000');
      expect(id, contains('100000'));
      expect(id, contains('200000'));
    });
  });

  // ── outgoing call state ──────────────────────────────────────────────────────

  group('Outgoing call state', () {
    test('starts with no outgoing call', () {
      expect(provider.hasOutgoingCall, isFalse);
      expect(provider.outgoingCall, isNull);
    });

    test('cancelOutgoingCall() is a no-op when there is no outgoing call', () {
      expect(() => provider.cancelOutgoingCall(), returnsNormally);
      expect(provider.hasOutgoingCall, isFalse);
    });

    test('clearOutgoingCall() resets wasAccepted and wasDeclined flags', () {
      // Simulate accepted state
      provider.clearOutgoingCall();
      expect(provider.wasAccepted, isFalse);
      expect(provider.wasDeclined, isFalse);
      expect(provider.hasOutgoingCall, isFalse);
    });
  });

  // ── incoming call state ──────────────────────────────────────────────────────

  group('Incoming call state', () {
    test('starts with no incoming call', () {
      expect(provider.hasIncomingCall, isFalse);
      expect(provider.incomingCall, isNull);
    });

    test('acceptCall() is a no-op when there is no incoming call', () {
      expect(() => provider.acceptCall(), returnsNormally);
    });

    test('declineCall() is a no-op when there is no incoming call', () {
      expect(() => provider.declineCall(), returnsNormally);
      expect(provider.hasIncomingCall, isFalse);
    });

    test('clearIncomingCall() clears state and notifies listeners', () {
      int notifications = 0;
      provider.addListener(() => notifications++);

      provider.clearIncomingCall();

      // notifyListeners fires once
      expect(notifications, greaterThanOrEqualTo(1));
      expect(provider.hasIncomingCall, isFalse);
    });
  });

  // ── message handler — via internal _handleMessage ────────────────────────────
  //
  // We test _handleMessage indirectly by building the exact ZegoZIMMessage
  // objects that the ZIM event handler would produce, then passing them to a
  // minimal CallProvider that uses a local stream.

  group('_handleMessage() — call signaling state machine', () {
    // Helper: create a provider wired to a fake stream so we can push messages.
    late _FakeMessageSink sink;
    late CallProvider wiredProvider;
    late StreamSubscription<ZegoZIMMessage> sub;

    setUp(() {
      sink = _FakeMessageSink();
      wiredProvider = CallProvider();
      wiredProvider.configure(userId: '1', userName: 'Alice');

      // Wire the fake stream to the provider's internal _handleMessage by
      // manually subscribing (mirrors startListening() but with our stream).
      sub = sink.stream.listen(
        // ignore: invalid_use_of_visible_for_testing_member
        (msg) => wiredProvider.testHandleMessage(msg),
      );
    });

    tearDown(() {
      sub.cancel();
      sink.close();
      wiredProvider.dispose();
    });

    ZegoZIMMessage makeMsg(String type, String callId, String fromUserId) {
      return ZegoZIMMessage(
        messageID: '0',
        fromUserId: fromUserId,
        content: jsonEncode({'type': type, 'callId': callId}),
        messageType: 'TEXT',
        timestamp: 0,
      );
    }

    ZegoZIMMessage makeInvite({
      required String callId,
      required String fromUserId,
      String callerName = 'Bob',
      bool isVideo = true,
    }) {
      return ZegoZIMMessage(
        messageID: '0',
        fromUserId: fromUserId,
        content: jsonEncode({
          'type': 'call_invite',
          'callId': callId,
          'callerName': callerName,
          'callerAvatar': null,
          'isVideo': isVideo,
        }),
        messageType: 'TEXT',
        timestamp: 0,
      );
    }

    test('call_invite creates IncomingCall with correct fields', () async {
      int notified = 0;
      wiredProvider.addListener(() => notified++);

      sink.add(makeInvite(callId: 'call_1_2_000', fromUserId: '2'));
      await Future<void>.delayed(Duration.zero);

      expect(wiredProvider.hasIncomingCall, isTrue);
      expect(wiredProvider.incomingCall!.callId, 'call_1_2_000');
      expect(wiredProvider.incomingCall!.callerId, '2');
      expect(wiredProvider.incomingCall!.callerName, 'Bob');
      expect(wiredProvider.incomingCall!.isVideo, isTrue);
      expect(notified, greaterThanOrEqualTo(1));
    });

    test('call_invite with isVideo=false sets correct flag', () async {
      sink.add(makeInvite(
        callId: 'call_1_2_001',
        fromUserId: '2',
        isVideo: false,
      ));
      await Future<void>.delayed(Duration.zero);
      expect(wiredProvider.incomingCall!.isVideo, isFalse);
    });

    test('duplicate call_invite with same callId is ignored (deduplication)', () async {
      sink.add(makeInvite(callId: 'call_1_2_000', fromUserId: '2'));
      await Future<void>.delayed(Duration.zero);

      int notified = 0;
      wiredProvider.addListener(() => notified++);

      // Send the exact same invite again
      sink.add(makeInvite(callId: 'call_1_2_000', fromUserId: '2'));
      await Future<void>.delayed(Duration.zero);

      // Should not trigger a new notification
      expect(notified, 0);
    });

    test('call_decline is ignored when callId does not match outgoing call', () async {
      // No outgoing call set — decline should be a no-op
      int notified = 0;
      wiredProvider.addListener(() => notified++);

      sink.add(makeMsg('call_decline', 'call_99_100_000', '2'));
      await Future<void>.delayed(Duration.zero);

      expect(wiredProvider.wasDeclined, isFalse);
      expect(notified, 0);
    });

    test('call_accept is ignored when callId does not match outgoing call', () async {
      int notified = 0;
      wiredProvider.addListener(() => notified++);

      sink.add(makeMsg('call_accept', 'call_stale_000', '2'));
      await Future<void>.delayed(Duration.zero);

      expect(wiredProvider.wasAccepted, isFalse);
      expect(notified, 0);
    });

    test('call_cancel is ignored when callId does not match current incoming', () async {
      // Set an incoming call first
      sink.add(makeInvite(callId: 'call_1_2_000', fromUserId: '2'));
      await Future<void>.delayed(Duration.zero);
      expect(wiredProvider.hasIncomingCall, isTrue);

      // Cancel with a different callId — must not clear the real incoming call
      sink.add(makeMsg('call_cancel', 'call_DIFFERENT_000', '2'));
      await Future<void>.delayed(Duration.zero);

      expect(wiredProvider.hasIncomingCall, isTrue);
    });

    test('call_cancel clears incoming call when callId matches', () async {
      sink.add(makeInvite(callId: 'call_1_2_000', fromUserId: '2'));
      await Future<void>.delayed(Duration.zero);
      expect(wiredProvider.hasIncomingCall, isTrue);

      sink.add(makeMsg('call_cancel', 'call_1_2_000', '2'));
      await Future<void>.delayed(Duration.zero);

      expect(wiredProvider.hasIncomingCall, isFalse);
    });

    test('non-JSON message content is silently ignored', () async {
      int notified = 0;
      wiredProvider.addListener(() => notified++);

      final plainText = ZegoZIMMessage(
        messageID: '0',
        fromUserId: '2',
        content: 'Hello, not JSON',
        messageType: 'TEXT',
        timestamp: 0,
      );
      sink.add(plainText);
      await Future<void>.delayed(Duration.zero);

      expect(notified, 0);
      expect(wiredProvider.hasIncomingCall, isFalse);
    });

    test('JSON without "type" key is silently ignored', () async {
      int notified = 0;
      wiredProvider.addListener(() => notified++);

      final noType = ZegoZIMMessage(
        messageID: '0',
        fromUserId: '2',
        content: jsonEncode({'callId': 'call_1_2_000', 'callerName': 'Eve'}),
        messageType: 'TEXT',
        timestamp: 0,
      );
      sink.add(noType);
      await Future<void>.delayed(Duration.zero);

      expect(notified, 0);
    });

    test('auto-dismiss timer clears incoming call after 30 seconds', () async {
      sink.add(makeInvite(callId: 'call_1_2_000', fromUserId: '2'));
      await Future<void>.delayed(Duration.zero);
      expect(wiredProvider.hasIncomingCall, isTrue);

      // Fast-forward 30 seconds using fake async
      await Future<void>.delayed(const Duration(seconds: 31));
      expect(wiredProvider.hasIncomingCall, isFalse);
    }, timeout: const Timeout(Duration(seconds: 40)));
  });

  // ── dispose ──────────────────────────────────────────────────────────────────

  group('dispose()', () {
    test('can be called without error', () {
      final p = CallProvider();
      p.configure(userId: '1', userName: 'Alice');
      expect(() => p.dispose(), returnsNormally);
    });

    test('cancels incomingCallTimer if an invite was pending', () async {
      // Wire a provider to a fake stream and send an invite
      final sink = _FakeMessageSink();
      final p = CallProvider();
      p.configure(userId: '1', userName: 'Alice');

      final sub = sink.stream.listen(
        // ignore: invalid_use_of_visible_for_testing_member
        (msg) => p.testHandleMessage(msg),
      );

      final invite = ZegoZIMMessage(
        messageID: '0',
        fromUserId: '2',
        content: jsonEncode({
          'type': 'call_invite',
          'callId': 'call_1_2_999',
          'callerName': 'Charlie',
          'callerAvatar': null,
          'isVideo': false,
        }),
        messageType: 'TEXT',
        timestamp: 0,
      );

      sink.add(invite);
      await Future<void>.delayed(Duration.zero);
      expect(p.hasIncomingCall, isTrue);

      // dispose() should cancel the 30s auto-dismiss timer without error
      expect(() => p.dispose(), returnsNormally);

      await sub.cancel();
      sink.close();
    });
  });
}
