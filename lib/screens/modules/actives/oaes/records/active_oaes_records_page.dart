import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/screens/modules/actives/oaes/records/list_oaes_page.dart';
import 'package:sipged/screens/modules/actives/oaes/records/tab_bar_oaes_page.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
      builder: (context, st) {
        final cubit = context.read<ActiveOaesCubit>();

        if (!_firedOaesWarmup && !st.initialized) {
          _firedOaesWarmup = true;
          cubit.warmup();
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
                Center(child: Text('Carregando OAE\'s...')),
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
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Solicitando exclusão...'),
              type: AppNotificationType.warning,
              leadingLabel: const Text('OAEs'),
              duration: const Duration(seconds: 4),
            ),
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
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: onAddOae,
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