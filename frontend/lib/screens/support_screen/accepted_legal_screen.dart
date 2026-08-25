import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:life_partner_again/core/app_colors.dart';
import 'package:life_partner_again/models/auth_response.dart';
import 'package:life_partner_again/services/legal_service.dart';
import 'package:life_partner_again/services/user_repository.dart';

enum LegalDocType { privacy, terms }

class AcceptedLegalScreen extends StatelessWidget {
  final LegalDocType docType;

  const AcceptedLegalScreen({super.key, required this.docType});

  Future<void> _showLegalContent(
    BuildContext context,
    bool isPrivacy,
    bool hasAccepted,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isPrivacy ? "Privacy Policy" : "Terms & Conditions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(sheetContext).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: hasAccepted
                      ? LegalService.getAcceptedDocument(
                          isPrivacy ? 'privacy' : 'terms',
                        )
                      : (isPrivacy
                            ? LegalService.getLatestPrivacyPolicy()
                            : LegalService.getLatestTerms()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return const Center(
                        child: Text('Failed to load document.'),
                      );
                    }
                    final content = snapshot.data!['content'] as String? ?? '';
                    return Markdown(data: content);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isPrivacy = docType == LegalDocType.privacy;
    final String title = isPrivacy ? "Privacy Policy" : "Terms & Conditions";

    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Legal Details",
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
      body: FutureBuilder<User>(
        future: UserRepository().getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          final bool hasAccepted = isPrivacy
              ? (user?.privacyAcknowledged ?? false)
              : (user?.termsAccepted ?? false);
          final String? version = isPrivacy
              ? user?.privacyVersion
              : user?.termsVersion;
          final DateTime? acceptedAt = isPrivacy
              ? user?.privacyAcknowledgedAt
              : user?.termsAcceptedAt;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(
                    theme,
                    isPrivacy,
                    hasAccepted,
                    version,
                    acceptedAt,
                  ),
                  const SizedBox(height: 32),
                  _buildDocumentCard(
                    theme,
                    title,
                    isPrivacy,
                    context,
                    hasAccepted,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    bool isPrivacy,
    bool hasAccepted,
    String? version,
    DateTime? acceptedAt,
  ) {
    final statusColor = hasAccepted ? AppColors.success : AppColors.error;
    final icon = isPrivacy
        ? Icons.privacy_tip_rounded
        : Icons.description_rounded;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
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
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            hasAccepted ? "Accepted" : "Action Required",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.textTheme.bodyLarge?.color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasAccepted
                ? "You have agreed to our ${isPrivacy ? "privacy policy" : "terms and conditions"}."
                : "We do not have a record of your agreement.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color:
                  theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (hasAccepted) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      theme,
                      "Version",
                      version ?? "Standard",
                    ),
                  ),
                  Container(width: 1, height: 40, color: theme.dividerColor),
                  Expanded(
                    child: _buildDetailItem(
                      theme,
                      "Date Accepted",
                      acceptedAt != null
                          ? DateFormat('MMM dd, yyyy').format(acceptedAt)
                          : "Unknown",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: theme.textTheme.bodyMedium?.color ?? AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(
    ThemeData theme,
    String title,
    bool isPrivacy,
    BuildContext context,
    bool hasAccepted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLegalContent(context, isPrivacy, hasAccepted),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Read Full Document",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "View the complete $title on our website.",
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              theme.textTheme.bodyMedium?.color ??
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color:
                      (theme.textTheme.bodyMedium?.color ??
                              AppColors.textSecondary)
                          .withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
