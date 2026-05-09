import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ======================================================================
/// ParticipantTile
/// - Card compacto de participante.
/// - Mostra avatar, nome, papel ao lado do nome e ações no topo.
/// - Chips de permissões toggláveis.
/// - Em telas pequenas pode ocultar os ícones dos chips.
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
  /// {'read': true, 'create': false, 'edit': true, 'delete': false}
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

    _perms = Map<String, bool>.from(widget.perms);
    _role = widget.role.trim().isEmpty ? 'COLABORADOR' : widget.role.trim();
  }

  @override
  void didUpdateWidget(covariant ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!mapEquals(oldWidget.perms, widget.perms)) {
      _perms = Map<String, bool>.from(widget.perms);
    }

    if (oldWidget.role != widget.role) {
      _role = widget.role.trim().isEmpty ? 'COLABORADOR' : widget.role.trim();
    }
  }

  Future<void> _togglePerm(String key, bool value) async {
    if (!widget.enabled) return;

    final oldValue = _perms[key] == true;

    setState(() {
      _perms[key] = value;
    });

    try {
      await widget.onTogglePerm?.call(key, value);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _perms[key] = oldValue;
      });
    }
  }

  Future<void> _changeRole(String? newRole) async {
    if (!widget.enabled) return;

    final cleanRole = newRole?.trim();

    if (cleanRole == null || cleanRole.isEmpty) return;
    if (cleanRole == _role) return;

    final oldRole = _role;

    setState(() {
      _role = cleanRole;
    });

    try {
      await widget.onChangeRole?.call(cleanRole);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _role = oldRole;
      });
    }
  }

  List<String> get _visiblePermKeys {
    final keys = _permOrder
        .where((key) => widget.perms.containsKey(key) || _perms.containsKey(key))
        .toList();

    if (keys.isEmpty) {
      return const <String>[
        'read',
        'edit',
        'delete',
      ];
    }

    return keys;
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
    );
  }

  Widget _chipPerm(
      String key, {
        required bool compact,
      }) {
    final selected = _perms[key] == true;
    final label = _permLabels[key] ?? key;

    const greenBg = Color(0xFFE8F5E9);
    const greenBor = Color(0xFF81C784);
    const greenTxt = Color(0xFF2E7D32);

    const redBg = Color(0xFFFFEBEE);
    const redBor = Color(0xFFE57373);
    const redTxt = Color(0xFFC62828);

    final showIcon = widget.showPermissionIcons && !compact;

    return FilterChip(
      selected: selected,
      onSelected: widget.enabled ? (value) => _togglePerm(key, value) : null,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              selected ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 14,
              color: selected ? greenTxt : redTxt,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              height: 1,
              fontWeight: FontWeight.w800,
              color: selected ? greenTxt : redTxt,
            ),
          ),
        ],
      ),
      backgroundColor: selected ? greenBg : redBg,
      selectedColor: selected ? greenBg : redBg,
      disabledColor: Colors.grey.shade100,
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
      enabled: widget.enabled && widget.onChangeRole != null,
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
                              maxWidth: compact
                                  ? localWidth - 130
                                  : widget.maxWidth > 260
                                  ? widget.maxWidth - 160
                                  : widget.maxWidth - 120,
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
                        onPressed: widget.enabled ? widget.onEditPerms : null,
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
                        onPressed: widget.enabled ? widget.onRemove : null,
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