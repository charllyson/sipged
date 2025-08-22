// COMPLETO — UI “boba” do modal. Sem lógica: só chama o controller.
import 'package:flutter/material.dart';

import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_widgets/input/custom_date_field.dart';
import 'package:sisged/_widgets/schedule/schedule_status.dart';

// Carrossel modular (apenas UI)
import 'package:sisged/_widgets/carousel/photo_carousel.dart';
import 'package:sisged/_datas/widgets/pickedPhoto/carousel_photo_theme.dart';
import 'package:sisged/screens/sectors/operation/schedule/schedule_ui_controller.dart';

class ScheduleModalResult extends StatelessWidget {
  final String title;
  final int count;
  final ScheduleUiController controller;

  const ScheduleModalResult({
    super.key,
    required this.title,
    required this.count,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isSingle = count == 1;
    final buttonLabel = isSingle ? 'Aplicar' : 'Aplicar em $count célula(s)';
    final buttonIcon  = isSingle ? Icons.done : Icons.done_all;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SafeArea(
          top: false,
          child: Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(title: title, isSingle: isSingle, busy: controller.busy),

                  const SizedBox(height: 8),
                  _StatusChips(
                    selected: controller.status,
                    onSelect: controller.busy ? null : controller.setStatus,
                  ),

                  const SizedBox(height: 12),
                  CustomDateField(
                    labelText: 'Data',
                    controller: controller.dateCtrl,
                    initialValue: controller.selectedDate,
                    onChanged: controller.busy ? null : controller.setDate,
                    width: double.infinity,
                  ),

                  const SizedBox(height: 12),
                  PhotoCarousel.fromSeparated(
                    leading: _PhotoPickerSquare(
                      enabled: !controller.busy,
                      onTap: controller.pickPhotos,
                    ),
                    existingUrls: controller.existingUrls,
                    existingMetaByUrl: controller.existingMetaByUrl,
                    newPhotos: controller.newPhotos,
                    newMetas: controller.newMetas,
                    onRemoveNew: controller.busy ? null : controller.removeNewAt,
                    onRemoveExisting: controller.busy ? null : controller.removeExistingAt,
                    theme: const CarouselPhotoTheme(itemSize: 96, spacing: 8),
                  ),

                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: controller.commentCtrl,
                    maxLines: 3,
                    labelText: 'Comentário (opcional)',
                    textInputAction: TextInputAction.done,
                    enabled: !controller.busy,
                    onFieldSubmitted: (_) => _submit(context),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(buttonIcon),
                      label: Text(buttonLabel),
                      onPressed: controller.busy ? null : () => _submit(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit(BuildContext context) {
    Navigator.pop(context, controller.buildModalResult());
  }
}

class _Header extends StatelessWidget {
  final String title;
  final bool isSingle;
  final bool busy;
  const _Header({required this.title, required this.isSingle, required this.busy});

  @override
  Widget build(BuildContext context) {
    final titleIcon = isSingle ? Icons.edit : Icons.select_all_rounded;
    return Row(
      children: [
        Icon(titleIcon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isSingle ? 'Editar célula — $title' : 'Aplicar em lote — $title',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: busy ? null : () => Navigator.pop(context, null),
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
        ),
      ],
    );
  }
}

class _StatusChips extends StatelessWidget {
  final ScheduleStatus selected;
  final ValueChanged<ScheduleStatus>? onSelect;
  const _StatusChips({required this.selected, required this.onSelect});

  Widget _chip(BuildContext _, ScheduleStatus s) {
    final sel = s == selected;
    return SizedBox(
      height: 44,
      child: Material(
        color: sel ? s.color : Colors.grey.shade200,
        shape: StadiumBorder(side: BorderSide(color: sel ? s.color : Colors.grey.shade300)),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onSelect == null ? null : () => onSelect!(s),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(s.icon, size: 18, color: sel ? Colors.white : s.color),
                const SizedBox(width: 8),
                Text(
                  s.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 520;
    final chips = [
      _chip(context, ScheduleStatus.concluido),
      _chip(context, ScheduleStatus.emAndamento),
      _chip(context, ScheduleStatus.aIniciar),
    ];

    if (isPhone) {
      return Column(children: [
        chips[0], const SizedBox(height: 8),
        chips[1], const SizedBox(height: 8),
        chips[2],
      ]);
    }
    return Row(children: [
      Expanded(child: chips[0]), const SizedBox(width: 8),
      Expanded(child: chips[1]), const SizedBox(width: 8),
      Expanded(child: chips[2]),
    ]);
  }
}

class _PhotoPickerSquare extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  const _PhotoPickerSquare({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96, height: 96,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: enabled ? Colors.blueGrey.shade300 : Colors.grey, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo, color: enabled ? Colors.blueGrey : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text('Adicionar foto', style: TextStyle(fontSize: 12, color: enabled ? Colors.blueGrey : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
