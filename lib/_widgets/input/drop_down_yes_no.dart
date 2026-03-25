// lib/screens/operation/hiring/1Dfd/dfd_sections/drop_down_yes_no.dart
import 'package:flutter/material.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';

class YesNoDrop extends StatelessWidget with SipGedValidation {

  YesNoDrop({
    super.key,
    required this.labelText,
    required this.value,
    required this.controller,
    required this.enabled,
  });

  final String labelText;
  final String? value;
  final ValueChanged<String?> controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropDownButtonChange(
      enabled: enabled,
      labelText: labelText,
      controller: TextEditingController(text: value),
      items: const ['Sim', 'Não', 'N/A'],
      onChanged: controller,
      validator: validateRequired,
    );
  }
}