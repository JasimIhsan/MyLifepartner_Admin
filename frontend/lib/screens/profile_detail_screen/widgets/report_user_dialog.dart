import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/services/report_service.dart';

class ReportUserDialog extends StatefulWidget {
  final Map<String, dynamic> profile;
  final String source; // E.g., 'PROFILE', 'CHAT'

  const ReportUserDialog({
    super.key,
    required this.profile,
    this.source = 'PROFILE',
  });

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> profile, {
    String source = 'PROFILE',
  }) async {
    final isWeb = kIsWeb;
    if (isWeb) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 680),
            child: ReportUserDialog(profile: profile, source: source),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ReportUserDialog(profile: profile, source: source),
          ),
        ),
      );
    }
  }

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  final List<Map<String, dynamic>> _presetReasonsList = [
    {
      'label': 'Fake profile',
      'value': 'FAKE_PROFILE',
      'icon': Icons.person_outline,
    },
    {
      'label': 'Inappropriate photos',
      'value': 'INAPPROPRIATE_PHOTOS',
      'icon': Icons.image_outlined,
    },
    {
      'label': 'Harassment or abuse',
      'value': 'HARASSMENT',
      'icon': Icons.warning_amber_rounded,
    },
    {
      'label': 'Scam or fraud',
      'value': 'SCAM_OR_FRAUD',
      'icon': Icons.money_off_csred_outlined,
    },
    {
      'label': 'Spam or advertising',
      'value': 'SPAM',
      'icon': Icons.campaign_outlined,
    },
    {
      'label': 'Offensive language',
      'value': 'HATEFUL_CONTENT',
      'icon': Icons.chat_bubble_outline,
    },
    {
      'label': 'Underage',
      'value': 'UNDERAGE_USER',
      'icon': Icons.child_care_outlined,
    },
    {
      'label': 'Wrong personal info',
      'value': 'FALSE_INFORMATION',
      'icon': Icons.badge_outlined,
    },
    {
      'label': 'Not looking for relationship',
      'value': 'MARRIED_OR_FALSE_RELATIONSHIP_STATUS',
      'icon': Icons.heart_broken_outlined,
    },
    {'label': 'Other', 'value': 'OTHER', 'icon': Icons.more_horiz_rounded},
  ];

  String? _selectedReasonKey;
  final TextEditingController _customReasonController = TextEditingController();
  List<XFile> _selectedProofImages = [];
  bool _isSubmitting = false;
  String? _errorMessage;
  int _currentStep = 0;

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedProofImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only attach up to 5 screenshots'),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);

    if (images.isNotEmpty) {
      setState(() {
        _selectedProofImages.addAll(images);
        if (_selectedProofImages.length > 5) {
          _selectedProofImages = _selectedProofImages.sublist(0, 5);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Only 5 screenshots are allowed. The rest were discarded.',
              ),
            ),
          );
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedProofImages.removeAt(index);
    });
  }

  void _submitReport() async {
    setState(() {
      _errorMessage = null;
    });

    if (_selectedReasonKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason for reporting')),
      );
      return;
    }

    if (_selectedReasonKey == 'OTHER' &&
        _customReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter details for the reason')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final reportedUserId = widget.profile['userId'] ?? widget.profile['id'];

      if (reportedUserId == null) {
        throw Exception("Reported User ID is missing.");
      }

      await ReportService.submitReport(
        reportedUserId: int.parse(reportedUserId.toString()),
        reason: _selectedReasonKey!,
        source: widget.source,
        description: _customReasonController.text.trim().isNotEmpty
            ? _customReasonController.text.trim()
            : null,
        screenshotPaths: _selectedProofImages.map((e) => e.path).toList(),
      );

      if (!mounted) return;

      setState(() {
        _currentStep = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStep0() {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shield,
                      color: Color(0xFFFFE5E5),
                      size: 70,
                    ),
                    const Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFFFB3B3),
                      size: 70,
                    ),
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade600,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Help us keep the community\nsafe and respectful.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _presetReasonsList.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = _presetReasonsList[index];
                    final isSelected = _selectedReasonKey == item['value'];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedReasonKey = item['value'];
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item['icon'],
                                color: Colors.black87,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item['label'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? Colors.red.shade600
                                  : Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedReasonKey == null
                    ? null
                    : () {
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              _selectedReasonKey == 'OTHER'
                  ? 'Please describe the reason'
                  : 'Additional details (Optional)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customReasonController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter details here...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attach Proof / Screenshot',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${_selectedProofImages.length}/5',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedProofImages.isNotEmpty
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ..._selectedProofImages.asMap().entries.map((entry) {
                            final index = entry.key;
                            final image = entry.value;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: kIsWeb
                                      ? Image.network(
                                          image.path,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(image.path),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                          if (_selectedProofImages.length < 5)
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to upload up to 5 screenshots',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    final userName = widget.profile['name'] ?? 'User';
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green.shade500,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Report Submitted',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for helping us keep the community safe. Your report for $userName is now under review.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = widget.profile['name'] ?? 'User';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header handle & title
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              if (!kIsWeb)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep == 1)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _currentStep = 0;
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textPrimary,
                    )
                  else
                    const SizedBox(width: 24), // Spacer when no back button
                  Expanded(
                    child: Text(
                      'Report $userName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 0.1, color: AppColors.borderColor),
        if (_currentStep == 0)
          _buildStep0()
        else if (_currentStep == 1)
          _buildStep1()
        else
          _buildStep2(),
      ],
    );
  }
}
