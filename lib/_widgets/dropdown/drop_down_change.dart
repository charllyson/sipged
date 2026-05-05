// lib/_widgets/input/drop_down_change.dart
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';

class DropDownChange extends StatefulWidget {
  const DropDownChange({
    super.key,
    required this.controller,

    // Dados
    this.items = const <String>[],
    this.enabled,
    this.validator,
    this.width,

    // UI
    this.labelText,
    this.greyItems = const <String>{},
    this.menuMaxHeight = 260,
    this.tooltipMessage,

    // Callbacks
    this.onChanged,

    // Callback genérico para "Adicionar novo"
    this.onAddNewItem,
    this.onCreateNewItem,
    this.promptForNewItem,
    this.specialItemLabel = 'Adicionar novo',
    this.showSpecialWhenEmpty = true,
    this.showSpecialAlways = false,
    this.sortTransformer,
    this.allowDuplicates = false,

    // Detalhes / edição / remoção
    this.onDetailsTap,
    this.onEditItem,
    this.onDeleteItem,
  });

  final TextEditingController controller;
  final List<String> items;
  final bool? enabled;
  final String? Function(String?)? validator;
  final double? width;

  final String? labelText;
  final Set<String> greyItems;
  final double menuMaxHeight;
  final String? tooltipMessage;

  final void Function(String?)? onChanged;

  final Future<void> Function(String label)? onCreateNewItem;
  final Future<String?> Function(BuildContext context)? promptForNewItem;
  final Future<String?> Function(BuildContext context)? onAddNewItem;

  final String specialItemLabel;
  final bool showSpecialWhenEmpty;
  final bool showSpecialAlways;
  final List<String> Function(List<String>)? sortTransformer;
  final bool allowDuplicates;

  final Future<void> Function(BuildContext context, String value)? onDetailsTap;
  final Future<void> Function(BuildContext context, String value)? onEditItem;
  final Future<void> Function(BuildContext context, String value)? onDeleteItem;

  @override
  State<DropDownChange> createState() => _DropDownChangeState();
}

class _DropDownChangeState extends State<DropDownChange> {
  static const String _kSpecialValue = '__dropdown_action__';

  late List<String> _items;
  String? _selected;
  String? _lastControllerText;

  bool _handlingSpecialAction = false;

  @override
  void initState() {
    super.initState();

    _items = _dedupe(widget.items);
    _applySort();

    _lastControllerText = widget.controller.text.trim();

    if (_items.contains(_lastControllerText)) {
      _selected = _lastControllerText;
    } else {
      _selected = null;
    }
  }

  @override
  void didUpdateWidget(covariant DropDownChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool shouldUpdate = false;

    if (oldWidget.items != widget.items) {
      _items = _dedupe(widget.items);
      _applySort();

      final currentText = widget.controller.text.trim();

      if (_items.contains(currentText)) {
        _selected = currentText;
      } else if (currentText.isEmpty) {
        _selected = null;
      } else if (_selected != null && !_items.contains(_selected)) {
        _selected = null;
      }

      shouldUpdate = true;
    }

    final currentControllerText = widget.controller.text.trim();

    if (currentControllerText != _lastControllerText) {
      _lastControllerText = currentControllerText;

      if (_items.contains(currentControllerText)) {
        _selected = currentControllerText;
      } else if (currentControllerText.isEmpty) {
        _selected = null;
      }

      shouldUpdate = true;
    }

    if (shouldUpdate && mounted) {
      setState(() {});
    }
  }

  List<String> _dedupe(List<String> source) {
    if (widget.allowDuplicates) {
      return source.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return LinkedHashSet<String>.from(
      source.map((e) => e.trim()).where((e) => e.isNotEmpty),
    ).toList();
  }

  void _applySort() {
    if (widget.sortTransformer != null) {
      _items = widget.sortTransformer!(_items.toList());
    }
  }

  String _s(Object? value) {
    return (value is String ? value : value?.toString() ?? '').trim();
  }

  TextStyle _styleFor(String value, {bool asSelected = false}) {
    final isGrey = widget.greyItems.contains(value);

    return TextStyle(
      color: isGrey ? Colors.grey : Colors.black,
      fontWeight: asSelected ? FontWeight.w500 : FontWeight.normal,
    );
  }

  List<DropdownMenuItem<String>> _buildItemsInternal() {
    final list = <DropdownMenuItem<String>>[];

    for (final value in _items) {
      list.add(
        DropdownMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: _styleFor(value),
                ),
              ),
              if (widget.onDetailsTap != null)
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Detalhes',
                  onPressed: () async {
                    await widget.onDetailsTap!(context, value);
                  },
                ),
              if (widget.onEditItem != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Editar',
                  onPressed: () async {
                    await widget.onEditItem!(context, value);
                  },
                ),
              if (widget.onDeleteItem != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Excluir',
                  onPressed: () async {
                    await widget.onDeleteItem!(context, value);
                  },
                ),
            ],
          ),
        ),
      );
    }

    final canShowSpecial = widget.specialItemLabel.trim().isNotEmpty &&
        (widget.showSpecialAlways ||
            (widget.showSpecialWhenEmpty && _items.isEmpty));

    if (canShowSpecial) {
      list.add(
        DropdownMenuItem<String>(
          value: _kSpecialValue,
          child: Row(
            children: [
              const Icon(Icons.add, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.specialItemLabel,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return list;
  }

  Future<void> _handleAddNewItem({
    required String? previousSelected,
    required String previousControllerText,
  }) async {
    if (_handlingSpecialAction) return;

    _handlingSpecialAction = true;

    if (mounted) {
      setState(() {
        _selected = previousSelected;
        widget.controller.text = previousControllerText;
        _lastControllerText = previousControllerText;
      });
    }

    // Essencial: espera o menu do Dropdown fechar antes de abrir o Dialog.
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (!mounted) {
      _handlingSpecialAction = false;
      return;
    }

    String? label;

    if (widget.onAddNewItem != null) {
      label = await widget.onAddNewItem!(context);
    } else if (widget.promptForNewItem != null) {
      label = await widget.promptForNewItem!(context);
    } else {
      label = await _defaultPrompt(context);
    }

    if (!mounted) {
      _handlingSpecialAction = false;
      return;
    }

    final trimmed = _s(label);

    if (trimmed.isEmpty) {
      setState(() {
        _selected = previousSelected;
        widget.controller.text = previousControllerText;
        _lastControllerText = previousControllerText;
      });

      _handlingSpecialAction = false;
      return;
    }

    if (!widget.allowDuplicates &&
        _items.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
      final existing = _items.firstWhere(
            (e) => e.toLowerCase() == trimmed.toLowerCase(),
      );

      setState(() {
        _selected = existing;
        widget.controller.text = existing;
        _lastControllerText = existing;
      });

      widget.onChanged?.call(existing);

      _handlingSpecialAction = false;
      return;
    }

    if (widget.onCreateNewItem != null) {
      await widget.onCreateNewItem!(trimmed);

      if (!mounted) {
        _handlingSpecialAction = false;
        return;
      }

      _handlingSpecialAction = false;
      return;
    }

    setState(() {
      _items = _dedupe([..._items, trimmed]);
      _applySort();

      _selected = trimmed;
      widget.controller.text = trimmed;
      _lastControllerText = trimmed;
    });

    widget.onChanged?.call(trimmed);

    _handlingSpecialAction = false;
  }

  Future<String?> _defaultPrompt(BuildContext context) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return WindowDialog(
          title: widget.specialItemLabel,
          onClose: () => Navigator.of(dialogCtx).pop(),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: ctrl,
                  labelText: 'Digite o nome',
                  textInputAction: TextInputAction.done,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe um nome';
                    }

                    return null;
                  },
                  onSubmitted: (v) {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogCtx).pop(v.trim());
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.of(dialogCtx).pop(ctrl.text.trim());
                        }
                      },
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    ctrl.dispose();

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled ?? true;

    final items = _buildItemsInternal();

    final safeSelected = items.any((e) => e.value == _selected) &&
        _selected != _kSpecialValue
        ? _selected
        : null;

    return SizedBox(
      width: widget.width ?? 160,
      child: Tooltip(
        message: widget.tooltipMessage ?? '',
        child: DropdownButtonFormField<String>(
          key: ValueKey(
            'dropdown-${widget.labelText ?? ""}-${safeSelected ?? "null"}-${_items.length}',
          ),
          isDense: true,
          isExpanded: true,
          menuMaxHeight: widget.menuMaxHeight,
          dropdownColor: Colors.white,

          // Mantém controlado e impede o valor especial de ficar selecionado.
          initialValue: safeSelected,

          validator: (val) {
            if (val == _kSpecialValue) return null;
            return widget.validator?.call(val);
          },
          selectedItemBuilder: (ctx) {
            final values = items.map((e) => e.value!).toList();

            return values.map((v) {
              final isSpecial = v == _kSpecialValue;
              final text = isSpecial ? widget.specialItemLabel : v;

              final style = isSpecial
                  ? const TextStyle(
                fontWeight: FontWeight.w100,
                color: Colors.grey,
              )
                  : _styleFor(v, asSelected: true);

              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: style,
                ),
              );
            }).toList();
          },
          items: items,
          onChanged: !isEnabled || _handlingSpecialAction
              ? null
              : (selected) async {
            final previousSelected = _selected;
            final previousControllerText = widget.controller.text;

            if (selected == _kSpecialValue) {
              await _handleAddNewItem(
                previousSelected: previousSelected,
                previousControllerText: previousControllerText,
              );
              return;
            }

            setState(() {
              _selected = selected;
              widget.controller.text = selected ?? '';
              _lastControllerText = selected ?? '';
            });

            widget.onChanged?.call(selected);
          },
          iconSize: 20,
          decoration: InputDecoration(
            fillColor: isEnabled ? Colors.white : Colors.grey.shade200,
            filled: true,
            labelText: widget.labelText,
            labelStyle: TextStyle(
              color: isEnabled ? Colors.grey : Colors.grey.shade500,
            ),
            hintStyle: TextStyle(
              color: isEnabled ? Colors.grey : Colors.grey.shade400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isEnabled ? Colors.grey : Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isEnabled ? Colors.blue : Colors.grey.shade400,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red.shade700),
              borderRadius: BorderRadius.circular(10),
            ),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}