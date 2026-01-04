import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'package:siged/_widgets/windows/show_window_dialog.dart';

class BadgeTypeButton extends StatelessWidget {
  const BadgeTypeButton({
    super.key,
    required this.hasType,
    required this.type,
    required this.onSelected,
    this.onRemove,
  });

  final bool hasType;
  final bc.ColumnType type;
  final ValueChanged<bc.ColumnType> onSelected;
  final VoidCallback? onRemove;

  String _label(bc.ColumnType t) {
    switch (t) {
      case bc.ColumnType.text: return 'Texto';
      case bc.ColumnType.number: return 'Número';
      case bc.ColumnType.money: return 'Monetário (R\$)';
      case bc.ColumnType.boolean_: return 'Booleano';
      case bc.ColumnType.date: return 'Data (DD/MM/YYYY)';
      case bc.ColumnType.auto: return 'Detectar automaticamente';
    }
  }

  String _badge(bc.ColumnType t) {
    switch (t) {
      case bc.ColumnType.money:    return '\$';
      case bc.ColumnType.date:     return 'D';
      case bc.ColumnType.text:     return 'T';
      case bc.ColumnType.number:   return 'N';
      case bc.ColumnType.boolean_: return 'B';
      case bc.ColumnType.auto:     return '+';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      tooltip: 'Tipo da coluna',
      color: Colors.white,
      onSelected: (a) async {
        if (a.kind == _MenuKind.setType) {
          onSelected(a.type!);
          return;
        }
        if (a.kind == _MenuKind.remove && onRemove != null) {
          final ok = confirmDialog(context, 'Deseja realmente remover esta coluna?');
          if (ok != true) return;
          onRemove!.call();
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: _MenuAction.type(bc.ColumnType.text), child: Text(_label(bc.ColumnType.text))),
        PopupMenuItem(value: _MenuAction.type(bc.ColumnType.number), child: Text(_label(bc.ColumnType.number))),
        PopupMenuItem(value: _MenuAction.type(bc.ColumnType.money), child: Text(_label(bc.ColumnType.money))),
        PopupMenuItem(value: _MenuAction.type(bc.ColumnType.boolean_), child: Text(_label(bc.ColumnType.boolean_))),
        PopupMenuItem(value: _MenuAction.type(bc.ColumnType.date), child: Text(_label(bc.ColumnType.date))),
        const PopupMenuDivider(),
        PopupMenuItem(value: _MenuAction.type(bc.ColumnType.auto), child: Text(_label(bc.ColumnType.auto))),
        if (onRemove != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: const _MenuAction.remove(),
            child: Row(
              children: const [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Remover coluna', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ],
      offset: const Offset(0, 24),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: hasType ? Colors.blueAccent.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          _badge(type),
          style: TextStyle(
            color: hasType ? Colors.white : Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

enum _MenuKind { setType, remove }

class _MenuAction {
  final _MenuKind kind;
  final bc.ColumnType? type;
  const _MenuAction._(this.kind, this.type);
  const _MenuAction.remove() : this._(_MenuKind.remove, null);
  const _MenuAction.type(bc.ColumnType t) : this._(_MenuKind.setType, t);
}
