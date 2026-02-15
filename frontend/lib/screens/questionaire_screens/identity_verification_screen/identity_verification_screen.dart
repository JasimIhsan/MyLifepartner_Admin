import 'package:flutter/material.dart';
import 'package:mylifepartner/core/app_colors.dart';
import 'package:mylifepartner/models/profile_question.dart';
import 'package:mylifepartner/screens/home_screen/home_screen.dart';
import 'package:mylifepartner/screens/login_screen/login_screen.dart';
import 'package:mylifepartner/screens/questionaire_screens/widgets/question_widget.dart';
import 'package:mylifepartner/services/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
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

  @override
  void initState() {
    super.initState();
    _loadSavedState();
  }

  Future<void> _loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
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
      if (questions.isEmpty) {
        // If no questions returned for section 1, maybe error or empty.
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

      // Populate local cache with saved answers
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
        // All answered? Go to last one or maybe section complete?
        newIndex = questions.length - 1;
      }

      setState(() {
        _questions = questions;
        _currentIndex = newIndex;
        _isLoading = false;
        _currentAnswer = _answers[_questions[_currentIndex].id];
        _isFirstLoad = false;
      });
    } catch (e) {
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
      builder: (context) => Container(
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

      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _currentAnswer = _answers[_questions[_currentIndex].id];
          _isSaving = false;
        });
      } else {
        // Finished current section, load next
        _currentSectionOrder++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currentSectionOrder', _currentSectionOrder);

        await _fetchQuestions();
        setState(() {
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
    } else if (_currentSectionOrder > 1) {
      // Go back to previous section?
      // This is complex because we need to re-fetch previous section.
      // For now, let's just allow back within section.
      // Or implement full back navigation later.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot go back to previous section yet."),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress
    // We don't know total questions across all sections easily without fetching structure first.
    // So let's show progress within current section or just a loader.
    // User requested "progress on the appbar".
    // Let's assume progress = (currentIndex + 1) / questions.length for this section.

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

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primaryLight,
        elevation: 0,
        leading: (_currentIndex > 0 || _currentSectionOrder > 1)
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
              final sharedPrefs = await SharedPreferences.getInstance();
              await sharedPrefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
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
                          disabledBackgroundColor: AppColors.primary
                              .withOpacity(0.5),
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
                            : const Text(
                                "Continue",
                                style: TextStyle(
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
