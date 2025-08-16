import 'package:flutter/material.dart';

class ContractAddButton extends StatelessWidget {
  final bool isEditable;
  final VoidCallback onAdd;

  const ContractAddButton({
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
      label: Text('Novo Contrato', style: TextStyle(color: Colors.white)),
    );
  }
}