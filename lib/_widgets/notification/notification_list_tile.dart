import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/registers/register_class.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';

import '../upBar/up_bar.dart';

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

    // Seleciona o usuário do cache do UserBloc
    final UserData? user = context.select<UserBloc, UserData?>(
          (b) => createdBy.isEmpty ? null : b.state.byId[createdBy],
    );

    // Se não está em cache e temos um createdBy, dispara o fetch pós-frame
    if (user == null && createdBy.isNotEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<UserBloc>().add(UserFetchByIdRequested(createdBy));
        }
      });
    }

    ImageProvider? avatarImage;
    Widget? avatarChild;

    if ((user?.urlPhoto?.isNotEmpty ?? false)) {
      avatarImage = NetworkImage(user!.urlPhoto!);
      avatarChild = null;
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
  }
}
