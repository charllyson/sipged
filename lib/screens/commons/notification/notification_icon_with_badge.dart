import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sisged/_widgets/registers/register_class.dart';
import '../../../_blocs/system/notification_bloc.dart';
import '../../../_blocs/system/user_bloc.dart';
import 'notification_dialog.dart';

class NotificationIconWithBadge extends StatelessWidget {
  final BehaviorSubject<int> badgeSubject;
  final BehaviorSubject<List<Registro>> notificacoesSubject;
  final NotificationBloc notificationBloc;
  final UserBloc userBloc;
  final User? firebaseUser;
  final Set<String> idsVistos;
  final void Function(Set<String>) onUpdateVistos;

  const NotificationIconWithBadge({
    super.key,
    required this.badgeSubject,
    required this.notificacoesSubject,
    required this.notificationBloc,
    required this.userBloc,
    required this.firebaseUser,
    required this.idsVistos,
    required this.onUpdateVistos,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: badgeSubject.stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Notificações',
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () async {
                final uid = firebaseUser?.uid;
                if (uid == null) return;

                final todos = notificacoesSubject.valueOrNull ?? [];

                await showDialog(
                  context: context,
                  builder: (_) => NotificationDialog(
                    registros: todos,
                    userBloc: userBloc,
                  ),
                );

                await notificationBloc.marcarComoVisto(uid, todos);
                final novos = await notificationBloc.carregarIdsVistos(uid);
                onUpdateVistos(novos);
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
