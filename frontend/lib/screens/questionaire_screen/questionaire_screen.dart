import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/profile_question.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/questionaire_screen/widgets/question_widget.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionaireScreen extends StatefulWidget {
  const QuestionaireScreen({super.key});

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

  int _totalSections = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch total sections first (or in parallel)
    try {
      _totalSections = await _repository.getTotalSectionsCount();
    } catch (e) {
      debugPrint("Failed to fetch total sections: $e");
    }

    int? savedSection = prefs.getInt('currentSectionOrder');
    if (savedSection != null) {
      _currentSectionOrder = savedSection;
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

        _currentSectionOrder++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currentSectionOrder', _currentSectionOrder);

        // Recursive call to get next section
        if (mounted) {
          await _fetchQuestions();
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
    await prefs.setBool('isProfileCompleted', true);

    if (!mounted) return;

    if (silent) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primary, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Profile Completed",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Thank you for completing the verification.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    // Call API to mark profile as completed in backend
                    await _repository.completeProfile();

                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  } catch (e) {
                    String message = e.toString().replaceAll('Exception: ', '');
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  "Continue to Home",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
      bool isLastSection = _currentSectionOrder == _totalSections;

      if (isLastQuestionOfSection) {
        if (isLastSection) {
          // COMPLETE THE PROFILE
          setState(() {
            _isSaving = false;
          });
          _handleCompletion(silent: false);
        } else {
          // Move to next section
          _currentSectionOrder++;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('currentSectionOrder', _currentSectionOrder);

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
    } else {
      // User is at the first question of the current section.
      // Requirements: "user only can goback to the current section... he can't go back to 2nd or 1st section"
      // So if _currentIndex == 0, we do nothing or pop if it's the very first section?
      // Actually usually Back on first screen pops the screen.
      // But if it's Section 3, Q1 -> Back logic says "cannot go back".
      // AppBar leading is hidden in that case anyway.
      // But if hardware back button is pressed:

      // If we want to allow popping the screen to go back to previous screen (Login? Home?), we can.
      // But if we want to restrict going to PREVIOUS QUESTIONS of PREVIOUS SECTIONS, we just don't decrement section order.

      Navigator.pop(context);
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
      if (_currentSectionOrder == _totalSections) {
        isLastQuestion = true;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        // Only show back button if we are NOT at the start of the section
        leading: (_currentIndex > 0)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: _onBack,
              )
            : null,
        title: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                color: AppColors.primary,
                minHeight: 8,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(context);
              final sharedPrefs = await SharedPreferences.getInstance();
              await sharedPrefs.clear();
              if (mounted) {
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Icon(Icons.logout, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1.2,
                                  // uppercase:
                                  //     Color(0xFFB88973) == AppColors.primary
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
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving || !isValid
                            ? null
                            : () {
                                // Hide keyboard
                                FocusScope.of(context).unfocus();
                                _onNext();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isLastQuestion
                                    ? "Complete Profile"
                                    : "Continue",
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
