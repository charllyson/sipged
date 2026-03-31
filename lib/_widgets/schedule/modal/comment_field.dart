// lib/_widgets/modals/parts/comment_field.dart
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

class ScheduleCommentField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const ScheduleCommentField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: CustomTextField(
        controller: controller,
        maxLines: 3,
        enabled: enabled,
        labelText: 'Comentário (opcional)',
      ),
    );
  }
}
