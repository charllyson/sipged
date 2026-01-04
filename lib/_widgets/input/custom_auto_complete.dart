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

  @override
  void initState() {
    super.initState();
    _hydrateFromProps();
  }

  @override
  void didUpdateWidget(covariant CustomAutoComplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialId != widget.initialId ||
        oldWidget.allList != widget.allList) {
      _hydrateFromProps();
    }
  }

  void _hydrateFromProps() {
    _selectedId = (widget.initialId?.isNotEmpty ?? false)
        ? widget.initialId
        : _guessIdFromText(widget.controller.text);

    if (_selectedId != null && _selectedId!.isNotEmpty) {
      final item = _findById(_selectedId!);
      if (item != null) {
        widget.controller.text = widget.displayOf(item);
      } else {
        // ID não existe mais na lista
        if (widget.controller.text.isEmpty ||
            widget.controller.text == _selectedId) {
          widget.controller.text = '';
        }
      }
    } else {
      widget.controller.text = '';
    }

    setState(() {});
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

    widget.controller.text = widget.displayOf(item);

    setState(() {});
    widget.onChanged?.call(id);
  }

  void _clearSelection() {
    _selectedId = null;
    widget.controller.clear();
    setState(() {});
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

    if (_selectedId == null || _selectedId!.isEmpty) {
      return Tooltip(
        message: 'Busque pelo termo desejado',
        child: Autocomplete<T>(
          optionsBuilder: (TextEditingValue tev) {
            final text = tev.text.trim();
            if (text.isEmpty) return Iterable<T>.empty();

            final q = text.toLowerCase();

            final matcher = widget.match ??
                    (T it, String qLower) {
                  final a = widget.displayOf(it).toLowerCase();
                  final b = (widget.subtitleOf?.call(it) ?? '').toLowerCase();
                  return a.contains(qLower) || b.contains(qLower);
                };

            return widget.allList.where((it) => matcher(it, q));
          },
          displayStringForOption: (it) => widget.displayOf(it),
          fieldViewBuilder: (context, textCtrl, focusNode, _) {
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
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                color: Colors.white, // ✅ fundo branco do dropdown
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

                      final bool hovering = _hoverIndex == i;

                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoverIndex = i),
                        onExit: (_) => setState(() => _hoverIndex = -1),
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          color: hovering
                              ? Colors.grey.withOpacity(0.10) // ✅ hover suave
                              : Colors.white, // ✅ fundo branco por item
                          child: ListTile(
                            hoverColor: Colors
                                .transparent, // evita conflito com hover padrão
                            onTap: () => onSelected(it),
                            leading: (widget.photoUrlOf == null)
                                ? null
                                : CircleAvatar(
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: (photoUrl?.isNotEmpty ?? false)
                                  ? NetworkImage(photoUrl!)
                                  : null,
                              child: (photoUrl?.isEmpty ?? true)
                                  ? const Icon(Icons.person,
                                  color: Colors.grey)
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
          onSelected: (it) => _selectItem(it),
        ),
      );
    }

    final display =
    selected != null ? widget.displayOf(selected) : widget.controller.text;
    final photoUrl =
    selected != null ? widget.photoUrlOf?.call(selected) : null;

    if (widget.controller.text != display) {
      widget.controller.text = display;
    }

    return CustomTextField(
      validator: _validateById,
      enabled: widget.enabled,
      controller: widget.controller,
      labelText: widget.label,
      width: width,
      readOnly: true,
      prefix: (widget.photoUrlOf == null)
          ? null
          : Padding(
        padding: const EdgeInsets.only(left: 8, right: 4),
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
      suffix: widget.enabled
          ? IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _clearSelection,
        tooltip: 'Limpar',
      )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}
