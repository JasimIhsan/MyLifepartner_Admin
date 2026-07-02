import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/guide_item.dart';
import 'package:life_partner_again/services/guide_service.dart';

enum MessageSender { assistant, user }

enum MessageType { text, categories, questions, followUp, thinking }

class ChatMessage {
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final MessageType type;
  final dynamic data;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.type = MessageType.text,
    this.data,
  });
}

class LpaGuideScreen extends StatefulWidget {
  const LpaGuideScreen({super.key});

  @override
  State<LpaGuideScreen> createState() => _LpaGuideScreenState();
}

class _LpaGuideScreenState extends State<LpaGuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _isLoading = true;
  String? _errorMessage;
  int? _currentCategoryId;

  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'About LPA', 'icon': Icons.favorite_outline},
    {'id': 2, 'name': 'Safety & Privacy', 'icon': Icons.security},
    {'id': 3, 'name': 'Account & Trust', 'icon': Icons.verified_user_outlined},
    {'id': 4, 'name': 'Membership', 'icon': Icons.card_membership_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialGuides();
  }

  Future<void> _loadInitialGuides() async {
    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });
    _initializeChat();
  }

  void _initializeChat() {
    _messages.clear();
    _messages.add(
      ChatMessage(
        sender: MessageSender.assistant,
        text:
            'Hi there! I am your LPA Guide Assistant. 🌟\n\nHow can I help you find your life partner with confidence and privacy today? Please select a category to get started:',
        timestamp: DateTime.now(),
      ),
    );
    _messages.add(
      ChatMessage(
        sender: MessageSender.assistant,
        text: '',
        type: MessageType.categories,
        timestamp: DateTime.now(),
      ),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  void _selectCategory(int categoryId, String categoryName) async {
    setState(() {
      _currentCategoryId = categoryId;
      _messages.add(
        ChatMessage(
          sender: MessageSender.user,
          text: categoryName,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    final loadingMsg = ChatMessage(
      sender: MessageSender.assistant,
      text: 'Loading questions for $categoryName...',
      type: MessageType.thinking,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(loadingMsg);
    });
    _scrollToBottom();

    try {
      final categoryItems = await GuideService.getGuides(
        categoryId: categoryId,
      );

      if (!mounted) return;

      setState(() {
        _messages.remove(loadingMsg);
        _messages.add(
          ChatMessage(
            sender: MessageSender.assistant,
            text:
                'Here are the most frequently asked questions about **$categoryName**:',
            timestamp: DateTime.now(),
          ),
        );
        _messages.add(
          ChatMessage(
            sender: MessageSender.assistant,
            text: '',
            type: MessageType.questions,
            data: categoryItems,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.remove(loadingMsg);
        _messages.add(
          ChatMessage(
            sender: MessageSender.assistant,
            text:
                'Failed to load questions. Please check your connection and try again.',
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _selectQuestion(GuideItem item) async {
    setState(() {
      _messages.add(
        ChatMessage(
          sender: MessageSender.user,
          text: item.question,
          timestamp: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    final thinkingMsg = ChatMessage(
      sender: MessageSender.assistant,
      text: 'Thinking...',
      type: MessageType.thinking,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(thinkingMsg);
    });
    _scrollToBottom();

    final startTime = DateTime.now();

    try {
      final detailedItem = await GuideService.getGuideById(item.id);

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final remainingDelay = 1500 - elapsed;

      if (remainingDelay > 500) {
        await Future.delayed(Duration(milliseconds: remainingDelay ~/ 2));
        if (!mounted) return;
        final index = _messages.indexOf(thinkingMsg);
        if (index != -1) {
          setState(() {
            _messages[index] = ChatMessage(
              sender: MessageSender.assistant,
              text: 'Generating answer...',
              type: MessageType.thinking,
              timestamp: DateTime.now(),
            );
          });
        }
        await Future.delayed(Duration(milliseconds: remainingDelay ~/ 2));
      }

      if (!mounted) return;

      setState(() {
        _messages.removeWhere((m) => m.type == MessageType.thinking);
        final finalItem = detailedItem ?? item;
        _messages.add(
          ChatMessage(
            sender: MessageSender.assistant,
            text: finalItem.answer,
            data: finalItem.bullets,
            timestamp: DateTime.now(),
          ),
        );
        _messages.add(
          ChatMessage(
            sender: MessageSender.assistant,
            text: 'What would you like to do next?',
            type: MessageType.followUp,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.type == MessageType.thinking);
        _messages.add(
          ChatMessage(
            sender: MessageSender.assistant,
            text:
                'Sorry, I encountered an error fetching the answer. Please check your connection.',
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _handleSearch(String query) async {
    if (query.trim().isEmpty) return;

    _searchController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages.add(
        ChatMessage(
          sender: MessageSender.user,
          text: query,
          timestamp: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    final searchLoadingMsg = ChatMessage(
      sender: MessageSender.assistant,
      text: 'Searching LPA Help Hub...',
      type: MessageType.thinking,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(searchLoadingMsg);
    });
    _scrollToBottom();

    try {
      final matchingItems = await GuideService.getGuides(search: query);

      if (!mounted) return;

      setState(() {
        _messages.remove(searchLoadingMsg);
        if (matchingItems.isNotEmpty) {
          _messages.add(
            ChatMessage(
              sender: MessageSender.assistant,
              text:
                  'I found ${matchingItems.length} matching question(s) for "$query". Click to read:',
              timestamp: DateTime.now(),
            ),
          );
          _messages.add(
            ChatMessage(
              sender: MessageSender.assistant,
              text: '',
              type: MessageType.questions,
              data: matchingItems,
              timestamp: DateTime.now(),
            ),
          );
        } else {
          _messages.add(
            ChatMessage(
              sender: MessageSender.assistant,
              text:
                  'Sorry, I couldn\'t find any questions matching "$query". Let\'s try selecting a category instead:',
              timestamp: DateTime.now(),
            ),
          );
          _messages.add(
            ChatMessage(
              sender: MessageSender.assistant,
              text: '',
              type: MessageType.categories,
              timestamp: DateTime.now(),
            ),
          );
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.remove(searchLoadingMsg);
        _messages.add(
          ChatMessage(
            sender: MessageSender.assistant,
            text: 'Search failed. Please check your connection.',
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Premium Header Section with assistant profile
        Container(
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
              if (Navigator.of(context).canPop()) ...[
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
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
                onPressed: _initializeChat,
              ),
            ],
          ),
        ),

        // Chat messages or Loading or Error Screen
        Expanded(child: _buildChatBody()),

        // Bottom text field / interaction area
        if (!_isLoading && _errorMessage == null) _buildBottomSearchBar(),
      ],
    );
  }

  Widget _buildChatBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadInitialGuides,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageRow(message);
      },
    );
  }

  Widget _buildMessageRow(ChatMessage message) {
    final isAssistant = message.sender == MessageSender.assistant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: isAssistant
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAssistant) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isAssistant
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                if (message.type == MessageType.text)
                  _buildTextBubble(message, isAssistant)
                else if (message.type == MessageType.categories)
                  _buildCategoriesSelector()
                else if (message.type == MessageType.questions)
                  _buildQuestionsSelector(message.data as List<GuideItem>)
                else if (message.type == MessageType.followUp)
                  _buildFollowUpSelector()
                else if (message.type == MessageType.thinking)
                  _buildThinkingBubble(message.text),
              ],
            ),
          ),
          if (!isAssistant) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingBubble(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(
    String text, {
    required TextStyle style,
    required TextStyle boldStyle,
  }) {
    final parts = text.split('**');
    if (parts.length <= 1) {
      return Text(text, style: style);
    }

    final List<TextSpan> spans = [];
    for (var i = 0; i < parts.length; i++) {
      final isBold = i % 2 == 1;
      spans.add(TextSpan(text: parts[i], style: isBold ? boldStyle : style));
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildTextBubble(ChatMessage message, bool isAssistant) {
    final List<String> bullets = message.data is List<String>
        ? message.data as List<String>
        : [];

    final baseStyle = TextStyle(
      fontSize: 14,
      color: isAssistant ? AppColors.textPrimary : Colors.white,
      height: 1.45,
    );
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isAssistant ? Colors.grey.shade100 : AppColors.primary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isAssistant ? 4 : 16),
          bottomRight: Radius.circular(isAssistant ? 16 : 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFormattedText(
            message.text,
            style: baseStyle,
            boldStyle: boldStyle,
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...bullets.map((bullet) {
              final bulletBaseStyle = TextStyle(
                fontSize: 13.5,
                color: isAssistant
                    ? AppColors.textSecondary
                    : Colors.white.withValues(alpha: 0.9),
                height: 1.35,
              );
              final bulletBoldStyle = bulletBaseStyle.copyWith(
                fontWeight: FontWeight.bold,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, right: 8.0),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isAssistant
                              ? AppColors.primary
                              : Colors.white70,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildFormattedText(
                        bullet,
                        style: bulletBaseStyle,
                        boldStyle: bulletBoldStyle,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoriesSelector() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _categories.map((cat) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  _selectCategory(cat['id'] as int, cat['name'] as String),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionsSelector(List<GuideItem> questions) {
    if (questions.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'No questions found in this category.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: questions.map((q) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _selectQuestion(q),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.question,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFollowUpSelector() {
    final List<Map<String, dynamic>> followUpOptions = [
      {
        'action': 'another_question',
        'text': _currentCategoryId != null
            ? 'Ask another question'
            : 'Show all questions',
        'icon': Icons.chat_bubble_outline_rounded,
      },
      {
        'action': 'change_category',
        'text': 'Change category',
        'icon': Icons.grid_view_rounded,
      },
      {
        'action': 'contact_support',
        'text': 'Contact Support',
        'icon': Icons.mail_outline_rounded,
      },
    ];

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: followUpOptions.map((opt) {
          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (opt['action'] == 'another_question') {
                  if (_currentCategoryId != null) {
                    final catName = _categories.firstWhere(
                      (c) => c['id'] == _currentCategoryId,
                    )['name'];
                    _selectCategory(_currentCategoryId!, catName);
                  } else {
                    _initializeChat();
                  }
                } else if (opt['action'] == 'change_category') {
                  setState(() {
                    _messages.add(
                      ChatMessage(
                        sender: MessageSender.user,
                        text: 'Change Category',
                        timestamp: DateTime.now(),
                      ),
                    );
                  });
                  _scrollToBottom();
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (!mounted) return;
                    setState(() {
                      _messages.add(
                        ChatMessage(
                          sender: MessageSender.assistant,
                          text: 'Sure! Please choose a category:',
                          timestamp: DateTime.now(),
                        ),
                      );
                      _messages.add(
                        ChatMessage(
                          sender: MessageSender.assistant,
                          text: '',
                          type: MessageType.categories,
                          timestamp: DateTime.now(),
                        ),
                      );
                    });
                    _scrollToBottom();
                  });
                } else if (opt['action'] == 'contact_support') {
                  setState(() {
                    _messages.add(
                      ChatMessage(
                        sender: MessageSender.user,
                        text: 'Contact Support',
                        timestamp: DateTime.now(),
                      ),
                    );
                  });
                  _scrollToBottom();
                  Future.delayed(const Duration(milliseconds: 600), () {
                    if (!mounted) return;
                    setState(() {
                      _messages.add(
                        ChatMessage(
                          sender: MessageSender.assistant,
                          text:
                              'You can reach out to our customer support team directly at support@mylifepartner.com, or tap the button below to compose an email.',
                          timestamp: DateTime.now(),
                        ),
                      );
                    });
                    _scrollToBottom();
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt['text'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomSearchBar() {
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
                  controller: _searchController,
                  onSubmitted: _handleSearch,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Type your question or search term...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
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
              onTap: () => _handleSearch(_searchController.text),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
