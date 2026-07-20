import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_partner_again/core/app_colors.dart';
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
  List<JobModel> _popularJobs = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _isSearching = widget.professionCtrl.text.trim().isNotEmpty;
    _fetchPopularJobs();
  }

  Future<void> _fetchPopularJobs() async {
    setState(() => _isLoading = true);
    try {
      final results = await JobService.getPopularJobs();
      if (mounted) {
        setState(() {
          _popularJobs = results;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    widget.onProfessionChanged(query);
    widget.onJobIdChanged(null);

    final isNotEmpty = query.trim().isNotEmpty;
    setState(() {
      _isSearching = isNotEmpty;
      if (isNotEmpty) {
        _isLoading =
            true; // Show loading immediately to prevent flashing empty state
      }
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        return;
      }
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await JobService.searchJobs(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final professionRegex = RegExp(r"^[a-zA-Z0-9\s\-\'\.\,]+$");
    final hasError =
        widget.professionCtrl.text.isNotEmpty &&
        !professionRegex.hasMatch(widget.professionCtrl.text);

    final displayList = _isSearching ? _suggestions : _popularJobs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.center,
          child: const OnboardingStepTitle(
            title: "What do you\ndo professionaly?",
          ),
        ),
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
          hint: 'Search your job or role',
          capitalization: TextCapitalization.sentences,
          errorText: hasError
              ? "Only letters, numbers, spaces, and basic punctuation allowed"
              : null,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          onChanged: _onSearchChanged,
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.textPrimary,
            size: 22,
          ),
          suffixIcon: _isLoading
              ? const UnconstrainedBox(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : null,
        ),
        if (!_isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 12, left: 4),
            child: Text(
              "Popular jobs",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        if (displayList.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: displayList.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final job = displayList[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 0,
                ),
                title: Text(
                  job.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onTap: () {
                  widget.professionCtrl.text = job.name;
                  widget.onProfessionChanged(job.name);
                  widget.onJobIdChanged(job.id);
                  setState(() {
                    _isSearching = false;
                    FocusScope.of(context).unfocus();
                  });
                },
              );
            },
          ),
        if (_isSearching &&
            _suggestions.isEmpty &&
            !_isLoading &&
            !hasError &&
            widget.professionCtrl.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                "Tap continue to use '${widget.professionCtrl.text.trim()}'",
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
