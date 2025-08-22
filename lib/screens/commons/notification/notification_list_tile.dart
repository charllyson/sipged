import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/user_provider.dart';
import 'package:sisged/_datas/system/user_data.dart';

import 'package:sisged/_widgets/registers/register_class.dart';
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/screens/commons/upBar/up_bar.dart';

class NotificationListTile extends StatelessWidget {
  final Registro registro;

  const NotificationListTile({
    super.key,
    required this.registro,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = getTipoAlteracao(
      createdAt: registro.original?.createdAt,
      updatedAt: registro.original?.updatedAt,
    );

    final icon = tipo == 'Atualização'
        ? const Icon(Icons.update, size: 12, color: Colors.orange)
        : const Icon(Icons.create, size: 12, color: Colors.blue);

    final createdBy = registro.original?.createdBy ?? '';

    return Consumer<UserProvider>(
      builder: (context, userProv, _) {
        // Tenta cache primeiro
        Future<UserData?> futureUser;
        if (createdBy.isEmpty) {
          futureUser = Future.value(null);
        } else {
          futureUser = userProv.fetchById(createdBy);
        }

        return FutureBuilder<UserData?>(
          future: futureUser,
          builder: (context, snapshotUser) {
            final user = snapshotUser.data;

            Widget avatarChild;
            ImageProvider? avatarImage;

            if ((user?.urlPhoto?.isNotEmpty ?? false)) {
              avatarImage = NetworkImage(user!.urlPhoto!);
              avatarChild = const SizedBox.shrink();
            } else {
              final initial = (user?.name?.isNotEmpty ?? false)
                  ? user!.name!.characters.first.toUpperCase()
                  : '?';
              avatarChild = Text(initial);
            }

            return ListTile(
              dense: true,
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: avatarImage,
                    child: avatarImage == null ? avatarChild : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: icon,
                    ),
                  ),
                ],
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      registro.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateAndTimeHumanized(registro.data),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              subtitle: Text(
                registro.contractData?.summarySubjectContract ?? 'Sem título',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}
