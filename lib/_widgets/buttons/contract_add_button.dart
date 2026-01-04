import 'package:flutter/material.dart';

class DemandAddButton extends StatelessWidget {
  final bool isEditable;
  final VoidCallback onAdd;

  const DemandAddButton({
    super.key,
    required this.isEditable,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEditable) return SizedBox.shrink();
    return FloatingActionButton.extended(
      backgroundColor: Colors.blue,
      heroTag: 'add_contract',
      onPressed: onAdd,
      icon: Icon(Icons.add, color: Colors.white),
      label: Text('Nova demanda', style: TextStyle(color: Colors.white)),
    );
  }
}