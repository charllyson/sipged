import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

class AutocompleteUserClass extends StatefulWidget {
  final String? label;
  /// Mostra NOME/EMAIL; o ID fica guardado internamente.
  final TextEditingController controller;
  final List<UserData> allUsers;
  final String? hint;
  final bool enabled;
  final String? Function(String? value)? validator;
  /// ID salvo no doc; quando presente exibimos nome/foto.
  final String? initialUserId;
  /// Devolve o ID selecionado (ou '' ao limpar)
  final void Function(String userId)? onChanged;

  const AutocompleteUserClass({
    super.key,
    required this.controller,
    required this.allUsers,
    required this.enabled,
    this.label,
    this.hint,
    this.validator,
    this.initialUserId,
    this.onChanged,
  });

  @override
  State<AutocompleteUserClass> createState() => _AutocompleteUserClassState();
}

class _AutocompleteUserClassState extends State<AutocompleteUserClass> {
  String? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _hydrateFromProps();
  }

  @override
  void didUpdateWidget(covariant AutocompleteUserClass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUserId != widget.initialUserId ||
        oldWidget.allUsers != widget.allUsers) {
      _hydrateFromProps();
    }
  }

  void _hydrateFromProps() {
    _selectedUserId = (widget.initialUserId?.isNotEmpty ?? false)
        ? widget.initialUserId
        : _guessIdFromText(widget.controller.text);

    if (_selectedUserId != null && _selectedUserId!.isNotEmpty) {
      final u = _findUser(_selectedUserId!);
      if (u != null) {
        widget.controller.text = u.name ?? u.email ?? '';
      } else {
        if (widget.controller.text.isEmpty ||
            widget.controller.text == _selectedUserId) {
          widget.controller.text = '';
        }
      }
    } else {
      widget.controller.text = '';
    }
    setState(() {});
  }

  UserData? _findUser(String id) {
    try {
      return widget.allUsers.firstWhere((u) => u.id == id);
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

  void _selectUser(UserData user) {
    _selectedUserId = user.id;
    widget.controller.text = user.name ?? user.email ?? (user.id ?? '');
    setState(() {});
    widget.onChanged?.call(user.id ?? '');
  }

  void _clearSelection() {
    _selectedUserId = null;
    widget.controller.clear();
    setState(() {});
    widget.onChanged?.call('');
  }

  /// Validação baseada no **ID** selecionado.
  String? _validateById(String? _) {
    if (widget.validator == null) return null;
    // passa uma string qualquer quando há ID, para considerar válido
    return widget.validator!(_selectedUserId?.isNotEmpty == true ? 'ok' : null);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedUserId != null ? _findUser(_selectedUserId!) : null;

    final width = responsiveInputWidth(
      context: context,
      itemsPerLine: 3,
      reservedWidth: 98.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
    );

    // ——— Modo BUSCA (sem seleção): usa o mesmo TextField
    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      return Tooltip(
        message: 'Busque por nome ou email',
        child: Autocomplete<UserData>(
          optionsBuilder: (TextEditingValue tev) {
            if (tev.text.isEmpty) return const Iterable<UserData>.empty();
            final input = tev.text.toLowerCase();
            return widget.allUsers.where((u) {
              final name = (u.name ?? '').toLowerCase();
              final email = (u.email ?? '').toLowerCase();
              return name.contains(input) || email.contains(input);
            });
          },
          displayStringForOption: (u) => u.name ?? u.email ?? '',
          fieldViewBuilder: (context, textCtrl, focusNode, _) {
            return CustomTextField(
              validator: _validateById,         // valida por ID
              enabled: widget.enabled,
              controller: textCtrl,
              focusNode: focusNode,
              labelText: widget.label,
              hintText: widget.hint,
              width: width,
              readOnly: !widget.enabled,        // mantém aparência idêntica
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                child: SizedBox(
                  width: width,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, i) {
                      final u = options.elementAt(i);
                      return ListTile(
                        tileColor: Colors.white,
                        onTap: () => onSelected(u),
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: (u.urlPhoto?.isNotEmpty ?? false)
                              ? NetworkImage(u.urlPhoto!)
                              : null,
                          child: (u.urlPhoto?.isEmpty ?? true)
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: Text(u.name ?? ''),
                        subtitle: Text(u.email ?? ''),
                      );
                    },
                  ),
                ),
              ),
            );
          },
          onSelected: (u) => _selectUser(u),
        ),
      );
    }

    // ——— Modo SELECIONADO: usa o mesmo TextField com prefix/suffix
    return CustomTextField(
      validator: _validateById,          // valida por ID
      enabled: widget.enabled,           // mesma paleta/borda/altura
      controller: widget.controller,     // mostra nome/email
      labelText: widget.label,
      width: width,
      readOnly: true,                    // travado, mas com o mesmo look
      prefix: Padding(
        padding: const EdgeInsets.only(left: 8, right: 4),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white,
          backgroundImage: (selected?.urlPhoto?.isNotEmpty ?? false)
              ? NetworkImage(selected!.urlPhoto!)
              : null,
          child: (selected?.urlPhoto?.isEmpty ?? true)
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
      // mantém o espaçamento e o estilo do teu CustomTextField
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}
