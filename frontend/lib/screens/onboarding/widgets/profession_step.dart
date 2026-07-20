import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/models/job.dart';
import 'package:life_partner_again/screens/onboarding/widgets/onboarding_ui_helpers.dart';
import 'package:life_partner_again/services/job_service.dart';

class ProfessionStep extends StatefulWidget {
  final TextEditingController professionCtrl;
  final ValueChanged<String> onProfessionChanged;
  final ValueChanged<int?> onJobIdChanged;
  final int? selectedJobId;

  const ProfessionStep({
    super.key,
    required this.professionCtrl,
    required this.onProfessionChanged,
    required this.onJobIdChanged,
    this.selectedJobId,
  });

  @override
  State<ProfessionStep> createState() => _ProfessionStepState();
}

class _ProfessionStepState extends State<ProfessionStep> {
  List<JobModel> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _showSuggestions = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    widget.onProfessionChanged(query);
    widget.onJobIdChanged(null); // Reset job ID as the user is typing/editing

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.trim().isEmpty) {
        setState(() {
          _suggestions = [];
          _showSuggestions = false;
        });
        return;
      }
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await JobService.searchJobs(query);
      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
      });
    } catch (_) {
      // Silently handle error for search suggestions
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final professionRegex = RegExp(r"^[a-zA-Z0-9\s\-\'\.\,]+$");

    String? getProfessionError() {
      if (widget.professionCtrl.text.isNotEmpty &&
          !professionRegex.hasMatch(widget.professionCtrl.text)) {
        return "Only letters, numbers, spaces, and basic punctuation allowed";
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const OnboardingStepTitle(title: "What do you do for work?"),
        const SizedBox(height: 10),
        Center(
          child: SizedBox(
            height: 140,
            child: Image.asset(
              'assets/images/onboarding/work.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        OnboardingInputField(
          controller: widget.professionCtrl,
          hint: 'e.g. Software Developer, Doctor…',
          capitalization: TextCapitalization.sentences,
          errorText: getProfessionError(),
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          onChanged: _onSearchChanged,
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 8.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.purple,
              ),
            ),
          ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final job = _suggestions[index];
                return ListTile(
                  title: Text(
                    job.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    widget.professionCtrl.text = job.name;
                    widget.onProfessionChanged(job.name);
                    widget.onJobIdChanged(job.id);
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
