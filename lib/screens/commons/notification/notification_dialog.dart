import 'package:flutter/material.dart';

import 'package:sisged/_widgets/registers/register_class.dart';
import 'notification_list_tile.dart';

class NotificationDialog extends StatelessWidget {
  final List<Registro> registros;

  const NotificationDialog({
    super.key,
    required this.registros,
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

