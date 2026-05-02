import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/modules/actives/roads/records/list_roads_page.dart';

import 'tab_bar_roads_page.dart';

class ActiveRoadsRecordsPage extends StatefulWidget {
  const ActiveRoadsRecordsPage({super.key});

  @override
  State<ActiveRoadsRecordsPage> createState() => _ActiveRoadsRecordsPageState();
}

class _ActiveRoadsRecordsPageState extends State<ActiveRoadsRecordsPage> {
  bool _firedUserWarmup = false;
  bool _firedRoadsWarmup = false;
  String? _lastFailureMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_firedUserWarmup) {
      _firedUserWarmup = true;

      context.read<UserCubit>().warmup(
        listenRealtime: true,
        bindCurrentUser: true,
      );
    }
  }

  void _showNotification({
    required String title,
    String? subtitle,
    NotificationStatus type = NotificationStatus.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Rodovias',
        type: type,
        duration: duration,
      ),
    );
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

        if (!_firedRoadsWarmup && !st.initialized) {
          _firedRoadsWarmup = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            cubit.warmup();
          });
        }

        if (!st.initialized || st.loadStatus == ActiveRoadsLoadStatus.loading) {
          return const Scaffold(
            appBar: UpBar(),
            body: Stack(
              children: [
                BackgroundChange(),
                Center(
                  child: LoadingTreeDots(
                    size: 90,
                    message: Text('Carregando rodovias...'),
                  ),
                ),
              ],
            ),
          );
        }

        if (st.loadStatus == ActiveRoadsLoadStatus.failure) {
          final error = st.error ?? 'Erro desconhecido';

          if (_lastFailureMessage != error) {
            _lastFailureMessage = error;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              _showNotification(
                title: 'Falha ao carregar rodovias',
                subtitle: error,
                type: NotificationStatus.error,
                duration: const Duration(seconds: 6),
              );
            });
          }

          return Scaffold(
            appBar: const UpBar(),
            body: Stack(
              children: [
                const BackgroundChange(),
                Center(
                  child: Text('Erro: ${st.error ?? '-'}'),
                ),
              ],
            ),
          );
        }

        _lastFailureMessage = null;

        final roads = st.all;

        void onTapRoad(ActiveRoadsData item) {
          _openTabBarForRoad(item);

          final rotulo = item.acronym ?? item.id ?? '';

          _showNotification(
            title: 'Editando rodovia',
            subtitle: rotulo,
            type: NotificationStatus.info,
            duration: const Duration(seconds: 3),
          );
        }

        void onDeleteRoad(String id) {
          cubit.deleteById(id);

          _showNotification(
            title: 'Solicitando exclusão...',
            subtitle: 'Registro enviado para exclusão.',
            type: NotificationStatus.warning,
            duration: const Duration(seconds: 3),
          );
        }

        void onAddRoad() {
          _openTabBarForRoad(null);
        }

        return Scaffold(
          appBar: const UpBar(),
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
              if (st.savingOrImporting)
                Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    const Center(
                      child: LoadingTreeDots(size: 120),
                    ),
                  ],
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: st.savingOrImporting ? null : onAddRoad,
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