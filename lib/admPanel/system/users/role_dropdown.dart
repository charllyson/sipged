import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/permission/permission_data.dart' as perm;
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';

class RoleDropdown extends StatefulWidget {
  const RoleDropdown({
    super.key,
    required this.baseRole,
    required this.onPick,
  });

  final perm.SystemUserRole baseRole;
  final Future<void> Function(perm.SystemUserRole picked) onPick;

  @override
  State<RoleDropdown> createState() => _RoleDropdownState();
}

class _RoleDropdownState extends State<RoleDropdown> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();

    _ctrl = TextEditingController(
      text: perm.SystemRoleCodec.label(widget.baseRole),
    );
  }

  @override
  void didUpdateWidget(covariant RoleDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.baseRole != widget.baseRole) {
      final next = perm.SystemRoleCodec.label(widget.baseRole);

      if (_ctrl.text != next) {
        _ctrl.text = next;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DropDownChange(
      labelText: 'Tipo de usuário',
      items: perm.SystemUserRole.values
          .map((role) => perm.SystemRoleCodec.label(role))
          .toList(),
      controller: _ctrl,
      onChanged: (value) async {
        if (value == null) return;

        final picked = perm.SystemUserRole.values.firstWhere(
              (role) => perm.SystemRoleCodec.label(role) == value,
          orElse: () => widget.baseRole,
        );

        if (picked == widget.baseRole) return;

        await widget.onPick(picked);
      },
    );
  }
}