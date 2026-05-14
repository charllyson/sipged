// lib/screens/_pages/physical_financial/widgets/card_wrapper.dart
import 'package:flutter/material.dart';

class PhysFinCardWrapper extends StatelessWidget {
  final EdgeInsets padding;
  final Widget child;
  const PhysFinCardWrapper({super.key, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Colors.white,
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
