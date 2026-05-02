import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class NameField extends StatelessWidget {
  const NameField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: 'Nome',
      hintText: 'Seu nome',
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Informe seu nome';
        }

        if (value.trim().length < 2) {
          return 'Nome muito curto';
        }

        return null;
      },
    );
  }
}
