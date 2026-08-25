import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/core/app_routes.dart';
import 'package:life_partner_again/services/api_service.dart';
import 'package:life_partner_again/services/user_repository.dart';

import 'accepted_legal_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Help & Support",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.textTheme.bodyLarge?.color,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 32),
              _buildSectionHeader(theme, "Legal & Policies"),
              _buildActionGroup(theme, [
                _buildActionItem(
                  theme: theme,
                  icon: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  subtitle: "Read our data policy and terms",
                  onTap: () {
                    context.push(
                      AppRoutes.acceptedLegal,
                      extra: LegalDocType.privacy,
                    );
                  },
                ),
                _buildActionItem(
                  theme: theme,
                  icon: Icons.description_outlined,
                  title: "Terms and Conditions",
                  subtitle: "Our rules and guidelines",
                  showDivider: false,
                  onTap: () {
                    context.push(
                      AppRoutes.acceptedLegal,
                      extra: LegalDocType.terms,
                    );
                  },
                ),
              ]),

              _buildSectionHeader(theme, "Contact Us"),
              _buildActionGroup(theme, [
                _buildActionItem(
                  theme: theme,
                  icon: Icons.support_agent_rounded,
                  title: "Support Team",
                  subtitle: "Get help with your account",
                  showDivider: false,
                  onTap: () => _showSupportBottomSheet(context),
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionHeader(theme, "Danger Zone", color: AppColors.error),
              _buildActionGroup(theme, [
                _buildActionItem(
                  theme: theme,
                  icon: Icons.delete_forever_rounded,
                  title: "Delete Account",
                  subtitle: "Permanently remove your account and data",
                  iconColor: AppColors.error,
                  titleColor: AppColors.error,
                  showDivider: false,
                  onTap: () => _showDeleteAccountBottomSheet(context),
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withOpacity(0.8), theme.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "How can we help you?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Find answers, read policies, or get in touch with our team.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color:
              color ??
              theme.textTheme.bodyMedium?.color ??
              AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildActionGroup(ThemeData theme, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionItem({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool showDivider = true,
  }) {
    final effectiveIconColor = iconColor ?? theme.primaryColor;
    final effectiveTitleColor =
        titleColor ?? theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
    final subtitleColor =
        theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: effectiveTitleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: subtitleColor.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 76,
            color: theme.dividerColor.withOpacity(0.5),
          ),
      ],
    );
  }

  void _showSupportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (BuildContext sheetContext) {
        final theme = Theme.of(context);
        final textColor =
            theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
        final mutedTextColor =
            theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;
        const email = 'support@lifepartneragain.com';

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 14,
              bottom: 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.primaryColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: theme.primaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Need help? Reach out to our support team and we\'ll get back to you as soon as possible.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: mutedTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: mutedTextColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(const ClipboardData(text: email));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email copied to clipboard!'),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.copy_rounded,
                          color: theme.primaryColor,
                        ),
                        tooltip: 'Copy Email',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountBottomSheet(BuildContext context) {
    final reasonController = TextEditingController();
    const deletionReasons = [
      'Found my partner',
      'Privacy concerns',
      'Not useful for me',
      'Too many notifications',
      'Taking a break',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (BuildContext sheetContext) {
        bool isLoading = false;
        bool isSent = false;
        String? reasonError;
        String? selectedReason;

        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final textColor =
                theme.textTheme.bodyLarge?.color ?? AppColors.textPrimary;
            final mutedTextColor =
                theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary;
            final dangerColor = AppColors.error;
            final successColor = AppColors.success;
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 14,
                    bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isSent ? successColor : dangerColor)
                                .withOpacity(0.12),
                          ),
                          child: Icon(
                            isSent
                                ? Icons.mark_email_read_rounded
                                : Icons.delete_forever_rounded,
                            color: isSent ? successColor : dangerColor,
                            size: 34,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isSent ? 'Check your email' : 'Delete account?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isSent
                            ? 'We sent a confirmation link to your email. Open it to verify your deletion request.'
                            : 'Tell us why you are leaving before we send the verification email.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: mutedTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (isSent)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            await ApiService.logoutAndRedirect();
                          },
                          child: const Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: dangerColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: dangerColor.withOpacity(0.16),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: dangerColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This action cannot be undone. Your account will be reviewed after email verification.',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Reason',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: deletionReasons.map((reason) {
                            final isSelected = selectedReason == reason;

                            return ChoiceChip(
                              label: Text(reason),
                              selected: isSelected,
                              onSelected: isLoading
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        selectedReason = selected
                                            ? reason
                                            : null;
                                        reasonError = null;
                                      });
                                    },
                              labelStyle: TextStyle(
                                color: isSelected ? dangerColor : textColor,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                              selectedColor: dangerColor.withOpacity(0.12),
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                color: isSelected
                                    ? dangerColor.withOpacity(0.55)
                                    : theme.dividerColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              showCheckmark: false,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: reasonController,
                          enabled: !isLoading,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 500,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            labelText: selectedReason == null
                                ? 'Tell us more'
                                : 'Add details (optional)',
                            hintText:
                                'A short note helps us understand what to improve',
                            errorText: reasonError,
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: theme.canvasColor.withOpacity(
                              theme.brightness == Brightness.dark ? 0.2 : 0.7,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: theme.dividerColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: dangerColor,
                                width: 1.4,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            setState(() => reasonError = null);
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: dangerColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: dangerColor.withOpacity(
                                0.45,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final reason = _composeDeletionReason(
                                      selectedReason: selectedReason,
                                      details: reasonController.text,
                                    );

                                    if (reason.isEmpty) {
                                      setState(() {
                                        reasonError =
                                            'Please select or enter a reason';
                                      });
                                      return;
                                    }

                                    if (reason.length > 500) {
                                      setState(() {
                                        reasonError =
                                            'Please keep the reason under 500 characters';
                                      });
                                      return;
                                    }

                                    setState(() => isLoading = true);
                                    try {
                                      await UserRepository()
                                          .requestAccountDeletion(
                                            reason: reason,
                                          );
                                      if (context.mounted) {
                                        setState(() {
                                          isLoading = false;
                                          isSent = true;
                                        });
                                      }
                                    } catch (e) {
                                      setState(() => isLoading = false);
                                      if (sheetContext.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.mail_outline_rounded,
                                        size: 19,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Send verification email',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dividerColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: Text(
                              'Keep my account',
                              style: TextStyle(
                                color: mutedTextColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(reasonController.dispose);
  }

  String _composeDeletionReason({
    required String? selectedReason,
    required String details,
  }) {
    final trimmedDetails = details.trim();

    if (selectedReason == null) {
      return trimmedDetails;
    }

    if (trimmedDetails.isEmpty) {
      return selectedReason;
    }

    return '$selectedReason: $trimmedDetails';
  }
}
