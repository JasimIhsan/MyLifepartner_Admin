import 'package:flutter/material.dart';
import '../../core/responsive/adaptive_screen.dart';
import 'mobile/mobile_chat_screen.dart';
import 'web/web_chat_screen.dart';

class ChatPlaceholderScreen extends StatelessWidget {
  const ChatPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveScreen(
      mobile: MobileChatScreen(),
      web: WebChatScreen(),
    );
  }
}
