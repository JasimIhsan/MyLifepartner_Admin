import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';

class ChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String query) onSubmitted;
  final bool enabled;

  const ChatSearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  onSubmitted: enabled ? onSubmitted : null,
                  textInputAction: TextInputAction.send,
                  enabled: enabled,
                  decoration: InputDecoration(
                    hintText: 'Type your question or search term...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color ?? AppColors.textLight,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? () => onSubmitted(controller.text) : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: enabled ? 1.0 : 0.5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}