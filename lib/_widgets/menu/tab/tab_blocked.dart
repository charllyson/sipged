import 'package:flutter/material.dart';

class TabBlocked extends StatelessWidget {
  final String message;
  const TabBlocked({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.red.shade700),
        ),
      ),
    );
  }
}
