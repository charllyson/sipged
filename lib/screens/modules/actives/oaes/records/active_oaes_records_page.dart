import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/modules/actives/oaes/records/list_oaes_page.dart';
import 'package:sipged/screens/modules/actives/oaes/records/tab_bar_oaes_page.dart';

class ActiveOaesRecordsPage extends StatefulWidget {
  const ActiveOaesRecordsPage({super.key});

  @override
  State<ActiveOaesRecordsPage> createState() => _ActiveOaesRecordsPageState();
}

class _ActiveOaesRecordsPageState extends State<ActiveOaesRecordsPage> {
  bool _firedUserWarmup = false;
  bool _firedOaesWarmup = false;

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
        leadingLabel: 'OAEs',
        type: type,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
      builder: (context, st) {
        final cubit = context.read<ActiveOaesCubit>();

        if (!_firedOaesWarmup && !st.initialized) {
          _firedOaesWarmup = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            cubit.warmup();
          });
        }

        if (!st.initialized || st.loadStatus == ActiveOaesLoadStatus.loading) {
          return const Scaffold(
            appBar: UpBar(
              leading: Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: CircleButtonChange(),
              ),
              showPhotoMenu: true,
            ),
            body: Stack(
              children: [
                BackgroundChange(),
                Center(
                  child: LoadingTreeDots(
                    size: 90,
                    message: Text('Carregando OAEs...'),
                  ),
                ),
              ],
            ),
          );
        }

        if (st.loadStatus == ActiveOaesLoadStatus.failure) {
          return Scaffold(
            appBar: const UpBar(
              leading: Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: CircleButtonChange(),
              ),
              showPhotoMenu: true,
            ),
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

        final oaes = st.all;

        void onTapOae(ActiveOaesData item) {
          final idx = st.all.indexWhere((e) => e.id == item.id);

          if (idx != -1) {
            cubit.selectByIndex(idx);
          } else {
            cubit.patchForm(item);
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: const TabBarOaesPage(),
              ),
            ),
          );
        }

        void onDeleteOae(String id) {
          cubit.delete(id);

          _showNotification(
            title: 'Solicitando exclusão...',
            subtitle: 'Registro enviado para exclusão.',
            type: NotificationStatus.warning,
          );
        }

        void onAddOae() {
          cubit.clearSelection();

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: cubit,
                child: const TabBarOaesPage(),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: const UpBar(),
          body: Stack(
            children: [
              const BackgroundChange(),
              SingleChildScrollView(
                child: ListOaesPage(
                  oaes: oaes,
                  onTapItem: onTapOae,
                  onDelete: onDeleteOae,
                ),
              ),
              if (st.saving)
                Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    const Center(
                      child: LoadingTreeDots(size: 120),
                    ),
                  ],
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: st.saving ? null : onAddOae,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Adicionar OAE',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue.shade800,
          ),
        );
      },
    );
  }
}