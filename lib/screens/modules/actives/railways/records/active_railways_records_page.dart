import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_event.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railways_cubit.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_state.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'active_railways_form.dart';
import 'active_railways_records_table_section.dart';

// 🔔 Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class ActiveRailwaysRecordsPage extends StatefulWidget {
  const ActiveRailwaysRecordsPage({super.key});

  @override
  State<ActiveRailwaysRecordsPage> createState() =>
      _ActiveRailwaysRecordsPageState();
}

class _ActiveRailwaysRecordsPageState
    extends State<ActiveRailwaysRecordsPage> {
  bool _firedUserWarmup = false;
  bool _firedWarmup = false;

  ActiveRailwayData? _editing; // registro atualmente em edição

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // garante warmup do UserBloc apenas uma vez
    if (!_firedUserWarmup) {
      _firedUserWarmup = true;
      context.read<UserBloc>().add(const UserWarmupRequested(
        listenRealtime: true,
        bindCurrentUser: true,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      buildWhen: (a, b) =>
      a.current != b.current || a.isLoadingUsers != b.isLoadingUsers,
      builder: (context, userState) {
        final currentUser = userState.current;
        if (currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocBuilder<ActiveRailwaysCubit, ActiveRailwaysState>(
          builder: (context, st) {
            final cubit = context.read<ActiveRailwaysCubit>();

            // dispara warmup 1x se ainda não inicializado
            if (!_firedWarmup && !st.initialized) {
              _firedWarmup = true;
              cubit.warmup();
            }

            if (!st.initialized ||
                st.loadStatus == ActiveRailwaysLoadStatus.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (st.loadStatus == ActiveRailwaysLoadStatus.failure) {
              // 🔔 Notificação de erro de carregamento
              NotificationCenter.instance.show(
                AppNotification(
                  title: const Text('Falha ao carregar ferrovias'),
                  subtitle: Text(st.error ?? 'Erro desconhecido'),
                  type: AppNotificationType.error,
                ),
              );
              return Scaffold(
                body: Center(child: Text('Erro: ${st.error ?? '-'}')),
              );
            }

            return Stack(
              children: [
                const BackgroundChange(),
                Column(
                  children: [
                    const UpBar(showPhotoMenu: true),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SectionTitle(
                              text: 'Cadastrar / Atualizar Ferrovia',
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12.0),
                              child: ActiveRailwaysForm(editing: _editing),
                            ),
                            const SectionTitle(
                              text: 'Ferrovias cadastradas no sistema',
                            ),
                            ActiveRailwaysRecordsTableSection(
                              futureRailways: Future.value(st.all),
                              onTapItem: (item) {
                                setState(() => _editing = item); // carrega no form
                                final rotulo =
                                    item.codigo ?? item.nome ?? item.id ?? '';
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    title: const Text('Editando registro'),
                                    subtitle: Text(rotulo),
                                    type: AppNotificationType.info,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                              onDelete: (id) {
                                cubit.deleteById(id);
                                if (_editing?.id == id) {
                                  setState(() => _editing = null);
                                }
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    title: const Text('Solicitando exclusão...'),
                                    type: AppNotificationType.warning,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const FootBar(),
                  ],
                ),

                if (st.savingOrImporting)
                  Stack(
                    children: [
                      ModalBarrier(
                        dismissible: false,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
