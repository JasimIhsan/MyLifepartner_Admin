import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class WebAboutPage extends StatelessWidget {
  const WebAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // 1. Hero Section
        Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surface
                : theme.primaryColor.withOpacity(0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'ABOUT US',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 2,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Text(
                  'LPA brings out the most attractive version of you, to find the right life partner this time!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Text(
                  'We have built and continue to build an international community on mutual respect and trust.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. The Story Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Does it matter? Definitely, YES!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildParagraph(
                    theme,
                    'Pairs part, when loneliness takes over love.\n\n'
                    'Multiple reasons cause separation and divorce. Moreover, many among us are unfortunately widowed. There are single parents as well. But, none of these experiences define them. Instead, they become stronger and wiser.',
                  ),
                  const SizedBox(height: 24),
                  _buildParagraph(
                    theme,
                    'LPA plays a vital role by bringing together ideal life partners in Canada. Sometimes it takes years to find a relationship built on trust. In reality, your perfect partner is hidden somewhere!',
                  ),
                  const SizedBox(height: 24),
                  _buildParagraph(
                    theme,
                    'Life Partner Again is the favourite App since we value emotions. In a word, LPA is the best platform for emotionally mature people to get into something real.',
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Mission & Vision
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 100),
          color: isDark ? theme.colorScheme.surface : const Color(0xFFF9FAFB),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 800;
                  if (isMobile) {
                    return Column(
                      children: [
                        _buildMissionVisionCard(
                          theme,
                          title: 'Mission',
                          icon: LucideIcons.compass,
                          content:
                              'The advanced Application serves as a trustworthy platform connecting adults seeking another chance for a serious relationship.',
                        ),
                        const SizedBox(height: 32),
                        _buildMissionVisionCard(
                          theme,
                          title: 'Vision',
                          icon: LucideIcons.telescope,
                          content:
                              'A world with ample space to experience joy and build fulfilling relationships at any stage of life.',
                        ),
                      ],
                    );
                  }
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildMissionVisionCard(
                            theme,
                            title: 'Mission',
                            icon: LucideIcons.compass,
                            content:
                                'The advanced Application serves as a trustworthy platform connecting adults seeking another chance for a serious relationship.',
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          child: _buildMissionVisionCard(
                            theme,
                            title: 'Vision',
                            icon: LucideIcons.telescope,
                            content:
                                'A world with ample space to experience joy and build fulfilling relationships at any stage of life.',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // 4. Values
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  Text(
                    'Our Values',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 80),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 900;
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildValueItem(
                              theme,
                              icon: LucideIcons.scale,
                              title: 'Integrity',
                              description:
                                  'We lead with honesty. You get what you see, because every connection begins with mutual trust.',
                            ),
                            const SizedBox(height: 56),
                            _buildValueItem(
                              theme,
                              icon: LucideIcons.gem,
                              title: 'Dignity',
                              description:
                                  'Your age, your past, and your thoughts deserve to be met with respect.',
                            ),
                            const SizedBox(height: 56),
                            _buildValueItem(
                              theme,
                              icon: LucideIcons.shield_check,
                              title: 'Safety',
                              description:
                                  'We protect your space; you can show up with a smile.',
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildValueItem(
                              theme,
                              icon: LucideIcons.scale,
                              title: 'Integrity',
                              description:
                                  'We lead with honesty. You get what you see, because every connection begins with mutual trust.',
                            ),
                          ),
                          const SizedBox(width: 56),
                          Expanded(
                            child: _buildValueItem(
                              theme,
                              icon: LucideIcons.gem,
                              title: 'Dignity',
                              description:
                                  'Your age, your past, and your thoughts deserve to be met with respect.',
                            ),
                          ),
                          const SizedBox(width: 56),
                          Expanded(
                            child: _buildValueItem(
                              theme,
                              icon: LucideIcons.shield_check,
                              title: 'Safety',
                              description:
                                  'We protect your space; you can show up with a smile.',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // 5. Founder's Message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161616) : const Color(0xFFFFFBFB),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.quote,
                    size: 64,
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    '“No seasons, no age limits for a serious relationship. So, we began Life Partner Again.\n\nI wanted to stand for people with history, kids, careers, and Hopes & Plans. As a member, you are free to express your expectations and meet others aspiring to the same.\n\nWe are grown adults showing up honestly, looking for something that counts.\n\nIf you’re ready to take the first step with the right attitude, you belong here!”',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.8,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 56),
                  Text(
                    'Syed Sohail',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Founder & CEO',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParagraph(ThemeData theme, String text) {
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(
        height: 1.8,
        color: theme.brightness == Brightness.dark
            ? Colors.white70
            : Colors.black87,
      ),
    );
  }

  Widget _buildMissionVisionCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 36),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            content,
            style: theme.textTheme.titleMedium?.copyWith(
              height: 1.7,
              color: theme.brightness == Brightness.dark
                  ? Colors.white70
                  : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface
                : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 48),
        ),
        const SizedBox(height: 32),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            height: 1.6,
            color: theme.brightness == Brightness.dark
                ? Colors.white70
                : Colors.black54,
          ),
        ),
      ],
    );
  }
}
