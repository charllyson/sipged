// lib/screens/process/hiring/1Dfd/dfd_sections/drop_down_yes_no.dart
import 'package:flutter/material.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';


class YesNoDrop extends StatelessWidget with FormValidationMixin {
  final String labelText;
  final String? value;
  final ValueChanged<String?> controller;
  final bool enabled;

  YesNoDrop({
    super.key,
    required this.labelText,
    required this.value,
    required this.controller,
    required this.enabled,
  });

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
