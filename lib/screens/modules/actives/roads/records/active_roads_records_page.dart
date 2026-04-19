import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

// User
import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_event.dart';

// Roads
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/screens/modules/actives/roads/records/list_roads_page.dart';

import 'tab_bar_roads_page.dart';

// Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class ActiveRoadsRecordsPage extends StatefulWidget {
  const ActiveRoadsRecordsPage({super.key});

  @override
  State<ActiveRoadsRecordsPage> createState() =>
      _ActiveRoadsRecordsPageState();
}

class _ActiveRoadsRecordsPageState extends State<ActiveRoadsRecordsPage> {
  bool _firedUserWarmup = false;
  bool _firedRoadsWarmup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_firedUserWarmup) {
      _firedUserWarmup = true;
      context.read<UserBloc>().add(
        const UserWarmupRequested(
          listenRealtime: true,
          bindCurrentUser: true,
        ),
      );
    }
  }

  void _openTabBarForRoad(ActiveRoadsData? road) {
    final cubit = context.read<ActiveRoadsCubit>();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: TabBarRoadsPage(editing: road),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveRoadsCubit, ActiveRoadsState>(
      builder: (context, st) {
        final cubit = context.read<ActiveRoadsCubit>();

        // warmup das rodovias (1x)
        if (!_firedRoadsWarmup && !st.initialized) {
          _firedRoadsWarmup = true;
          cubit.warmup();
        }

        // ================== ESTADO CARREGANDO ==================
        if (!st.initialized ||
            st.loadStatus == ActiveRoadsLoadStatus.loading) {
          return const Scaffold(
            appBar: UpBar(),
            body: Stack(
              children: [
                BackgroundChange(),
                Center(child: Text('Carregando rodovias...')),
              ],
            ),
          );
        }

        // ================== ESTADO ERRO ==================
        if (st.loadStatus == ActiveRoadsLoadStatus.failure) {
          if (st.error != null && st.error!.isNotEmpty) {
            NotificationCenter.instance.show(
              AppNotification(
                title: const Text('Falha ao carregar rodovias'),
                subtitle: Text(st.error ?? 'Erro desconhecido'),
                type: AppNotificationType.error,
              ),
            );
          }
          return Scaffold(
            body: Center(child: Text('Erro: ${st.error ?? '-'}')),
          );
        }

        // ================== ESTADO OK ==================
        final roads = st.all;

        void onTapRoad(ActiveRoadsData item) {
          _openTabBarForRoad(item);
          final rotulo = item.acronym ?? item.id ?? '';
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Editando rodovia'),
              subtitle: Text(rotulo),
              type: AppNotificationType.info,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        void onDeleteRoad(String id) {
          cubit.deleteById(id);
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Solicitando exclusão...'),
              type: AppNotificationType.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        }

        void onAddRoad() {
          _openTabBarForRoad(null);
        }

        return Scaffold(
          appBar: UpBar(),
          body: Stack(
            children: [
              const BackgroundChange(),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: ListRoadsPage(
                    roads: roads,
                    onTapItem: onTapRoad,
                    onDelete: onDeleteRoad,
                  ),
                ),
              ),
            ],
          ),

          // Botão flutuante para adicionar rodovia
          floatingActionButton: FloatingActionButton.extended(
            onPressed: onAddRoad,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Adicionar rodovia',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue.shade800,
          ),
        );
      },
    );
  }
}
