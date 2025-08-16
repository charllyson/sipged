import 'package:sisged/screens/commons/upBar/up_bar.dart';

import '../../../_blocs/system/user_bloc.dart';
import '../../../_widgets/registers/register_class.dart';
import 'package:flutter/material.dart';

import '../../../_datas/system/user_data.dart';
import '../../../_widgets/formats/format_field.dart';

class NotificationListTile extends StatelessWidget {
  final Registro registro;
  final UserBloc userBloc;

  const NotificationListTile({
    super.key,
    required this.registro,
    required this.userBloc,
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

    return FutureBuilder<UserData?>(
      future: userBloc.getUserData(uid: registro.original?.createdBy ?? ''),
      builder: (context, snapshotUser) {
        final user = snapshotUser.data;

        return ListTile(
          dense: true,
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: (user?.urlPhoto?.isNotEmpty ?? false)
                    ? NetworkImage(user!.urlPhoto!)
                    : null,
                child: (user?.urlPhoto?.isEmpty ?? true)
                    ? Text(user?.name?[0] ?? '?')
                    : null,
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
  }
}
