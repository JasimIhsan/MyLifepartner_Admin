import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/profile_question.dart';

class QuestionWidget extends StatefulWidget {
  final ProfileQuestion question;
  final dynamic currentAnswer;
  final ValueChanged<dynamic> onAnswerChanged;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    String initialText = '';
    if (widget.currentAnswer is String) {
      initialText = widget.currentAnswer;
    }
    _textController = TextEditingController(text: initialText);
  }

  @override
  void didUpdateWidget(QuestionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If question changed, reset everything
    if (oldWidget.question.id != widget.question.id) {
      _textController.dispose();
      _initializeController();
    } else {
      // If answer changed externally (or we just typed), sync if needed
      if (widget.currentAnswer != oldWidget.currentAnswer) {
        if (widget.question.answerType == AnswerType.text) {
          String newText = '';
          if (widget.currentAnswer is String) {
            newText = widget.currentAnswer;
          }

          // ONLY update if the text is actually different.
          // This prevents cursor jumping when specific keystrokes trigger parent rebuilds.
          if (_textController.text != newText) {
            _textController.text = newText;
            // We can technically lose cursor position here if external update happens
            // while typing, but in this app flow, updates are echoes of typing.
            // If we typed 'A', controller has 'A', parent sends back 'A'.
            // condition 'A' != 'A' is false, so we DO NOT touch controller. Cursor safe.
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.question.question,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.question.minWords != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Minimum ${widget.question.minWords} words required.",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "Current: ${_getWordCount(widget.currentAnswer)}",
                  style: TextStyle(
                    color:
                        _getWordCount(widget.currentAnswer) >=
                            widget.question.minWords!
                        ? AppColors.success
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        _buildAnswerInput(),
      ],
    );
  }

  int _getWordCount(dynamic answer) {
    if (answer is! String || answer.isEmpty) return 0;
    return (answer)
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .length;
  }

  Widget _buildAnswerInput() {
    switch (widget.question.answerType) {
      case AnswerType.text:
        return _buildTextInput();
      case AnswerType.singleChoice:
        return _buildSingleChoiceInput();
      case AnswerType.multiChoice:
        return _buildMultiChoiceInput();
      case AnswerType.rating:
        return _buildRatingInput();
      case AnswerType.boolean:
        return _buildBooleanInput();
    }
  }

  Widget _buildTextInput() {
    return TextField(
      onChanged: widget.onAnswerChanged,
      controller: _textController,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Type your answer here...",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildSingleChoiceInput() {
    return Column(
      children: widget.question.options!.map((option) {
        final isSelected = widget.currentAnswer == option;
        return GestureDetector(
          onTap: () => widget.onAnswerChanged(option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.check_circle, color: AppColors.primary),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceInput() {
    // Placeholder for multi-choice
    return const Text("Multi-choice not implemented yet");
  }

  Widget _buildRatingInput() {
    // 1-5 Rating
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = widget.currentAnswer == rating;
        return GestureDetector(
          onTap: () => widget.onAnswerChanged(rating),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderColor,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rating.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBooleanInput() {
    return Column(
      children: [
        _buildBooleanOption("Yes", true),
        _buildBooleanOption("No", false),
      ],
    );
  }

  Widget _buildBooleanOption(String label, bool value) {
    final isSelected = widget.currentAnswer == value;
    return GestureDetector(
      onTap: () => widget.onAnswerChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Icon(Icons.check_circle, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
