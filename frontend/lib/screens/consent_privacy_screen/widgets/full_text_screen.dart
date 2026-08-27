import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class FullTextScreen extends StatelessWidget {
  final String title;
  final String content;

  const FullTextScreen({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Makes it responsive for large screens
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                ),
                h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                listBullet: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
