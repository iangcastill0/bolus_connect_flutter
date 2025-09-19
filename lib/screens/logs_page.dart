import 'package:flutter/material.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logs')),
      body: const Center(
        child: Text('Your recent logs will appear here.'),
      ),
    );
  }
}

