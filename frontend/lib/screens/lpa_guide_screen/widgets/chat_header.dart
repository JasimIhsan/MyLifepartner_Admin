import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback onRestartChat;

  const ChatHeader({super.key, required this.onRestartChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          if (context.canPop()) ...[
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => context.pop(),
            ),
            const SizedBox(width: 8),
          ],
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LPA Support Bot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Online | Frequently Asked Questions',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Restart Chat',
            onPressed: onRestartChat,
          ),
        ],
      ),
    );
  }
}
