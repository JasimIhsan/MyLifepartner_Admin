import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/models/profile_question.dart';
import 'package:life_partner_again/models/profile_section.dart';
import 'package:life_partner_again/screens/questionaire_screen/widgets/question_widget.dart';
import 'package:life_partner_again/services/profile_repository.dart';
import 'package:life_partner_again/widgets/custom_app_bar.dart';
import 'package:life_partner_again/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionaireScreen extends StatefulWidget {
  final bool isPrimaryFlow;
  final int? initialSectionOrder;

  const QuestionaireScreen({
    super.key,
    this.isPrimaryFlow = true,
    this.initialSectionOrder,
  });

  @override
  State<QuestionaireScreen> createState() => _QuestionaireScreenState();
}

class _QuestionaireScreenState extends State<QuestionaireScreen> {
  final ProfileRepository _repository = ProfileRepository();
  List<ProfileQuestion> _questions = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  int _currentSectionOrder = 1;
  int _currentIndex = 0;

  // Stores answer for current question temporarily until saved/moved next
  dynamic _currentAnswer;

  // Cache answers to show them if user goes back (optional, but good UX)
  // Map<questionId, answer>
  final Map<int, dynamic> _answers = {};

  List<ProfileSection> _allSections = [];
  List<ProfileSection> _activeSections = [];

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch total sections first (or in parallel)
    try {
      _allSections = await _repository.getSections(); // Fetch all, then filter
      if (widget.isPrimaryFlow) {
        _activeSections = _allSections.where((s) => s.isPrimary).toList();
      } else {
        _activeSections = _allSections.where((s) => !s.isPrimary).toList();
      }
      _activeSections.sort((a, b) => a.orderNo.compareTo(b.orderNo));
    } catch (e) {
      debugPrint("Failed to fetch sections: $e");
    }

    if (widget.initialSectionOrder != null) {
      _currentSectionOrder = widget.initialSectionOrder!;
    } else {
      int? savedSection = prefs.getInt(
        widget.isPrimaryFlow ? 'currentSectionOrder' : 'nonPrimarySectionOrder',
      );
      if (savedSection != null) {
        _currentSectionOrder = savedSection;
      } else if (_activeSections.isNotEmpty) {
        _currentSectionOrder = _activeSections.first.orderNo;
      }
    }
    _fetchQuestions();
  }

  bool _isFirstLoad = true;

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _repository.getQuestions(_currentSectionOrder);

      // 1. Check if questions list is empty
      if (questions.isEmpty) {
        // If for section > 1, means we are done.
        if (_currentSectionOrder > 1) {
          _handleCompletion(silent: _isFirstLoad);
          return;
        } else {
          setState(() {
            _errorMessage = "No questions found.";
            _isLoading = false;
          });
          return;
        }
      }

      // 2. Check if THIS section is fully completed
      bool allAnswered = true;
      for (final q in questions) {
        if (q.savedAnswer == null) {
          allAnswered = false;
          break;
        }
      }

      // 3. If fully answered, auto-advance to next section (Recursive)
      if (allAnswered) {
        // Cache answers just in case we need them or for back nav (optional)
        for (final q in questions) {
          _answers[q.id] = q.savedAnswer;
        }

        final currentIndex = _activeSections.indexWhere(
          (s) => s.orderNo == _currentSectionOrder,
        );
        if (currentIndex != -1 && currentIndex < _activeSections.length - 1) {
          _currentSectionOrder = _activeSections[currentIndex + 1].orderNo;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            widget.isPrimaryFlow
                ? 'currentSectionOrder'
                : 'nonPrimarySectionOrder',
            _currentSectionOrder,
          );

          // Recursive call to get next section
          if (mounted) {
            await _fetchQuestions();
          }
        } else {
          _handleCompletion(silent: _isFirstLoad);
        }
        return;
      }

      // 4. If NOT fully answered, show this section
      int firstUnansweredIndex = -1;
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        if (q.savedAnswer != null) {
          _answers[q.id] = q.savedAnswer;
        } else if (firstUnansweredIndex == -1) {
          firstUnansweredIndex = i;
        }
      }

      // Determine where to resume
      int newIndex = 0;
      if (firstUnansweredIndex != -1) {
        newIndex = firstUnansweredIndex;
      } else {
        // Should be covered by "allAnswered" check above,
        // but as a fallback, go to last one.
        newIndex = questions.length - 1;
      }

      if (!mounted) return;
      setState(() {
        _questions = questions;
        _currentIndex = newIndex;
        _isLoading = false;
        _currentAnswer = _answers[_questions[_currentIndex].id];
        _isFirstLoad = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _handleCompletion({bool silent = false}) async {
    // Save completion state
    final prefs = await SharedPreferences.getInstance();
    if (widget.isPrimaryFlow) {
      await prefs.setString('profileStatus', "ONBOARDING_COMPLETED");
    } else {
      await prefs.setString('profileStatus', "COMPLETED");
    }

    if (!mounted) return;

    if (!silent && widget.isPrimaryFlow) {
      try {
        // Call API to mark profile as completed in backend
        await _repository.completeProfile();
      } catch (e) {
        debugPrint("Error completing profile: $e");
        // We continue anyway so user can upload images
      }
    }

    if (!mounted) return;
    if (widget.isPrimaryFlow) {
      context.go(AppRoutes.profileImageUpload);
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _onNext() async {
    final question = _questions[_currentIndex];

    // Validation
    if (question.isRequired &&
        (_currentAnswer == null ||
            (_currentAnswer is String && _currentAnswer.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("This question is required.")),
      );
      return;
    }

    if (question.minWords != null && _currentAnswer is String) {
      // Simple word count
      final wordCount = (_currentAnswer as String)
          .trim()
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .length;
      if (wordCount < question.minWords!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Minimum ${question.minWords} words required."),
          ),
        );
        return;
      }
    }

    // Save Answer
    setState(() {
      _isSaving = true;
    });

    try {
      await _repository.saveAnswer(question.id, _currentAnswer);
      _answers[question.id] = _currentAnswer; // Cache it

      // Check if this is the absolute last question of the last section
      bool isLastQuestionOfSection = _currentIndex == _questions.length - 1;
      final currentSectionIndex = _activeSections.indexWhere(
        (s) => s.orderNo == _currentSectionOrder,
      );
      bool isLastSection = currentSectionIndex == _activeSections.length - 1;

      if (isLastQuestionOfSection) {
        if (isLastSection) {
          // COMPLETE THE PROFILE
          setState(() {
            _isSaving = false;
          });
          _handleCompletion(silent: false);
        } else {
          // Move to next section
          _currentSectionOrder =
              _activeSections[currentSectionIndex + 1].orderNo;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(
            widget.isPrimaryFlow
                ? 'currentSectionOrder'
                : 'nonPrimarySectionOrder',
            _currentSectionOrder,
          );

          await _fetchQuestions();
          setState(() {
            _isSaving = false;
          });
        }
      } else {
        // Just move to next question in same section
        setState(() {
          _currentIndex++;
          _currentAnswer = _answers[_questions[_currentIndex].id];
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      String message = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _onBack() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _currentAnswer = _answers[_questions[_currentIndex].id];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress
    double progress = 0.0;
    if (_questions.isNotEmpty) {
      progress = (_currentIndex + 1) / _questions.length;
    }

    // Check if valid to enable/disable button visual
    bool isValid = true;
    ProfileQuestion? question;

    if (_questions.isNotEmpty && _currentIndex < _questions.length) {
      question = _questions[_currentIndex];

      if (question.isRequired) {
        if (_currentAnswer == null ||
            (_currentAnswer is String && _currentAnswer.trim().isEmpty)) {
          isValid = false;
        }
      }
      if (question.minWords != null && _currentAnswer is String) {
        final wordCount = (_currentAnswer as String)
            .trim()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .length;
        if (wordCount < question.minWords!) {
          isValid = false;
        }
      }
    }

    // Determine if it's the last question of the last section
    bool isLastQuestion = false;
    if (_questions.isNotEmpty && _currentIndex == _questions.length - 1) {
      final currentSectionIndex = _activeSections.indexWhere(
        (s) => s.orderNo == _currentSectionOrder,
      );
      if (currentSectionIndex == _activeSections.length - 1) {
        isLastQuestion = true;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color:
                Theme.of(context).textTheme.bodyLarge?.color ??
                AppColors.textPrimary,
          ),
          onPressed: () {
            // Navigator.pushAndRemoveUntil(
            //   context,
            //   MaterialPageRoute(builder: (context) => const HomePage()),
            //   (route) => false,
            // );
            context.pop();
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100,
        titleWidget: Column(
          children: [
            // Section name stepper
            if (_activeSections.isNotEmpty)
              SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _activeSections.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: Icon(
                      Icons.chevron_right,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final section = _activeSections[index];
                    final isCompleted =
                        _activeSections.indexWhere(
                          (s) => s.orderNo == _currentSectionOrder,
                        ) >
                        index;
                    final isCurrent = section.orderNo == _currentSectionOrder;
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? Theme.of(context).primaryColor
                              : isCompleted
                              ? AppColors.success.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isCompleted
                              ? Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.4,
                                  ),
                                  width: 1,
                                )
                              : isCurrent
                              ? null
                              : Border.all(color: Colors.grey[300]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCompleted)
                              const Padding(
                                padding: EdgeInsets.only(right: 4.0),
                                child: Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: AppColors.success,
                                ),
                              ),
                            Text(
                              _activeSections[index].title,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isCurrent || isCompleted
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isCurrent
                                    ? Colors.white
                                    : isCompleted
                                    ? AppColors.success
                                    : Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color ??
                                          AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            // Question progress bar within section
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: Theme.of(context).primaryColor,
                minHeight: 6,
              ),
            ),
            // Labels row
            if (_questions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            Theme.of(context).textTheme.bodyMedium?.color ??
                            AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final sharedPrefs = await SharedPreferences.getInstance();
              await sharedPrefs.clear();
              if (context.mounted) {
                context.go(AppRoutes.landing);
              }
            },
            child: Icon(
              Icons.logout,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  AppColors.textPrimary,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.black),
                ),
              )
            : (_questions.isEmpty || question == null)
            ? const Center(child: Text("No questions available."))
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (question.sectionName != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                question.sectionName!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color ??
                                      AppColors.textSecondary,
                                  letterSpacing: 1.2,
                                  // uppercase:
                                  //     Color(0xFFB88973) == Theme.of(context).primaryColor
                                  //     ? false
                                  //     : true, // Just logic to keep it simple
                                ),
                              ),
                            ),
                          QuestionWidget(
                            question: question,
                            currentAnswer: _currentAnswer,
                            onAnswerChanged: (val) {
                              setState(() {
                                _currentAnswer = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        if (_currentIndex > 0) ...[
                          Expanded(
                            child: CustomButton(
                              onPressed: _isSaving ? null : _onBack,
                              text: "Back",
                              type: CustomButtonType.secondary,
                              height: 50,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            onPressed: _isSaving || !isValid
                                ? null
                                : () {
                                    // Hide keyboard
                                    FocusScope.of(context).unfocus();
                                    _onNext();
                                  },
                            isLoading: _isSaving,
                            text: isLastQuestion
                                ? (widget.isPrimaryFlow
                                      ? "Upload Profile Pictures"
                                      : "Done")
                                : "Continue",
                            backgroundColor: Theme.of(context).primaryColor,
                            height: 50,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
