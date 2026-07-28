import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

class MultiSelectDialog extends StatefulWidget {
  final List<String> options;
  final List<String> selectedOptions;
  final String title;

  const MultiSelectDialog({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.title,
  });

  @override
  State<MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  late List<String> _currentSelections;

  @override
  void initState() {
    super.initState();
    _currentSelections = List<String>.from(widget.selectedOptions);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.options.map((option) {
            return CheckboxListTile(
              value: _currentSelections.contains(option),
              title: Text(option),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (isChecked) {
                setState(() {
                  if (isChecked == true) {
                    _currentSelections.add(option);
                  } else {
                    _currentSelections.remove(option);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => context.pop(_currentSelections),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
