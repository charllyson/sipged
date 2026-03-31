// lib/_widgets/input/drop_down_change.dart
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';

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

    // ==== NOVO: callback genérico para "Adicionar novo" ====
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

  // Dados básicos
  final TextEditingController controller;
  final List<String> items;
  final bool? enabled;
  final String? Function(String?)? validator;
  final double? width;

  // UI
  final String? labelText;
  final Set<String> greyItems;
  final double menuMaxHeight;
  final String? tooltipMessage;

  // Callbacks
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

  late List<String> _items; // labels (sem duplicados)
  String? _selected;        // label selecionado

  String? _lastControllerText;

  @override
  void initState() {
    super.initState();
    _items = _dedupe(widget.items);
    _applySort();

    _lastControllerText = widget.controller.text;

    if (_items.contains(widget.controller.text)) {
      _selected = widget.controller.text;
    } else {
      _selected = null;
    }
  }

  @override
  void didUpdateWidget(covariant DropDownChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Quando a lista de itens muda
    if (oldWidget.items != widget.items) {
      _items = _dedupe(widget.items);
      _applySort();

      if (_items.contains(widget.controller.text)) {
        _selected = widget.controller.text;
      } else if (widget.controller.text.isEmpty) {
        _selected = null;
      }
      setState(() {});
    }

    // Quando o texto do controller muda por fora
    if (widget.controller.text != _lastControllerText) {
      _lastControllerText = widget.controller.text;

      if (_items.contains(widget.controller.text)) {
        _selected = widget.controller.text;
      } else if (widget.controller.text.isEmpty) {
        _selected = null;
      }
      setState(() {});
    }
  }

  // Remove duplicados preservando ordem
  List<String> _dedupe(List<String> source) {
    return LinkedHashSet<String>.from(source).toList();
  }

  void _applySort() {
    if (widget.sortTransformer != null) {
      _items = widget.sortTransformer!(_items.toList());
    }
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

    final canShowSpecial = widget.specialItemLabel.isNotEmpty &&
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

  Future<void> _handleAddNewItem() async {
    String? label;
    if (widget.onAddNewItem != null) {
      label = await widget.onAddNewItem!(context);
    } else if (widget.promptForNewItem != null) {
      label = await widget.promptForNewItem!(context);
    } else {
      label = await _defaultPrompt(context);
    }

    if (label == null) return;
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    if (!widget.allowDuplicates &&
        _items.any((e) => e.toLowerCase() == trimmed.toLowerCase())) {
      setState(() {
        _selected = _items.firstWhere(
              (e) => e.toLowerCase() == trimmed.toLowerCase(),
        );
        widget.controller.text = _selected!;
        _lastControllerText = _selected!;
      });
      widget.onChanged?.call(_selected);
      return;
    }

    if (widget.onCreateNewItem != null) {
      await widget.onCreateNewItem!(trimmed);
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
  }

  Future<String?> _defaultPrompt(BuildContext context) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
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
                          Navigator.of(dialogCtx)
                              .pop(ctrl.text.trim());
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
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.enabled ?? true;

    // Gera a lista UMA vez por build
    final items = _buildItemsInternal();

    // Garante que o value SEMPRE exista nos items (ou seja null)
    final safeSelected = items.any((e) => e.value == _selected)
        ? _selected
        : null;

    return SizedBox(
      width: widget.width ?? 160,
      child: Tooltip(
        message: widget.tooltipMessage ?? '',
        child: DropdownButtonFormField<String>(
          isDense: true,
          isExpanded: true,
          menuMaxHeight: widget.menuMaxHeight,
          validator: (val) {
            if (val == _kSpecialValue) return null;
            return widget.validator?.call(val);
          },
          dropdownColor: Colors.white,
          initialValue: safeSelected,
          selectedItemBuilder: (ctx) {
            final values = items.map((e) => e.value!).toList();
            return values.map((v) {
              final text =
              v == _kSpecialValue ? widget.specialItemLabel : v;
              final style = v == _kSpecialValue
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
          onChanged: !isEnabled
              ? null
              : (selected) async {
            if (selected == _kSpecialValue) {
              await _handleAddNewItem();
              setState(() {});
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
