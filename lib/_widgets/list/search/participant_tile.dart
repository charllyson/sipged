import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ======================================================================
/// ParticipantTile
/// - Card compacto de participante.
/// - Mostra avatar, nome, papel ao lado do nome e ações no topo.
/// - Chips de permissões toggláveis.
/// - Em telas pequenas pode ocultar os ícones dos chips.
/// - Mantém todas as permissões documentais visíveis:
///   read/create/edit/delete/approve.
/// ======================================================================
class ParticipantTile extends StatefulWidget {
  const ParticipantTile({
    super.key,
    required this.title,
    required this.role,
    required this.perms,
    required this.roleOptions,
    this.avatarUrl,
    this.enabled = true,
    this.showPermissionIcons = true,
    this.onChangeRole,
    this.onTogglePerm,
    this.onEditPerms,
    this.onRemove,
    this.maxWidth = 320,
  });

  final String? avatarUrl;
  final String title;
  final String role;

  /// Exemplo:
  /// {'read': true, 'create': false, 'edit': true, 'delete': false, 'approve': false}
  final Map<String, bool> perms;

  final List<String> roleOptions;
  final bool enabled;

  /// Quando false, remove o ícone check/cancel dos chips.
  final bool showPermissionIcons;

  final Future<void> Function(String newRole)? onChangeRole;
  final Future<void> Function(String key, bool value)? onTogglePerm;
  final Future<void> Function()? onEditPerms;
  final VoidCallback? onRemove;

  final double maxWidth;

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  late Map<String, bool> _perms;
  late String _role;

  String? _savingPermKey;
  bool _savingRole = false;

  static const List<String> _permOrder = <String>[
    'read',
    'create',
    'edit',
    'delete',
    'approve',
  ];

  static const Map<String, String> _permLabels = <String, String>{
    'read': 'ler',
    'create': 'criar',
    'edit': 'editar',
    'delete': 'excluir',
    'approve': 'aprovar',
  };

  @override
  void initState() {
    super.initState();

    _perms = _normalizePerms(widget.perms);
    _role = _normalizeRole(widget.role);
  }

  @override
  void didUpdateWidget(covariant ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!mapEquals(oldWidget.perms, widget.perms)) {
      _perms = _normalizePerms(widget.perms);
    }

    if (oldWidget.role != widget.role) {
      _role = _normalizeRole(widget.role);
    }
  }

  Map<String, bool> _normalizePerms(Map<String, bool> raw) {
    final normalized = <String, bool>{
      'read': false,
      'create': false,
      'edit': false,
      'delete': false,
      'approve': false,
    };

    for (final entry in raw.entries) {
      final key = entry.key.trim().toLowerCase();

      if (key.isEmpty) continue;

      if (key == 'write') {
        normalized['create'] = entry.value;
        continue;
      }

      if (key == 'update') {
        normalized['edit'] = entry.value;
        continue;
      }

      if (key == 'remove') {
        normalized['delete'] = entry.value;
        continue;
      }

      if (key == 'approval' || key == 'approved') {
        normalized['approve'] = entry.value;
        continue;
      }

      normalized[key] = entry.value;
    }

    return normalized;
  }

  String _normalizeRole(String? role) {
    final clean = role?.trim();

    if (clean == null || clean.isEmpty) {
      return 'COLABORADOR';
    }

    return clean;
  }

  Future<void> _togglePerm(String key, bool value) async {
    if (!widget.enabled) return;
    if (_savingPermKey != null) return;

    final cleanKey = key.trim().toLowerCase();

    if (cleanKey.isEmpty) return;

    final oldValue = _perms[cleanKey] == true;

    setState(() {
      _savingPermKey = cleanKey;
      _perms[cleanKey] = value;
    });

    try {
      await widget.onTogglePerm?.call(cleanKey, value);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _perms[cleanKey] = oldValue;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _savingPermKey = null;
      });
    }
  }

  Future<void> _changeRole(String? newRole) async {
    if (!widget.enabled) return;
    if (_savingRole) return;

    final cleanRole = newRole?.trim();

    if (cleanRole == null || cleanRole.isEmpty) return;
    if (cleanRole == _role) return;

    final oldRole = _role;

    setState(() {
      _savingRole = true;
      _role = cleanRole;
    });

    try {
      await widget.onChangeRole?.call(cleanRole);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _role = oldRole;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _savingRole = false;
      });
    }
  }

  List<String> get _visiblePermKeys {
    return _permOrder;
  }

  String _roleLabel(String role) {
    final clean = role.trim().toUpperCase();

    switch (clean) {
      case 'ADMIN':
      case 'ADMINISTRADOR':
        return 'Administrador';
      case 'DEV':
      case 'DESENVOLVEDOR':
        return 'Desenvolvedor';
      case 'GESTOR':
      case 'GESTOR_REGIONAL':
        return 'Gestor';
      case 'FISCAL':
        return 'Fiscal';
      case 'COLABORADOR':
        return 'Colaborador';
      case 'LEITOR':
        return 'Leitor';
      default:
        return clean
            .replaceAll('_', ' ')
            .toLowerCase()
            .split(' ')
            .where((part) => part.trim().isNotEmpty)
            .map((part) {
          return '${part[0].toUpperCase()}${part.substring(1)}';
        }).join(' ');
    }
  }

  Color _roleColor(String role) {
    final clean = role.trim().toUpperCase();

    if (clean.contains('ADMIN')) return const Color(0xFF7C2D12);
    if (clean.contains('DEV')) return const Color(0xFF1E3A8A);
    if (clean.contains('GESTOR')) return const Color(0xFF065F46);
    if (clean.contains('FISCAL')) return const Color(0xFF854D0E);
    if (clean.contains('COLABORADOR')) return const Color(0xFF374151);
    if (clean.contains('LEITOR')) return const Color(0xFF475569);

    return const Color(0xFF374151);
  }

  Widget _roleBadge() {
    final color = _roleColor(_role);

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 160,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _roleLabel(_role),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (_savingRole) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.4,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chipPerm(
      String key, {
        required bool compact,
      }) {
    final selected = _perms[key] == true;
    final label = _permLabels[key] ?? key;
    final saving = _savingPermKey == key;

    const greenBg = Color(0xFFE8F5E9);
    const greenBor = Color(0xFF81C784);
    const greenTxt = Color(0xFF2E7D32);

    const redBg = Color(0xFFFFEBEE);
    const redBor = Color(0xFFE57373);
    const redTxt = Color(0xFFC62828);

    final textColor = selected ? greenTxt : redTxt;
    final showIcon = widget.showPermissionIcons && !compact;

    return FilterChip(
      selected: selected,
      onSelected: widget.enabled && !saving && _savingPermKey == null
          ? (value) => _togglePerm(key, value)
          : null,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (saving) ...[
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: textColor,
              ),
            ),
            const SizedBox(width: 5),
          ] else if (showIcon) ...[
            Icon(
              selected ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              height: 1,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
      backgroundColor: selected ? greenBg : redBg,
      selectedColor: selected ? greenBg : redBg,
      disabledColor: selected ? greenBg.withValues(alpha: 0.72) : redBg.withValues(alpha: 0.72),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: selected ? greenBor : redBor,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(
        horizontal: -3,
        vertical: -3,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 5,
      ),
    );
  }

  Widget _roleSelector() {
    final options = widget.roleOptions
        .map((role) => role.trim())
        .where((role) => role.isNotEmpty)
        .toSet()
        .toList();

    if (options.isEmpty) {
      return _roleBadge();
    }

    if (!options.contains(_role)) {
      options.add(_role);
    }

    return PopupMenuButton<String>(
      tooltip: 'Alterar papel',
      enabled: widget.enabled && widget.onChangeRole != null && !_savingRole,
      onSelected: _changeRole,
      itemBuilder: (context) {
        return options.map((role) {
          return PopupMenuItem<String>(
            value: role,
            child: Row(
              children: [
                if (role == _role)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _roleLabel(role),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false);
      },
      child: _roleBadge(),
    );
  }

  Widget _avatar() {
    final hasAvatar = widget.avatarUrl?.trim().isNotEmpty ?? false;

    return CircleAvatar(
      radius: 17,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: hasAvatar ? NetworkImage(widget.avatarUrl!.trim()) : null,
      child: hasAvatar
          ? null
          : const Icon(
        Icons.person_rounded,
        color: Colors.grey,
        size: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePerms = _visiblePermKeys;

    return LayoutBuilder(
      builder: (context, constraints) {
        final localWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.maxWidth;

        final compact = localWidth < 420 || widget.maxWidth < 420;

        final titleMaxWidth = compact
            ? mathMax(localWidth - 130, 90)
            : widget.maxWidth > 260
            ? mathMax(widget.maxWidth - 160, 120)
            : mathMax(widget.maxWidth - 120, 90);

        return Material(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 8 : 10,
              8,
              compact ? 4 : 6,
              9,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _avatar(),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: titleMaxWidth,
                            ),
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _roleSelector(),
                        ],
                      ),
                    ),
                    if (widget.onEditPerms != null)
                      IconButton(
                        tooltip: 'Editar permissões',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 19,
                          color: Color(0xFF374151),
                        ),
                        onPressed: widget.enabled && _savingPermKey == null
                            ? widget.onEditPerms
                            : null,
                      ),
                    if (widget.onRemove != null)
                      IconButton(
                        tooltip: 'Remover usuário',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Color(0xFFDC2626),
                        ),
                        onPressed: widget.enabled &&
                            _savingPermKey == null &&
                            !_savingRole
                            ? widget.onRemove
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: compact ? 5 : 7,
                  runSpacing: compact ? 5 : 7,
                  children: visiblePerms.map((key) {
                    return _chipPerm(
                      key,
                      compact: compact,
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

double mathMax(double a, double b) {
  return a > b ? a : b;
}