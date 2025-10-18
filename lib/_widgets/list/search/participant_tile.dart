import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// ======================================================================
/// Item de participante com chips de permissão toggláveis
/// ======================================================================
class ParticipantTile extends StatefulWidget {
  final String? avatarUrl;
  final String title;
  final String role;
  final Map<String, bool> perms;           // {'read':..., 'edit':..., 'delete':...}
  final List<String> roleOptions;
  final Future<void> Function(String newRole)? onChangeRole;
  final Future<void> Function(String key, bool value)? onTogglePerm;
  final Future<void> Function()? onEditPerms;
  final VoidCallback? onRemove;
  final double maxWidth;

  const ParticipantTile({super.key,
    required this.title,
    required this.role,
    required this.perms,
    required this.roleOptions,
    this.avatarUrl,
    this.onChangeRole,
    this.onTogglePerm,
    this.onEditPerms,
    this.onRemove,
    this.maxWidth = 320,
  });

  @override
  State<ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<ParticipantTile> {
  late Map<String, bool> _perms;

  // ordem + rótulos como no print
  static const _permOrder = ['read', 'create', 'edit', 'delete', 'approve'];
  static const _permLabels = {
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
  }

  Future<void> _togglePerm(String key, bool value) async {
    setState(() => _perms[key] = value);
    try {
      if (widget.onTogglePerm != null) {
        await widget.onTogglePerm!(key, value);
      }
    } catch (_) {
      // se falhar, volta ao estado anterior
      if (mounted) setState(() => _perms[key] = !(value));
    }
  }

  Widget _chipPerm(String key) {
    final selected = _perms[key] == true;
    final label = _permLabels[key]!;
    // cores no estilo do print
    final greenBg  = const Color(0xFFE8F5E9);
    final greenBor = const Color(0xFF81C784);
    final greenTxt = const Color(0xFF2E7D32);

    final redBg    = const Color(0xFFFFEBEE);
    final redBor   = const Color(0xFFE57373);
    final redTxt   = const Color(0xFFC62828);

    return FilterChip(
      selected: selected,
      onSelected: (v) => _togglePerm(key, v),
      showCheckmark: false, // << desliga o checkmark padrão do FilterChip
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(selected ? Icons.check_circle : Icons.cancel,
              size: 16, color: selected ? greenTxt : redTxt),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? greenTxt : redTxt,
            ),
          ),
        ],
      ),
      backgroundColor: selected ? greenBg : redBg,
      selectedColor: selected ? greenBg : redBg,
      // checkmarkColor: ...  // pode remover, já que o check interno está desligado
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: selected ? greenBor : redBor),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );

  }

  @override
  void didUpdateWidget(covariant ParticipantTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // mantém em sincronia ao atualizar lista
    if (!mapEquals(oldWidget.perms, widget.perms)) {
      _perms = Map<String, bool>.from(widget.perms);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (widget.onEditPerms != null)
        IconButton(
          tooltip: 'Definir papel',
          icon: const Icon(Icons.badge),
          onPressed: widget.onEditPerms,
        ),
      if (widget.onRemove != null)
        IconButton(
          tooltip: 'Remover',
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: widget.onRemove,
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo: avatar + nome
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: (widget.avatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(widget.avatarUrl!)
                      : null,
                  child: (widget.avatarUrl?.isEmpty ?? true)
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Chips de permissão — MESMO visual do print
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _permOrder.map(_chipPerm).toList(),
            ),

            const Divider(height: 18),

            // Papel + ações
            Row(
              children: [
                Chip(
                  backgroundColor: Colors.grey.shade100,
                  label: Text(
                    widget.role,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                ),
                const Spacer(),
                ...actions,
              ],
            ),
          ],
        ),
      ),
    );
  }
}