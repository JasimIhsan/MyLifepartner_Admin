import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class FaqItem {
  final String id;
  final String question;
  final String answer;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });
}

class FaqAccordion extends StatefulWidget {
  final List<FaqItem> items;
  final String? initialExpandedId;

  const FaqAccordion({
    super.key,
    required this.items,
    this.initialExpandedId,
  });

  @override
  State<FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<FaqAccordion> {
  int _expandedIndex = -1;
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      _itemKeys[item.id] = GlobalKey();
    }

    if (widget.initialExpandedId != null) {
      final index = widget.items.indexWhere(
        (item) => item.id == widget.initialExpandedId,
      );
      if (index != -1) {
        _expandedIndex = index;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToItem(widget.initialExpandedId!);
        });
      }
    }
  }

  void _scrollToItem(String id) {
    final key = _itemKeys[id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.1, // Slight offset from the top
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        for (var index = 0; index < widget.items.length; index++) ...[
          _FaqAccordionTile(
            key: _itemKeys[widget.items[index].id],
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
    super.key,
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
