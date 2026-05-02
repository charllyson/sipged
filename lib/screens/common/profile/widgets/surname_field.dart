import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class SurnameField extends StatelessWidget {
  const SurnameField({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: 'Sobrenome',
      hintText: 'Seu sobrenome',
    );
  }
}