// lib/screens/modules/operation/schedule/linear/editor/services/schedule_services_profile.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart';
import 'package:sipged/screens/modules/operation/schedule/common/schedule_header_section.dart';
import 'package:sipged/screens/modules/operation/schedule/linear/editor/services/schedule_services_editor.dart';

class ScheduleServicesProfile extends StatelessWidget {
  const ScheduleServicesProfile({
    super.key,
    required this.services,
    required this.activeServiceKey,
    required this.onAdd,
    required this.onSelect,
    required this.onRemove,
    required this.onLabelChanged,
    required this.onIconChanged,
    required this.onColorChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.compact,
  });

  final List<ScheduleLinearServicesData> services;
  final String activeServiceKey;

  final VoidCallback onAdd;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onRemove;

  final void Function(
      ScheduleLinearServicesData service,
      String value,
      ) onLabelChanged;

  final void Function(
      ScheduleLinearServicesData service,
      String iconKey,
      ) onIconChanged;

  final void Function(
      ScheduleLinearServicesData service,
      int colorValue,
      ) onColorChanged;

  final ValueChanged<ScheduleLinearServicesData> onMoveUp;
  final ValueChanged<ScheduleLinearServicesData> onMoveDown;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final orderedServices = ScheduleLinearServicesData.sortByLayer(services);

    final specificServices = orderedServices
        .where((service) => service.key != ScheduleLinearServicesData.geralKey)
        .toList(growable: false);

    final list = ListView.separated(
      itemCount: orderedServices.length,
      shrinkWrap: compact,
      physics: compact
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final service = orderedServices[index];
        final isSelected = service.key == activeServiceKey;
        final isGeral = service.key == ScheduleLinearServicesData.geralKey;

        final specificIndex = specificServices.indexWhere(
              (item) => item.key == service.key,
        );

        final canMoveUp = !isGeral && specificIndex > 0;
        final canMoveDown = !isGeral &&
            specificIndex >= 0 &&
            specificIndex < specificServices.length - 1;

        return ScheduleServicesEditor(
          service: service,
          isSelected: isSelected,
          isGeral: isGeral,
          compact: compact,
          canMoveUp: canMoveUp,
          canMoveDown: canMoveDown,
          onTap: () => onSelect(service.key),
          onRemove: isGeral ? null : () => onRemove(service.key),
          onChanged: isGeral
              ? null
              : (value) {
            onLabelChanged(service, value);
          },
          onIconChanged: isGeral
              ? null
              : (iconKey) {
            onIconChanged(service, iconKey);
          },
          onColorChanged: isGeral
              ? null
              : (colorValue) {
            onColorChanged(service, colorValue);
          },
          onMoveUp: isGeral || !canMoveUp ? null : () => onMoveUp(service),
          onMoveDown:
          isGeral || !canMoveDown ? null : () => onMoveDown(service),
        );
      },
    );

    return Container(
      width: double.infinity,
      height: compact ? null : double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.34),
        ),
      ),
      child: compact
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScheduleHeaderSection(
            title: 'Serviços',
            icon: Icons.layers_outlined,
            compact: true,
            description:
            'Use as setas nos serviços para definir a ordem.',
            primaryLabel: 'Adicionar serviço',
            primaryIcon: Icons.add,
            onPrimary: onAdd,
          ),
          const SizedBox(height: 10),
          list,
        ],
      )
          : Column(
        children: [
          ScheduleHeaderSection(
            title: 'Serviços',
            icon: Icons.layers_outlined,
            compact: false,
            description:
            'Use as setas nos serviços para definir a ordem.',
            primaryLabel: 'Adicionar serviço',
            primaryIcon: Icons.add,
            onPrimary: onAdd,
          ),
          const SizedBox(height: 10),
          Expanded(child: list),
        ],
      ),
    );
  }
}