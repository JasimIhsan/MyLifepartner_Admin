import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class FaqItem {
  final String question;
  final String answer;

  const FaqItem({required this.question, required this.answer});
}

class FaqAccordion extends StatefulWidget {
  final List<FaqItem> items;

  const FaqAccordion({super.key, required this.items});

  @override
  State<FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<FaqAccordion> {
  int _expandedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (var index = 0; index < widget.items.length; index++) ...[
          _FaqAccordionTile(
            item: widget.items[index],
            isExpanded: _expandedIndex == index,
            onTap: () {
              setState(() {
                _expandedIndex = _expandedIndex == index ? -1 : index;
              });
            },
          ),
          if (index != widget.items.length - 1)
            Divider(height: 1, color: theme.dividerColor),
        ],
      ],
    );
  }
}

class _FaqAccordionTile extends StatelessWidget {
  final FaqItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  const _FaqAccordionTile({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      expanded: isExpanded,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.question,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.35,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Icon(
                      LucideIcons.chevron_down,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 28),
                  child: Text(
                    item.answer,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                sizeCurve: Curves.easeOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
