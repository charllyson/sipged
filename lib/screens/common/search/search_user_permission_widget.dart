import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/screens/common/search/inline_autocomplete.dart';
import 'package:sipged/screens/common/search/participant_tile.dart';

/// ======================================================================
/// SearchUserPermissionWidget
/// - Seleciona usuários em modo simples ou múltiplo.
/// - Em participantsMode, exibe participantes com papel e permissões.
/// - Permite alternar permissões read/create/edit/delete/approve.
/// - Permite alterar papel e remover participante.
/// - Persiste novo usuário via [onUserAdded].
/// ======================================================================
class SearchUserPermissionWidget extends StatefulWidget {
  const SearchUserPermissionWidget({
    super.key,
    required this.title,
    required this.allUsers,
    this.initialUserIds = const <String>[],
    this.onChanged,
    this.onUserAdded,
    this.enabled = true,
    this.width = 300,
    this.multiple = true,
    this.maxItems,
    this.controller,
    this.participantsMode = false,
    this.labelFor,
    this.getPerms,
    this.getRole,
    this.roleOptions = const <String>[
      'GESTOR_REGIONAL',
      'FISCAL',
      'COLABORADOR',
      'LEITOR',
    ],
    this.onChangeRole,
    this.onSetPerms,
    this.onTogglePerm,
    this.onEditPerms,
    this.onRemove,
  });

  final String title;
  final List<UserData> allUsers;

  /// IDs inicialmente selecionados.
  final List<String> initialUserIds;

  /// Dispara quando a lista local de IDs muda.
  final void Function(List<String> userIds)? onChanged;

  /// Dispara ao selecionar novo usuário.
  ///
  /// Use este callback para persistir no Firestore:
  /// ContractCubit.addParticipant(...)
  final Future<void> Function(String uid, UserData user)? onUserAdded;

  final bool enabled;
  final double width;
  final bool multiple;
  final int? maxItems;
  final TextEditingController? controller;

  /// Liga a UI rica de participantes.
  final bool participantsMode;

  /// Rótulo a mostrar no participante.
  final String Function(String uid)? labelFor;

  /// Permissões atuais do usuário.
  final Map<String, bool> Function(String uid)? getPerms;

  /// Papel atual do usuário.
  final String Function(String uid)? getRole;

  /// Lista de papéis possíveis.
  final List<String> roleOptions;

  /// Altera papel e persiste no backend.
  final Future<void> Function(String uid, String newRole)? onChangeRole;

  /// Define permissões completas.
  final Future<void> Function(String uid, Map<String, bool> newPerms)?
  onSetPerms;

  /// Alterna uma permissão.
  final Future<void> Function(String uid, String permKey, bool value)?
  onTogglePerm;

  /// Editor externo adicional.
  final Future<void> Function(String uid)? onEditPerms;

  /// Remove participante.
  final Future<void> Function(String uid)? onRemove;

  @override
  State<SearchUserPermissionWidget> createState() =>
      _SearchUserPermissionWidgetState();
}

class _SearchUserPermissionWidgetState
    extends State<SearchUserPermissionWidget> {
  late List<String> _selectedIds;

  bool _showInlineSearch = false;
  bool _isAddingUser = false;

  @override
  void initState() {
    super.initState();

    final fromController = _parseControllerIds(widget.controller?.text ?? '');

    _selectedIds = fromController.isNotEmpty
        ? fromController
        : widget.initialUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    _syncController();
  }

  @override
  void didUpdateWidget(covariant SearchUserPermissionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != null) {
      return;
    }

    final oldInitial = oldWidget.initialUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final newInitial = widget.initialUserIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final current = _selectedIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    final initialReallyChanged = oldInitial.length != newInitial.length ||
        !oldInitial.containsAll(newInitial) ||
        !newInitial.containsAll(oldInitial);

    final currentEqualsNew = current.length == newInitial.length &&
        current.containsAll(newInitial) &&
        newInitial.containsAll(current);

    if (initialReallyChanged && !currentEqualsNew) {
      setState(() {
        _selectedIds = newInitial.toList();
      });

      _syncController();
    }
  }

  List<String> _parseControllerIds(String raw) {
    if (raw.trim().isEmpty) return <String>[];

    return raw
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  void _syncController() {
    widget.controller?.text = _selectedIds.join(',');
  }

  void _emitChanged() {
    _syncController();
    widget.onChanged?.call(List<String>.unmodifiable(_selectedIds));
  }

  String _cleanUid(UserData user) {
    return (user.uid ?? '').trim();
  }

  UserData? _findById(String? id) {
    final cleanId = id?.trim();

    if (cleanId == null || cleanId.isEmpty) return null;

    try {
      return widget.allUsers.firstWhere(
            (user) => (user.uid ?? '').trim() == cleanId,
      );
    } catch (_) {
      return UserData(uid: cleanId);
    }
  }

  String _display(UserData user) {
    final name = (user.name ?? '').trim();
    final surname = (user.surname ?? '').trim();
    final email = (user.email ?? '').trim();
    final uid = (user.uid ?? '').trim();

    final fullName = [name, surname]
        .where((value) => value.trim().isNotEmpty)
        .join(' ')
        .trim();

    if (fullName.isNotEmpty && email.isNotEmpty) return '$fullName ($email)';
    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;
    if (uid.isNotEmpty) return uid;

    return 'Usuário';
  }

  bool get _canAddMore {
    if (!widget.enabled) return false;
    if (_isAddingUser) return false;

    final maxItems = widget.maxItems;

    if (maxItems == null) return true;

    return _selectedIds.length < maxItems;
  }

  void _toggleSearch() {
    if (!widget.enabled) return;
    if (!_canAddMore) return;

    setState(() {
      _showInlineSearch = !_showInlineSearch;
    });
  }

  Future<void> _addUser(UserData user) async {
    if (!_canAddMore) return;

    final uid = _cleanUid(user);

    if (uid.isEmpty) return;

    final alreadySelected = _selectedIds.contains(uid);

    if (alreadySelected) {
      if (!widget.multiple) {
        setState(() {
          _selectedIds = <String>[uid];
          _showInlineSearch = false;
        });

        _emitChanged();
      }

      return;
    }

    setState(() {
      _isAddingUser = true;
    });

    try {
      if (widget.onUserAdded != null) {
        await widget.onUserAdded!(uid, user);
      }

      if (!mounted) return;

      setState(() {
        if (widget.multiple) {
          if (!_selectedIds.contains(uid)) {
            _selectedIds.add(uid);
          }

          _showInlineSearch = true;
        } else {
          _selectedIds = <String>[uid];
          _showInlineSearch = false;
        }
      });

      _emitChanged();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar usuário: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingUser = false;
        });
      }
    }
  }

  Future<void> _removeAt(int index) async {
    if (!widget.enabled) return;
    if (index < 0 || index >= _selectedIds.length) return;

    final uid = _selectedIds[index];

    setState(() {
      _selectedIds.removeAt(index);
    });

    _emitChanged();

    try {
      if (widget.participantsMode && widget.onRemove != null) {
        await widget.onRemove!(uid);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (!_selectedIds.contains(uid)) {
          _selectedIds.add(uid);
        }
      });

      _emitChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao remover usuário: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _labelForUid(String uid) {
    final customLabel = widget.labelFor?.call(uid).trim();

    if (customLabel != null && customLabel.isNotEmpty) {
      return customLabel;
    }

    final user = _findById(uid);

    if (user != null) return _display(user);

    return uid;
  }

  Map<String, bool> _permsForUid(String uid) {
    final perms = widget.getPerms?.call(uid);

    if (perms == null) {
      return const <String, bool>{
        'read': true,
        'create': false,
        'edit': false,
        'delete': false,
        'approve': false,
      };
    }

    return Map<String, bool>.from(perms);
  }

  String _roleForUid(String uid) {
    final role = widget.getRole?.call(uid).trim();

    if (role != null && role.isNotEmpty) {
      return role;
    }

    return 'COLABORADOR';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      width: widget.width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              title: widget.title,
              enabled: _canAddMore,
              selectedCount: _selectedIds.length,
              maxItems: widget.maxItems,
              isLoading: _isAddingUser,
              onAdd: _toggleSearch,
            ),
            if (_showInlineSearch && widget.enabled)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                ),
                child: InlineAutocomplete(
                  allUsers: widget.allUsers,
                  popupWidth: math.max(
                    220,
                    math.min(
                      800,
                      widget.width,
                    ),
                  ),
                  onSelected: _addUser,
                  onCancel: () {
                    setState(() {
                      _showInlineSearch = false;
                    });
                  },
                  hintText: 'Busque por nome ou email',
                ),
              ),
            if (_selectedIds.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nenhum usuário adicionado.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 360,
                ),
                child: Scrollbar(
                  thumbVisibility: _selectedIds.length > 4,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _selectedIds.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                    itemBuilder: (context, index) {
                      final uid = _selectedIds[index];

                      if (widget.participantsMode) {
                        final user = _findById(uid);
                        final label = _labelForUid(uid);
                        final role = _roleForUid(uid);
                        final perms = _permsForUid(uid);

                        return ParticipantTile(
                          avatarUrl: user?.urlPhoto,
                          title: label,
                          role: role,
                          perms: perms,
                          roleOptions: widget.roleOptions,
                          enabled: widget.enabled && !_isAddingUser,
                          onChangeRole: widget.onChangeRole == null
                              ? null
                              : (newRole) async {
                            await widget.onChangeRole!(uid, newRole);
                          },
                          onTogglePerm: widget.onTogglePerm == null
                              ? null
                              : (key, value) async {
                            await widget.onTogglePerm!(
                              uid,
                              key,
                              value,
                            );
                          },
                          onEditPerms: widget.onEditPerms == null
                              ? null
                              : () async {
                            await widget.onEditPerms!(uid);
                          },
                          onRemove: widget.enabled && !_isAddingUser
                              ? () {
                            _removeAt(index);
                          }
                              : null,
                          maxWidth: widget.width,
                        );
                      }

                      final user = _findById(uid) ?? UserData(uid: uid);

                      return Material(
                        color: theme.cardColor,
                        child: ListTile(
                          dense: true,
                          minLeadingWidth: 0,
                          contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            4,
                            6,
                            4,
                          ),
                          leading: CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                            (user.urlPhoto?.isNotEmpty ?? false)
                                ? NetworkImage(user.urlPhoto!)
                                : null,
                            child: (user.urlPhoto?.isEmpty ?? true)
                                ? const Icon(
                              Icons.person_rounded,
                              color: Colors.grey,
                              size: 18,
                            )
                                : null,
                          ),
                          title: Text(
                            _display(user),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover usuário',
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.close_rounded,
                              color: cs.error,
                              size: 20,
                            ),
                            onPressed: widget.enabled && !_isAddingUser
                                ? () {
                              _removeAt(index);
                            }
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.enabled,
    required this.selectedCount,
    required this.maxItems,
    required this.isLoading,
    required this.onAdd,
  });

  final String title;
  final bool enabled;
  final int selectedCount;
  final int? maxItems;
  final bool isLoading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counter =
    maxItems == null ? '$selectedCount' : '$selectedCount/$maxItems';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.group_rounded,
            color: Colors.grey.shade700,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B2033),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2033).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              counter,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B2033),
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: 'Adicionar usuário',
              visualDensity: VisualDensity.compact,
              onPressed: enabled ? onAdd : null,
              icon: Icon(
                Icons.add_circle_rounded,
                size: 22,
                color: enabled
                    ? const Color(0xFF1B2033)
                    : Colors.grey.shade400,
              ),
            ),
        ],
      ),
    );
  }
}