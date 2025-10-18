import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/permitions/page_permission.dart' as pp;

// ---------- UI de chips para as 5 flags ----------
class PermsChipsRow extends StatefulWidget {
  const PermsChipsRow({super.key,
    required this.module,
    required this.current,
    required this.onChanged,
  });

  final String module;
  final pp.Perms current;
  final ValueChanged<pp.Perms> onChanged;

  @override
  State<PermsChipsRow> createState() => _PermsChipsRowState();
}

class _PermsChipsRowState extends State<PermsChipsRow> {
  late pp.Perms _perms;

  @override
  void initState() {
    super.initState();
    _perms = widget.current;
  }

  void _toggle(String key, bool value) {
    setState(() {
      switch (key) {
        case 'read':    _perms = _perms.copyWith(read: value); break;
        case 'create':  _perms = _perms.copyWith(create: value); break;
        case 'edit':    _perms = _perms.copyWith(edit: value); break;
        case 'delete':  _perms = _perms.copyWith(delete: value); break;
        case 'approve': _perms = _perms.copyWith(approve: value); break;
      }
    });
    widget.onChanged(_perms);
  }

  @override
  Widget build(BuildContext context) {
    final chips = <_PermChipSpec>[
      _PermChipSpec('read',    'ler',     _perms.read),
      _PermChipSpec('create',  'criar',   _perms.create),
      _PermChipSpec('edit',    'editar',  _perms.edit),
      _PermChipSpec('delete',  'excluir', _perms.delete),
      _PermChipSpec('approve', 'aprovar', _perms.approve),
    ];

    return Row(
      children: chips.map((c) {
        final has = c.value;
        return Padding(
          padding: const EdgeInsets.all(6.0),
          child: FilterChip(
            label: Text(c.label),
            labelStyle: TextStyle(color: has ? Colors.white : Colors.black54),
            backgroundColor: has ? Colors.green : Colors.grey.shade100,
            selectedColor: Colors.green,
            checkmarkColor: Colors.white,
            selected: has,
            onSelected: (value) => _toggle(c.key, value),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(color: has ? Colors.green.shade700 : Colors.grey),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PermChipSpec {
  final String key;
  final String label;
  final bool value;
  const _PermChipSpec(this.key, this.label, this.value);
}
