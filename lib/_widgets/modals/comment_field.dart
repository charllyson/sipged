// lib/_widgets/modals/parts/comment_field.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/modals/schedule_modal_controller.dart';

class ScheduleCommentField extends StatelessWidget {
  const ScheduleCommentField({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ScheduleModalController>();

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: CustomTextField(
        controller: c.commentCtrl,
        maxLines: 3,
        enabled: !(c.picking || c.saving),
        labelText: 'Comentário (opcional)',
      ),
    );
  }
}
