import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/list/search/inline_autocomplete.dart';
import 'package:siged/_widgets/list/search/participant_tile.dart';

/// ======================================================================
/// SearchUserPermissionWidget
/// - Seleciona usuários (simples ou múltiplo)
/// - Exibe participantes com papel + permissões
/// - Permite alternar permissões (read/create/edit/delete/approve)
/// - Opcionalmente, altera papel inline
/// ======================================================================
class SearchUserPermissionWidget extends StatefulWidget {
  final String title;
  final List<UserData> allUsers;

  /// IDs inicialmente selecionados
  final List<String> initialUserIds;

  /// Dispara sempre que a lista de IDs muda (add/remove)
  final void Function(List<String> userIds)? onChanged;

  /// Geral
  final bool enabled;
  final double width; // também dimensiona o popup
  final bool multiple;
  final int? maxItems;
  final TextEditingController? controller;

  // ========= MODO PARTICIPANTES (opcional) =========
  /// Liga a UI rica (papel/permissões). Mantém retrocompatibilidade.
  final bool participantsMode;

  /// Rótulo para mostrar no card (ex.: vindo do UserBloc.state.labelFor)
  final String Function(String uid)? labelFor;

  /// Permissões atuais do usuário no contrato:
  /// Pode conter: {'read':bool, 'create':bool, 'edit':bool, 'delete':bool, 'approve':bool}
  /// (Se vier só read/edit/delete, mostramos apenas essas.)
  final Map<String, bool> Function(String uid)? getPerms;

  /// Papel atual do usuário (ex.: 'COLABORADOR')
  final String Function(String uid)? getRole;

  /// Lista de papéis para o seletor
  final List<String> roleOptions;

  /// Troca de papel (deve persistir no backend)
  final Future<void> Function(String uid, String newRole)? onChangeRole;

  /// Define permissões (map completo) — opcional
  final Future<void> Function(String uid, Map<String, bool> newPerms)? onSetPerms;

  /// Alterna UMA permissão (ex.: "read", "edit", "delete")
  final Future<void> Function(String uid, String permKey, bool value)? onTogglePerm;

  /// Abre editor adicional (se quiser manter)
  final Future<void> Function(String uid)? onEditPerms;

  /// Remover participante (deve persistir no backend)
  final Future<void> Function(String uid)? onRemove;

  const SearchUserPermissionWidget({
    super.key,
    required this.title,
    required this.allUsers,
    this.initialUserIds = const [],
    this.onChanged,
    this.enabled = true,
    this.width = 300,
    this.multiple = true,
    this.maxItems,
    this.controller,

    // participantes
    this.participantsMode = false,
    this.labelFor,
    this.getPerms,
    this.getRole,
    this.roleOptions = const ['GESTOR_REGIONAL', 'FISCAL', 'COLABORADOR', 'LEITOR'],
    this.onChangeRole,
    this.onSetPerms,
    this.onTogglePerm,
    this.onEditPerms,
    this.onRemove,
  });

  @override
  State<SearchUserPermissionWidget> createState() => _SearchUserPermissionWidgetState();
}

class _SearchUserPermissionWidgetState extends State<SearchUserPermissionWidget> {
  late List<String> _selectedIds;
  bool _showInlineSearch = false;

  @override
  void initState() {
    super.initState();
    final fromController = _parseControllerIds(widget.controller?.text ?? '');
    _selectedIds = fromController.isNotEmpty ? fromController : [...widget.initialUserIds];
    _syncController();
  }

  // ---- helpers básicos ----
  List<String> _parseControllerIds(String raw) {
    if (raw.trim().isEmpty) return [];
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  void _syncController() {
    widget.controller?.text = _selectedIds.join(',');
  }

  void _emitChanged() {
    widget.onChanged?.call(List.unmodifiable(_selectedIds));
    _syncController();
  }

  UserData? _findById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return widget.allUsers.firstWhere((u) => u.id == id);
    } catch (_) {
      return UserData(id: id); // fallback
    }
  }

  String _display(UserData u) {
    final hasName = (u.name ?? '').trim().isNotEmpty;
    final hasEmail = (u.email ?? '').trim().isNotEmpty;
    if (hasName && hasEmail) return '${u.name} (${u.email})';
    if (hasName) return u.name!;
    if (hasEmail) return u.email!;
    return u.id ?? 'Usuário';
  }

  // ---- add/remove ----
  void _addUser(UserData user) {
    if (!widget.enabled) return;
    if (widget.maxItems != null && _selectedIds.length >= widget.maxItems!) return;

    setState(() {
      if (widget.multiple) {
        if (!_selectedIds.contains(user.id)) _selectedIds.add(user.id!);
      } else {
        _selectedIds = [user.id!];
      }
      _showInlineSearch = widget.multiple;
    });
    _emitChanged();
  }

  Future<void> _removeAt(int index) async {
    if (!widget.enabled) return;
    if (index < 0 || index >= _selectedIds.length) return;

    final uid = _selectedIds[index];
    setState(() => _selectedIds.removeAt(index));
    _emitChanged();

    if (widget.participantsMode && widget.onRemove != null) {
      await widget.onRemove!(uid);
    }
  }

  // ---- UI ----
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.width,
      child: Card(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1B2039),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: widget.multiple ? 'Adicionar usuário' : 'Selecionar usuário',
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: widget.enabled ? () => setState(() => _showInlineSearch = true) : null,
                  ),
                ],
              ),
            ),

            // Autocomplete inline
            if (_showInlineSearch && widget.enabled)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: InlineAutocomplete(
                  allUsers: widget.allUsers,
                  popupWidth: math.min(800, widget.width - 24),
                  onSelected: (u) => _addUser(u),
                  onCancel: () => setState(() => _showInlineSearch = false),
                  hintText: 'Busque por nome ou email',
                ),
              ),

            // ===== Lista =====
            if (_selectedIds.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Sem usuários. Toque em + e adicione.'),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: Scrollbar(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _selectedIds.length,
                    separatorBuilder: (_, __) => Container(),
                    itemBuilder: (context, i) {
                      final uid = _selectedIds[i];

                      if (widget.participantsMode &&
                          widget.labelFor != null &&
                          widget.getPerms != null) {
                        final label = widget.labelFor!(uid);
                        final perms = widget.getPerms!(uid);
                        final role  = widget.getRole?.call(uid) ?? 'COLABORADOR';
                        final u     = _findById(uid) ?? UserData(id: uid, name: label);

                        return ParticipantTile(
                          avatarUrl: u.urlPhoto,
                          title: label,
                          role: role,
                          perms: perms,
                          roleOptions: widget.roleOptions,
                          onChangeRole: widget.onChangeRole == null ? null : (newRole) async => widget.onChangeRole!(uid, newRole),
                          onTogglePerm: widget.onTogglePerm == null ? null : (key, val) async => widget.onTogglePerm!(uid, key, val),
                          onEditPerms: widget.onEditPerms == null ? null : () async => widget.onEditPerms!(uid),
                          onRemove: widget.enabled ? () => _removeAt(i) : null,
                          maxWidth: widget.width,
                        );

                      }

                      // --- MODO SIMPLES (sem perms/role) ---
                      final u = _findById(uid) ?? UserData(id: uid);
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: (u.urlPhoto?.isNotEmpty ?? false)
                                ? NetworkImage(u.urlPhoto!)
                                : null,
                            child: (u.urlPhoto?.isEmpty ?? true)
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(_display(u), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            tooltip: 'Remover',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: widget.enabled ? () => _removeAt(i) : null,
                          ),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (widget.maxItems != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_selectedIds.length}/${widget.maxItems} selecionados',
                    style: TextStyle(
                      fontSize: 12,
                      color: (_selectedIds.length == (widget.maxItems ?? 0))
                          ? cs.error
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
