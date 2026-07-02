import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final VoidCallback onBack;

  const NotificationScreen({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBack();
      },
      child: Column(
        children: [
          // Header
          const Padding(
            padding: EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Content
          Expanded(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("New match request"),
                subtitle: const Text("Someone liked your profile"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
