// lib/screens/common/setup/initial_setup_form.dart

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';

class InitialSetupForm extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool enabled;

  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelectItem;
  final VoidCallback onClearSelection;

  final String addLabel;
  final String saveLabel;
  final String removeLabel;

  final bool primaryEnabled;
  final VoidCallback onPrimaryAction;
  final VoidCallback onRemoveAction;

  final ValueChanged<String>? onChanged;

  final Widget? trailingWidget;
  final Widget? extraBottom;

  const InitialSetupForm({
    super.key,
    required this.controller,
    required this.labelText,
    required this.enabled,
    required this.items,
    required this.selectedItem,
    required this.onSelectItem,
    required this.onClearSelection,
    required this.addLabel,
    required this.saveLabel,
    required this.removeLabel,
    required this.primaryEnabled,
    required this.onPrimaryAction,
    required this.onRemoveAction,
    this.onChanged,
    this.trailingWidget,
    this.extraBottom,
  });

  Widget _buildActionText({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    Color? color,
  }) {
    final resolvedColor = enabled ? (color ?? Colors.blue) : Colors.grey;

    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor: resolvedColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }

  Widget _emptyText() {
    return const Text(
      'Nenhum item cadastrado.',
      style: TextStyle(
        color: Color(0xFF98A2B3),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildList() {
    final hasSelection = selectedItem != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;

        final list = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selectedItem == item;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: !enabled
                  ? null
                  : () {
                if (isSelected) {
                  onClearSelection();
                } else {
                  onSelectItem(item);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(
                    color: Colors.blue,
                    width: 1.3,
                  )
                      : null,
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.06)
                      : Colors.transparent,
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        );

        final actions = Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.end,
          children: [
            _buildActionText(
              label: hasSelection ? saveLabel : addLabel,
              enabled: primaryEnabled,
              onTap: onPrimaryAction,
            ),
            if (hasSelection)
              _buildActionText(
                label: removeLabel,
                enabled: enabled,
                onTap: onRemoveAction,
                color: Colors.red,
              ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (items.isEmpty) _emptyText() else list,
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: actions,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: items.isEmpty ? _emptyText() : list,
            ),
            const SizedBox(width: 12),
            actions,
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomTextField(
                controller: controller,
                labelText: labelText,
                enabled: enabled,
                onChanged: onChanged,
              ),
            ),
            if (trailingWidget != null) ...[
              const SizedBox(width: 12),
              trailingWidget!,
            ],
          ],
        ),
        const SizedBox(height: 10),
        _buildList(),
        if (extraBottom != null) ...[
          const SizedBox(height: 10),
          extraBottom!,
        ],
      ],
    );
  }
}