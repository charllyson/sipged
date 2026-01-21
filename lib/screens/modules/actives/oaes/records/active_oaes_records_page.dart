import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/buttons/back_circle_button.dart';
import 'package:siged/screens/modules/actives/oaes/records/list_oaes_page.dart';
import 'package:siged/screens/modules/actives/oaes/records/tab_bar_oaes_page.dart';

// BLoC de usuário
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';

// Cubit de OAEs
import 'package:siged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:siged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:siged/_blocs/modules/actives/oaes/active_oaes_data.dart';

import 'package:siged/_widgets/menu/upBar/up_bar.dart';

// notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

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
      context.read<UserBloc>().add(
        const UserWarmupRequested(
          listenRealtime: true,
          bindCurrentUser: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
      builder: (context, st) {
        final cubit = context.read<ActiveOaesCubit>();

        // warmup das rodovias (1x)
        if (!_firedOaesWarmup && !st.initialized) {
          _firedOaesWarmup = true;
          cubit.warmup();
        }

        if (!st.initialized ||
            st.loadStatus == ActiveOaesLoadStatus.loading) {
          return const Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: UpBar(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: BackCircleButton(),
                ),
                showPhotoMenu: true,
              ),
            ),
            body: Stack(
              children: [
                BackgroundClean(),
                Center(
                    child: Text('Carregando OAE\'s...')),
              ],
            ),
          );
        }
        final oaes = st.all;

        void _onTapOae(ActiveOaesData item) {
          final idx = st.all.indexWhere((e) => e.id == item.id);
          if (idx != -1) {
            cubit.selectByIndex(idx);
          } else {
            // fallback: joga o item direto para o form
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

        void _onDeleteOae(String id) {
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

        // 🔹 Novo: ação do botão flutuante "Adicionar OAE"
        void _onAddOae() {
          // limpa seleção e deixa o form em branco
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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: UpBar(
              leading: const Padding(
                padding: EdgeInsets.only(left: 12.0),
                child: BackCircleButton(),
              ),
            ),
          ),
          body: Stack(
            children: [
              const BackgroundClean(),
              SingleChildScrollView(
                child: ListOaesPage(
                  oaes: oaes,
                  onTapItem: _onTapOae,
                  onDelete: _onDeleteOae,
                ),
              ),
            ],
          ),

          // 🔹 Botão flutuante no canto inferior direito
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _onAddOae,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Adicionar OAE', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.blue.shade800,
          ),
        );
      },
    );
  }
}
