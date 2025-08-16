import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_widgets/registers/register_class.dart';
import 'package:sisged/screens/commons/toast/show_stacked_toast.dart';
import '../popUpMenu/pup_up_menu.dart';
import '../search/search_overlay_manager.dart';
import '../currentUser/user_greeting.dart';

class UpBar extends StatefulWidget implements PreferredSizeWidget {
  final void Function(String)? onSearch;

  const UpBar({super.key, this.onSearch});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  State<UpBar> createState() => _UpBarState();
}

class _UpBarState extends State<UpBar> {
  final UserBloc userBloc = UserBloc();
  final BehaviorSubject<List<Registro>> _notificacoesSubject = BehaviorSubject<List<Registro>>();
  final BehaviorSubject<int> _badgeSubject = BehaviorSubject<int>();
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _searchController = TextEditingController();
  late final SearchOverlayManager _searchOverlayManager;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _searchOverlayManager = SearchOverlayManager(context, _searchController, widget.onSearch);
    //_iniciarStreamNotificacoes();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _notificacoesSubject.close();
    _badgeSubject.close();
    super.dispose();
  }

  /*void _iniciarStreamNotificacoes() {
    _subscription = userBloc.getNotificacoesRecentesStreamAgrupado()
        .debounceTime(const Duration(seconds: 1))
        .listen((registros) async {
      final uid = firebaseUser?.uid;
      if (uid == null) return;

      final novosIdsVistos = await _notificationBloc.carregarIdsVistos(uid);
      final naoVistos = registros
          .where((r) => !novosIdsVistos.contains(_notificationBloc.gerarIdUnico(r)))
          .toList();
      final exibidos = <String>{};

      for (int i = 0; i < naoVistos.length && i < 5; i++) {
        final idUnico = _notificationBloc.gerarIdUnico(naoVistos[i]);
        if (!exibidos.contains(idUnico)) {
          exibidos.add(idUnico);
          showStackedToast(context, naoVistos[i], i);
        }
      }

      if (naoVistos.isNotEmpty) {
        await _notificationBloc.marcarComoVisto(uid, naoVistos);
      }

      _idsVistos = novosIdsVistos..addAll(naoVistos.map(_notificationBloc.gerarIdUnico));

      final totalNaoVistos = registros
          .where((r) => !_idsVistos.contains(_notificationBloc.gerarIdUnico(r)))
          .length;

      _badgeSubject.add(totalNaoVistos);
      _notificacoesSubject.add(registros.take(10).toList());
    });
  }*/

  void showStackedToast(BuildContext context, Registro registro, int index) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => StackedToastNotification(
        registro: registro,
        index: index,
        tipoAlteracao: getTipoAlteracao(
          createdAt: registro.original?.createdAt,
          updatedAt: registro.original?.updatedAt,
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 4)).then((_) => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white, width: 1)),
        gradient: LinearGradient(
          colors: [Color(0xFF1B2031), Color(0xFF1B2039)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Buscar',
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _searchOverlayManager.toggleOverlay,
          ),
          const SizedBox(width: 12),
          /*NotificationIconWithBadge(
            badgeSubject: _badgeSubject,
            notificacoesSubject: _notificacoesSubject,
            notificationBloc: _notificationBloc,
            userBloc: userBloc,
            firebaseUser: firebaseUser,
            idsVistos: _idsVistos,
            onUpdateVistos: (v) => setState(() => _idsVistos = v),
          ),
          const SizedBox(width: 12),*/
          UserGreeting(userBloc: userBloc, firebaseUser: firebaseUser,),
          const PopUpMenu(),
        ],
      ),
    );
  }
}

String getTipoAlteracao({DateTime? createdAt, DateTime? updatedAt}) {
  if (updatedAt != null && createdAt != null && updatedAt.isAfter(createdAt)) {
    return 'Atualização';
  }
  return 'Criação';
}
