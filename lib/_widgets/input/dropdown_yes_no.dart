// lib/screens/process/hiring/1Dfd/dfd_sections/dropdown_yes_no.dart
import 'package:flutter/material.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';


class YesNoDrop extends StatelessWidget with FormValidationMixin {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;
  final double width;
  final bool enabled;

  YesNoDrop({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.width,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropDownButtonChange(
        enabled: enabled,
        labelText: label,
        controller: TextEditingController(text: value),
        items: const ['Sim', 'Não', 'N/A'],
        onChanged: onChanged,
        validator: validateRequired,
      ),
    );
  }
}

/// Helper centralizado para calcular largura dos inputs
double inputWidth({
  required BuildContext context,
  required BoxConstraints inner,
  required int perLine,
  double minItemWidth = 220,
}) {
  return responsiveInputWidth(
    context: context,
    itemsPerLine: perLine,
    containerWidth: MediaQuery.of(context).size.width,
    spacing: 12,
    margin: 12,
    extraPadding: 0,
    minItemWidth: minItemWidth,
    minWidthSmallScreen: 280,
    forceItemsPerLineOnSmall: true,
  );
}
