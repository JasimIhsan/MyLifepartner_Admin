import 'dart:async';

import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/guide_category.dart';
import 'package:life_partner_again/models/guide_item.dart';
import 'package:life_partner_again/services/guide_service.dart';

import 'widgets/category_selector.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_message_bubble.dart';
import 'widgets/chat_search_bar.dart';
import 'widgets/follow_up_selector.dart';
import 'widgets/question_selector.dart';

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
  bool _isResponding = false;
  List<GuideCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadInitialGuides();
  }

  Future<void> _loadInitialGuides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await GuideService.getGuideCategories();

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _isLoading = false;
        _errorMessage = null;
        _resetChatMessages();
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Failed to load guide categories. Please check your connection and try again.';
      });
    }
  }

  void _initializeChat() {
    setState(_resetChatMessages);
    _scrollToBottom();
  }

  void _resetChatMessages() {
    _isResponding = false;
    _currentCategoryId = null;
    _messages.clear();
    _messages.add(
      ChatMessage(
        sender: MessageSender.assistant,
        text: _categories.isEmpty
            ? 'Welcome to Find Your Self! ✨\n\nOur guide is temporarily unavailable. Please check your connection and try again.'
            : 'Welcome to Find Your Self! ✨\n\nI\'m here to help you navigate your journey to finding your life partner with confidence and clarity. Select a topic below to get started:',
        timestamp: DateTime.now(),
      ),
    );
    if (_categories.isNotEmpty) {
      _messages.add(
        ChatMessage(
          sender: MessageSender.assistant,
          text: '',
          type: MessageType.categories,
          timestamp: DateTime.now(),
        ),
      );
    }
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
    if (_isResponding) return;
    setState(() {
      _isResponding = true;
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
        _isResponding = false;
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
        _isResponding = false;
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
    if (_isResponding) return;
    setState(() {
      _isResponding = true;
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
    ChatMessage currentThinkingMsg = thinkingMsg;

    try {
      final detailedItem = await GuideService.getGuideById(item.id);

      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final remainingDelay = 1500 - elapsed;

      if (remainingDelay > 500) {
        await Future.delayed(Duration(milliseconds: remainingDelay ~/ 2));
        if (!mounted) return;
        final index = _messages.indexOf(currentThinkingMsg);
        if (index != -1) {
          final newThinkingMsg = ChatMessage(
            sender: MessageSender.assistant,
            text: 'Generating answer...',
            type: MessageType.thinking,
            timestamp: DateTime.now(),
          );
          setState(() {
            _messages[index] = newThinkingMsg;
            currentThinkingMsg = newThinkingMsg;
          });
        }
        await Future.delayed(Duration(milliseconds: remainingDelay ~/ 2));
      }

      if (!mounted) return;

      setState(() {
        _isResponding = false;
        _messages.remove(currentThinkingMsg);
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
        _isResponding = false;
        _messages.remove(currentThinkingMsg);
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
    if (_isResponding) return;

    _searchController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _isResponding = true;
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
        _isResponding = false;
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
          if (_categories.isNotEmpty) {
            _messages.add(
              ChatMessage(
                sender: MessageSender.assistant,
                text: '',
                type: MessageType.categories,
                timestamp: DateTime.now(),
              ),
            );
          }
        }
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isResponding = false;
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

  void _handleFollowUpOption(String action) {
    if (_isResponding) return;
    if (action == 'another_question') {
      if (_currentCategoryId != null) {
        final category = _findCategoryById(_currentCategoryId!);
        if (category != null) {
          _selectCategory(_currentCategoryId!, category.name);
        } else {
          _initializeChat();
        }
      } else {
        _initializeChat();
      }
    } else if (action == 'change_category') {
      setState(() {
        _isResponding = true;
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
          _isResponding = false;
          _messages.add(
            ChatMessage(
              sender: MessageSender.assistant,
              text: 'Sure! Please choose a category:',
              timestamp: DateTime.now(),
            ),
          );
          if (_categories.isNotEmpty) {
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
      });
    } else if (action == 'contact_support') {
      setState(() {
        _isResponding = true;
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
          _isResponding = false;
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
  }

  GuideCategory? _findCategoryById(int categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) {
        return category;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/chat_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.06)),
          ),
          Column(
            children: [
              // Premium Header Section with assistant profile
              ChatHeader(onRestartChat: _initializeChat),

              // Chat messages or Loading or Error Screen
              Expanded(child: _buildChatBody()),

              // Bottom text field / interaction area
              if (!_isLoading && _errorMessage == null)
                ChatSearchBar(
                  controller: _searchController,
                  onSubmitted: _handleSearch,
                  enabled: !_isResponding,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadInitialGuides,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
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

    if (message.type == MessageType.text ||
        message.type == MessageType.thinking) {
      return ChatMessageBubble(message: message);
    }

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
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.support_agent_rounded,
                color: Theme.of(context).primaryColor,
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
                if (message.type == MessageType.categories)
                  CategorySelector(
                    categories: _categories,
                    onSelectCategory: _selectCategory,
                    enabled: !_isResponding,
                  )
                else if (message.type == MessageType.questions)
                  QuestionSelector(
                    questions: message.data as List<GuideItem>,
                    onSelectQuestion: _selectQuestion,
                    enabled: !_isResponding,
                  )
                else if (message.type == MessageType.followUp)
                  FollowUpSelector(
                    hasCurrentCategory: _currentCategoryId != null,
                    onSelectOption: _handleFollowUpOption,
                    enabled: !_isResponding,
                  ),
              ],
            ),
          ),
          if (!isAssistant) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                Icons.person_outline_rounded,
                color: Theme.of(context).primaryColor,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
