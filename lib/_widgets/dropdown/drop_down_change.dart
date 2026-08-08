import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_change.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tile.dart';
import 'package:sipged/_widgets/overlays/balloon/balloon_tip.dart';

class DropDownChange extends StatefulWidget {
  const DropDownChange({
    super.key,
    required this.controller,

    // Dados
    this.items = const <String>[],
    this.enabled,
    this.validator,
    this.width,
    this.height,

    // UI
    this.labelText,
    this.labelStyle,
    this.labelFontSize = 14.0,
    this.valueColor,
    this.valueFontSize = 14.0,
    this.valueFontWeight,
    this.fillColor,
    this.greyItems = const <String>{},
    this.menuMaxHeight = 260,
    this.tooltipMessage,

    // Aparência da borda
    this.borderRadius = 10.0,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor = Colors.red,
    this.borderWidth = 1.0,
    this.contentPadding,
    this.textAlignVertical,

    // Balloon
    this.useBalloon = true,
    this.balloonWidth,
    this.balloonTipSide = BalloonTipSide.top,
    this.closeBalloonOnScroll = true,

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
  final double? height;

  final String? labelText;
  final TextStyle? labelStyle;
  final double labelFontSize;
  final Color? valueColor;
  final double valueFontSize;
  final FontWeight? valueFontWeight;
  final Color? fillColor;
  final Set<String> greyItems;
  final double menuMaxHeight;
  final String? tooltipMessage;

  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color errorBorderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlignVertical? textAlignVertical;

  final bool useBalloon;
  final double? balloonWidth;
  final BalloonTipSide balloonTipSide;
  final bool closeBalloonOnScroll;

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

  final GlobalKey _fieldKey = GlobalKey();

  late List<String> _items;
  String? _selected;
  String? _lastControllerText;

  bool _handlingSpecialAction = false;
  bool _balloonOpen = false;
  bool _scheduledBalloonRebuild = false;

  OverlayEntry? _overlayEntry;
  ScrollPosition? _scrollPosition;

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

    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindNearestScrollPosition();
  }

  @override
  void didUpdateWidget(covariant DropDownChange oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);

      _lastControllerText = widget.controller.text.trim();

      final controllerText = _lastControllerText ?? '';

      if (_items.contains(controllerText)) {
        _selected = controllerText;
      } else if (controllerText.isEmpty) {
        _selected = null;
      }
    }

    if (oldWidget.closeBalloonOnScroll != widget.closeBalloonOnScroll) {
      _bindNearestScrollPosition();
    }

    bool shouldRefreshVisualState = false;

    if (oldWidget.items != widget.items ||
        oldWidget.allowDuplicates != widget.allowDuplicates ||
        oldWidget.sortTransformer != widget.sortTransformer) {
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

      shouldRefreshVisualState = true;
    }

    final currentControllerText = widget.controller.text.trim();

    if (currentControllerText != _lastControllerText) {
      _lastControllerText = currentControllerText;

      if (_items.contains(currentControllerText)) {
        _selected = currentControllerText;
      } else if (currentControllerText.isEmpty) {
        _selected = null;
      }

      shouldRefreshVisualState = true;
    }

    if (shouldRefreshVisualState) {
      _scheduleRebuildBalloon();
    }
  }

  @override
  void dispose() {
    _closeBalloon();
    _unbindScrollPosition();
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final currentControllerText = widget.controller.text.trim();

    if (currentControllerText == _lastControllerText) return;

    _lastControllerText = currentControllerText;

    if (_items.contains(currentControllerText)) {
      _selected = currentControllerText;
    } else if (currentControllerText.isEmpty) {
      _selected = null;
    }

    if (mounted) {
      setState(() {});
    }

    _scheduleRebuildBalloon();
  }

  void _bindNearestScrollPosition() {
    _unbindScrollPosition();

    if (!widget.closeBalloonOnScroll) return;

    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;

    if (position == null) return;

    _scrollPosition = position;
    _scrollPosition!.isScrollingNotifier.addListener(_handleScrollActivity);
  }

  void _unbindScrollPosition() {
    _scrollPosition?.isScrollingNotifier.removeListener(_handleScrollActivity);
    _scrollPosition = null;
  }

  void _handleScrollActivity() {
    if (!widget.closeBalloonOnScroll) return;

    final position = _scrollPosition;
    if (position == null) return;

    if (position.isScrollingNotifier.value) {
      _closeBalloon();
    }
  }

  List<String> _dedupe(List<String> source) {
    final clean = source.map((e) => e.trim()).where((e) => e.isNotEmpty);

    if (widget.allowDuplicates) {
      return clean.toList();
    }

    return LinkedHashSet<String>.from(clean).toList();
  }

  void _applySort() {
    if (widget.sortTransformer != null) {
      _items = widget.sortTransformer!(_items.toList());
    }
  }

  String _s(Object? value) {
    return (value is String ? value : value?.toString() ?? '').trim();
  }

  TextStyle _styleFor(
      String value, {
        bool asSelected = false,
      }) {
    final isGrey = widget.greyItems.contains(value);

    return TextStyle(
      color: widget.valueColor ?? (isGrey ? Colors.grey : Colors.black),
      fontWeight:
      widget.valueFontWeight ?? (asSelected ? FontWeight.w500 : FontWeight.normal),
      fontSize: widget.valueFontSize,
      height: 1.0,
    );
  }

  bool get _canShowSpecial {
    return widget.specialItemLabel.trim().isNotEmpty &&
        (widget.showSpecialAlways ||
            (widget.showSpecialWhenEmpty && _items.isEmpty));
  }

  List<String> get _allValues {
    return [
      ..._items,
      if (_canShowSpecial) _kSpecialValue,
    ];
  }

  EdgeInsetsGeometry get _effectiveContentPadding {
    if (widget.contentPadding != null) {
      return widget.contentPadding!;
    }

    if (widget.height == null) {
      return const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      );
    }

    return const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 0,
    );
  }

  OutlineInputBorder _border({
    required Color color,
    required double width,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  double _safeWidth(
      double? width, {
        required double fallback,
      }) {
    if (width != null && width.isFinite && width > 0) {
      return width;
    }

    return fallback;
  }

  double _safeBalloonWidth({
    required double fieldWidth,
  }) {
    final configuredWidth = widget.balloonWidth;

    if (configuredWidth != null &&
        configuredWidth.isFinite &&
        configuredWidth > 0) {
      return configuredWidth;
    }

    if (fieldWidth.isFinite && fieldWidth > 0) {
      return fieldWidth.clamp(180.0, 360.0).toDouble();
    }

    return 220.0;
  }

  Future<void> _handleAddNewItem({
    required String? previousSelected,
    required String previousControllerText,
  }) async {
    if (_handlingSpecialAction) return;

    _handlingSpecialAction = true;

    _closeBalloon();

    if (mounted) {
      setState(() {
        _selected = previousSelected;
        widget.controller.text = previousControllerText;
        _lastControllerText = previousControllerText;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 80));

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

  void _toggleBalloon() {
    if (_balloonOpen) {
      _closeBalloon();
      return;
    }

    _openBalloon();
  }

  void _openBalloon() {
    if (!mounted) return;
    if (_handlingSpecialAction) return;
    if (widget.enabled == false) return;

    _closeBalloon();

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject();
    final targetBox = _fieldKey.currentContext?.findRenderObject();

    if (overlayBox is! RenderBox || targetBox is! RenderBox) {
      return;
    }

    if (!overlayBox.attached || !targetBox.attached) {
      return;
    }

    if (!targetBox.hasSize || !overlayBox.hasSize) {
      return;
    }

    final fieldWidth = targetBox.size.width;
    final balloonWidth = _safeBalloonWidth(fieldWidth: fieldWidth);

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) {
        if (!mounted || !targetBox.attached || !overlayBox.attached) {
          return const SizedBox.shrink();
        }

        if (!targetBox.hasSize || !overlayBox.hasSize) {
          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeBalloon,
                onPanDown: (_) {
                  if (widget.closeBalloonOnScroll) {
                    _closeBalloon();
                  }
                },
                child: const SizedBox.expand(),
              ),
            ),
            BalloonChange(
              targetBox: targetBox,
              overlayBox: overlayBox,
              width: balloonWidth,
              maxHeight: widget.menuMaxHeight,
              tipSide: widget.balloonTipSide,
              topGap: 4,
              screenMargin: 8,
              showHeader: false,
              title: null,
              headerIcon: null,
              items: _buildBalloonItems(),
              emptyIcon: Icons.list_alt_rounded,
              emptyMessage: 'Nenhum item encontrado.',
            ),
          ],
        );
      },
    );

    overlay.insert(_overlayEntry!);

    if (mounted) {
      setState(() {
        _balloonOpen = true;
      });
    }
  }

  void _scheduleRebuildBalloon() {
    if (!mounted) return;
    if (_scheduledBalloonRebuild) return;

    _scheduledBalloonRebuild = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduledBalloonRebuild = false;

      if (!mounted) return;

      _rebuildBalloon();
    });
  }

  void _rebuildBalloon() {
    if (!mounted) return;

    final entry = _overlayEntry;

    if (entry == null) return;

    entry.markNeedsBuild();
  }

  void _closeBalloon() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (_balloonOpen && mounted) {
      setState(() {
        _balloonOpen = false;
      });
    } else {
      _balloonOpen = false;
    }
  }

  List<BalloonTileData> _buildBalloonItems() {
    final values = _allValues;

    return values.map((value) {
      final isSpecial = value == _kSpecialValue;

      if (isSpecial) {
        return BalloonTileData(
          id: value,
          icon: Icons.add_rounded,
          accentColor: const Color(0xFF2563EB),
          highlighted: false,
          title: Text(
            widget.specialItemLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
          onTap: () async {
            final previousSelected = _selected;
            final previousControllerText = widget.controller.text;

            await _handleAddNewItem(
              previousSelected: previousSelected,
              previousControllerText: previousControllerText,
            );
          },
        );
      }

      final selected = value == _selected;
      final isGrey = widget.greyItems.contains(value);
      final accent =
      selected ? const Color(0xFF2563EB) : const Color(0xFF475569);

      return BalloonTileData(
        id: value,
        icon: selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        accentColor: isGrey ? Colors.grey : accent,
        highlighted: selected,
        title: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: TextStyle(
                  color: isGrey ? Colors.grey : const Color(0xFF0F172A),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                  height: 1.0,
                ),
              ),
            ),
            if (widget.onDetailsTap != null) ...[
              const SizedBox(width: 4),
              _ActionIconButton(
                icon: Icons.info_outline_rounded,
                tooltip: 'Detalhes',
                color: const Color(0xFF64748B),
                onTap: () async {
                  _closeBalloon();
                  await widget.onDetailsTap!(context, value);
                },
              ),
            ],
            if (widget.onEditItem != null) ...[
              const SizedBox(width: 4),
              _ActionIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Editar',
                color: const Color(0xFF64748B),
                onTap: () async {
                  _closeBalloon();
                  await widget.onEditItem!(context, value);
                },
              ),
            ],
            if (widget.onDeleteItem != null) ...[
              const SizedBox(width: 4),
              _ActionIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Excluir',
                color: const Color(0xFFDC2626),
                onTap: () async {
                  _closeBalloon();
                  await widget.onDeleteItem!(context, value);
                },
              ),
            ],
          ],
        ),
        onTap: () {
          setState(() {
            _selected = value;
            widget.controller.text = value;
            _lastControllerText = value;
          });

          widget.onChanged?.call(value);
          _closeBalloon();
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.useBalloon) {
      return _LegacyDropdown(
        controller: widget.controller,
        items: _items,
        selected: _selected,
        enabled: widget.enabled,
        validator: widget.validator,
        width: _safeWidth(widget.width, fallback: 160),
        height: widget.height,
        labelText: widget.labelText,
        labelStyle: widget.labelStyle,
        labelFontSize: widget.labelFontSize,
        valueColor: widget.valueColor,
        valueFontSize: widget.valueFontSize,
        valueFontWeight: widget.valueFontWeight,
        fillColor: widget.fillColor,
        greyItems: widget.greyItems,
        menuMaxHeight: widget.menuMaxHeight,
        tooltipMessage: widget.tooltipMessage,
        borderRadius: widget.borderRadius,
        borderColor: widget.borderColor,
        focusedBorderColor: widget.focusedBorderColor,
        errorBorderColor: widget.errorBorderColor,
        borderWidth: widget.borderWidth,
        contentPadding: widget.contentPadding,
        textAlignVertical: widget.textAlignVertical,
        onChanged: (value) {
          setState(() {
            _selected = value;
            widget.controller.text = value ?? '';
            _lastControllerText = value ?? '';
          });

          widget.onChanged?.call(value);
        },
      );
    }

    final isEnabled = widget.enabled ?? true;

    final effectiveBorderColor = widget.borderColor ?? Colors.grey.shade500;
    final effectiveFocusedColor = widget.focusedBorderColor ?? Colors.blue;

    final safeWidth = _safeWidth(widget.width, fallback: 160);

    final valueStyle = _selected == null
        ? TextStyle(
      color: widget.valueColor ?? Colors.black,
      fontWeight: widget.valueFontWeight ?? FontWeight.normal,
      fontSize: widget.valueFontSize,
      height: 1.0,
    )
        : _styleFor(_selected!, asSelected: true);

    return SizedBox(
      key: _fieldKey,
      width: safeWidth,
      height: widget.height,
      child: Tooltip(
        message: widget.tooltipMessage ?? '',
        child: TextFormField(
          controller: widget.controller,
          enabled: isEnabled,
          readOnly: true,
          style: valueStyle,
          onTap: isEnabled ? _toggleBalloon : null,
          textAlignVertical:
          widget.textAlignVertical ?? TextAlignVertical.center,
          validator: (_) {
            return widget.validator?.call(widget.controller.text.trim());
          },
          decoration: InputDecoration(
            fillColor:
            isEnabled ? widget.fillColor ?? Colors.white : Colors.grey.shade200,
            filled: true,
            labelText: widget.labelText,
            labelStyle: widget.labelStyle ??
                TextStyle(
                  color: isEnabled ? Colors.grey : Colors.grey.shade500,
                  fontSize: widget.labelFontSize,
                  height: 1.0,
                ),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            hintStyle: TextStyle(
              color: isEnabled ? Colors.grey : Colors.grey.shade400,
              fontSize: widget.valueFontSize,
              height: 1.0,
            ),
            isDense: widget.height != null,
            contentPadding: _effectiveContentPadding,
            suffixIcon: Icon(
              _balloonOpen
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isEnabled ? Colors.grey.shade700 : Colors.grey.shade400,
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: 34,
              minHeight: widget.height ?? 48,
            ),
            enabledBorder: _border(
              color: isEnabled ? effectiveBorderColor : Colors.grey.shade400,
              width: widget.borderWidth,
            ),
            focusedBorder: _border(
              color: isEnabled ? effectiveFocusedColor : Colors.grey.shade400,
              width: widget.borderWidth,
            ),
            errorBorder: _border(
              color: widget.errorBorderColor,
              width: widget.borderWidth,
            ),
            focusedErrorBorder: _border(
              color: widget.errorBorderColor,
              width: widget.borderWidth,
            ),
            disabledBorder: _border(
              color: Colors.grey.shade400,
              width: widget.borderWidth,
            ),
            border: _border(
              color: Colors.grey.shade400,
              width: widget.borderWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 15,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _LegacyDropdown extends StatelessWidget {
  const _LegacyDropdown({
    required this.controller,
    required this.items,
    required this.selected,
    required this.enabled,
    required this.validator,
    required this.width,
    required this.height,
    required this.labelText,
    required this.labelStyle,
    required this.labelFontSize,
    required this.valueColor,
    required this.valueFontSize,
    required this.valueFontWeight,
    required this.fillColor,
    required this.greyItems,
    required this.menuMaxHeight,
    required this.tooltipMessage,
    required this.borderRadius,
    required this.borderColor,
    required this.focusedBorderColor,
    required this.errorBorderColor,
    required this.borderWidth,
    required this.contentPadding,
    required this.textAlignVertical,
    required this.onChanged,
  });

  final TextEditingController controller;
  final List<String> items;
  final String? selected;
  final bool? enabled;
  final String? Function(String?)? validator;
  final double? width;
  final double? height;
  final String? labelText;
  final TextStyle? labelStyle;
  final double labelFontSize;
  final Color? valueColor;
  final double valueFontSize;
  final FontWeight? valueFontWeight;
  final Color? fillColor;
  final Set<String> greyItems;
  final double menuMaxHeight;
  final String? tooltipMessage;
  final double borderRadius;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color errorBorderColor;
  final double borderWidth;
  final EdgeInsetsGeometry? contentPadding;
  final TextAlignVertical? textAlignVertical;
  final ValueChanged<String?> onChanged;

  TextStyle _styleFor(String value, {bool asSelected = false}) {
    final isGrey = greyItems.contains(value);

    return TextStyle(
      color: valueColor ?? (isGrey ? Colors.grey : Colors.black),
      fontWeight:
      valueFontWeight ?? (asSelected ? FontWeight.w500 : FontWeight.normal),
      fontSize: valueFontSize,
      height: 1.0,
    );
  }

  OutlineInputBorder _border({
    required Color color,
    required double width,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  EdgeInsetsGeometry get _effectiveContentPadding {
    if (contentPadding != null) {
      return contentPadding!;
    }

    if (height == null) {
      return const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 14,
      );
    }

    return const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 0,
    );
  }

  double _safeWidth(
      double? width, {
        required double fallback,
      }) {
    if (width != null && width.isFinite && width > 0) {
      return width;
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled ?? true;

    final effectiveBorderColor = borderColor ?? Colors.grey.shade500;
    final effectiveFocusedColor = focusedBorderColor ?? Colors.blue;

    final safeSelected = items.contains(selected) ? selected : null;
    final safeWidth = _safeWidth(width, fallback: 160);

    return SizedBox(
      width: safeWidth,
      height: height,
      child: Tooltip(
        message: tooltipMessage ?? '',
        child: DropdownButtonFormField<String>(
          key: ValueKey(
            'legacy-dropdown-${labelText ?? ""}-${safeSelected ?? "null"}-${items.length}',
          ),
          isDense: height != null,
          isExpanded: true,
          menuMaxHeight: menuMaxHeight,
          dropdownColor: Colors.white,
          initialValue: safeSelected,
          validator: validator,
          selectedItemBuilder: (ctx) {
            return items.map((v) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  v,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: _styleFor(v, asSelected: true),
                ),
              );
            }).toList();
          },
          items: items.map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                softWrap: false,
                style: _styleFor(value),
              ),
            );
          }).toList(),
          onChanged: isEnabled
              ? (value) {
            controller.text = value ?? '';
            onChanged(value);
          }
              : null,
          iconSize: 20,
          decoration: InputDecoration(
            fillColor: isEnabled ? fillColor ?? Colors.white : Colors.grey.shade200,
            filled: true,
            labelText: labelText,
            labelStyle: labelStyle ??
                TextStyle(
                  color: isEnabled ? Colors.grey : Colors.grey.shade500,
                  fontSize: labelFontSize,
                  height: 1.0,
                ),
            hintStyle: TextStyle(
              color: isEnabled ? Colors.grey : Colors.grey.shade400,
              fontSize: valueFontSize,
              height: 1.0,
            ),
            isDense: height != null,
            contentPadding: _effectiveContentPadding,
            enabledBorder: _border(
              color: isEnabled ? effectiveBorderColor : Colors.grey.shade400,
              width: borderWidth,
            ),
            focusedBorder: _border(
              color: isEnabled ? effectiveFocusedColor : Colors.grey.shade400,
              width: borderWidth,
            ),
            errorBorder: _border(
              color: errorBorderColor,
              width: borderWidth,
            ),
            focusedErrorBorder: _border(
              color: errorBorderColor,
              width: borderWidth,
            ),
            disabledBorder: _border(
              color: Colors.grey.shade400,
              width: borderWidth,
            ),
            border: _border(
              color: Colors.grey.shade400,
              width: borderWidth,
            ),
          ),
        ),
      ),
    );
  }
}