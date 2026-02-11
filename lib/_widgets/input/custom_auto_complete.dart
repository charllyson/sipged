import 'package:flutter/material.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

typedef IdOf<T> = String? Function(T item);
typedef TextOf<T> = String Function(T item);
typedef PhotoOf<T> = String? Function(T item);

class CustomAutoComplete<T extends Object> extends StatefulWidget {
  final String? label;
  final TextEditingController controller;

  /// Lista genérica de itens
  final List<T> allList;

  /// Extractors
  final IdOf<T> idOf;
  final TextOf<T> displayOf; // texto exibido no campo quando selecionado
  final TextOf<T>? subtitleOf; // opcional (dropdown)
  final PhotoOf<T>? photoUrlOf; // opcional (avatar)

  /// Busca customizável; se null, usa display+subtitle.
  final bool Function(T item, String queryLower)? match;

  final String? hint;
  final bool enabled;
  final String? Function(String? value)? validator;

  /// ID já salvo no doc
  final String? initialId;

  /// Devolve o ID selecionado (ou '' ao limpar)
  final void Function(String id)? onChanged;

  const CustomAutoComplete({
    super.key,
    required this.controller,
    required this.allList,
    required this.idOf,
    required this.displayOf,
    this.subtitleOf,
    this.photoUrlOf,
    this.match,
    required this.enabled,
    this.label,
    this.hint,
    this.validator,
    this.initialId,
    this.onChanged,
  });

  @override
  State<CustomAutoComplete<T>> createState() => _CustomAutoCompleteState<T>();
}

class _CustomAutoCompleteState<T extends Object>
    extends State<CustomAutoComplete<T>> {
  String? _selectedId;

  // ✅ controla hover no dropdown
  int _hoverIndex = -1;

  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _hydrateFromProps();
  }

  @override
  void didUpdateWidget(covariant CustomAutoComplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final initialChanged = oldWidget.initialId != widget.initialId;
    final listChanged = oldWidget.allList != widget.allList;

    if (initialChanged || listChanged) {
      _hydrateFromProps();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _hydrateFromProps() {
    final incoming = (widget.initialId?.isNotEmpty ?? false)
        ? widget.initialId
        : _guessIdFromText(widget.controller.text);

    _selectedId = (incoming?.isNotEmpty ?? false) ? incoming : null;

    if (_selectedId != null && _selectedId!.isNotEmpty) {
      final item = _findById(_selectedId!);
      if (item != null) {
        final wanted = widget.displayOf(item);
        if (widget.controller.text != wanted) {
          widget.controller.text = wanted;
        }
      } else {
        _selectedId = null;
      }
    }

    if (mounted) setState(() {});
  }

  T? _findById(String id) {
    try {
      return widget.allList.firstWhere((it) => (widget.idOf(it) ?? '') == id);
    } catch (_) {
      return null;
    }
  }

  String? _guessIdFromText(String t) {
    final s = t.trim();
    if (s.isEmpty) return null;
    final looksUid = s.length >= 20 && !s.contains(' ');
    return looksUid ? s : null;
  }

  void _selectItem(T item) {
    final id = widget.idOf(item) ?? '';
    _selectedId = id.isNotEmpty ? id : null;

    final txt = widget.displayOf(item);
    if (widget.controller.text != txt) {
      widget.controller.text = txt;
    }

    if (mounted) setState(() {});
    widget.onChanged?.call(id);

    _focusNode.unfocus();
  }

  void _clearSelection() {
    _selectedId = null;
    widget.controller.clear();
    if (mounted) setState(() {});
    widget.onChanged?.call('');
  }

  /// Validação baseada no **ID** selecionado.
  String? _validateById(String? _) {
    if (widget.validator == null) return null;
    return widget.validator!(_selectedId?.isNotEmpty == true ? 'ok' : null);
  }

  @override
  Widget build(BuildContext context) {
    final selected = (_selectedId != null && _selectedId!.isNotEmpty)
        ? _findById(_selectedId!)
        : null;

    final width = responsiveInputWidth(
      context: context,
      itemsPerLine: 3,
      reservedWidth: 98.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
    );

    bool defaultMatcher(T it, String qLower) {
      final a = widget.displayOf(it).toLowerCase();
      final b = (widget.subtitleOf?.call(it) ?? '').toLowerCase();
      return a.contains(qLower) || b.contains(qLower);
    }

    final matcher = widget.match ?? defaultMatcher;

    // ✅ Quando já selecionado: campo readOnly com avatar + limpar
    if (selected != null) {
      final display = widget.displayOf(selected);
      final photoUrl = widget.photoUrlOf?.call(selected);

      // garante texto coerente sem setState no build
      if (widget.controller.text != display) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (widget.controller.text != display) {
            widget.controller.text = display;
          }
        });
      }

      return CustomTextField(
        validator: _validateById,
        enabled: widget.enabled,
        controller: widget.controller,
        labelText: widget.label,
        width: width,
        readOnly: true,

        // ✅ use prefixIcon em vez de prefix
        prefixIcon: (widget.photoUrlOf == null)
            ? null
            : Padding(
          padding: const EdgeInsets.only(left: 8, right: 6),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            backgroundImage: (photoUrl?.isNotEmpty ?? false)
                ? NetworkImage(photoUrl!)
                : null,
            child: (photoUrl?.isEmpty ?? true)
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
        ),

        // ✅ garante área do prefixIcon consistente (centraliza melhor)
        prefixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),

        suffix: widget.enabled
            ? IconButton(
          icon: const Icon(Icons.clear),
          onPressed: _clearSelection,
          tooltip: 'Limpar',
        )
            : null,

        // opcional: ajuste fino de padding
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      );
    }

    // ✅ Não selecionado: RawAutocomplete com controller real
    return Tooltip(
      message: 'Busque pelo termo desejado',
      child: RawAutocomplete<T>(
        textEditingController: widget.controller,
        focusNode: _focusNode,
        displayStringForOption: (it) => widget.displayOf(it),
        optionsBuilder: (TextEditingValue tev) {
          if (!widget.enabled) return Iterable<T>.empty();

          final text = tev.text.trim();
          if (text.isEmpty) return Iterable<T>.empty();

          final q = text.toLowerCase();
          final filtered = widget.allList.where((it) => matcher(it, q));

          return filtered.take(80);
        },
        onSelected: _selectItem,
        fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
          return CustomTextField(
            validator: _validateById,
            enabled: widget.enabled,
            controller: textCtrl,
            focusNode: focusNode,
            labelText: widget.label,
            hintText: widget.hint,
            width: width,
            readOnly: !widget.enabled,
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          if (_hoverIndex >= options.length) _hoverIndex = -1;

          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              color: Colors.white,
              child: SizedBox(
                width: width,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final it = options.elementAt(i);
                    final photoUrl = widget.photoUrlOf?.call(it);
                    final subtitle = widget.subtitleOf?.call(it);
                    final hovering = _hoverIndex == i;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoverIndex = i),
                      onExit: (_) => setState(() => _hoverIndex = -1),
                      cursor: SystemMouseCursors.click,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        color: hovering
                            ? Colors.grey.withOpacity(0.10)
                            : Colors.white,
                        child: ListTile(
                          hoverColor: Colors.transparent,
                          onTap: () => onSelected(it),
                          leading: (widget.photoUrlOf == null)
                              ? null
                              : CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (photoUrl?.isNotEmpty ?? false)
                                ? NetworkImage(photoUrl!)
                                : null,
                            child: (photoUrl?.isEmpty ?? true)
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(widget.displayOf(it)),
                          subtitle: (subtitle == null || subtitle.isEmpty)
                              ? null
                              : Text(subtitle),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
