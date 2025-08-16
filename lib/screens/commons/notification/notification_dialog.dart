import 'package:flutter/material.dart';

import '../../../_blocs/system/user_bloc.dart';
import '../../../_widgets/registers/register_class.dart';
import 'notification_list_tile.dart';

class NotificationDialog extends StatelessWidget {
  final List<Registro> registros;
  final UserBloc userBloc;

  const NotificationDialog({
    super.key,
    required this.registros,
    required this.userBloc,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Todas as Notificações'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: ListView.builder(
          itemCount: registros.length,
          itemBuilder: (context, index) {
            return NotificationListTile(
              registro: registros[index],
              userBloc: userBloc,
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

