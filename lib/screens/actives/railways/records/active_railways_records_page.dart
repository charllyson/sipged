import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_event.dart';

import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_state.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';
import 'package:siged/_blocs/actives/railway/active_railway_data.dart';

import 'active_railways_form.dart';
import 'active_railways_records_table_section.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ActiveRailwaysRecordsPage extends StatefulWidget {
  const ActiveRailwaysRecordsPage({super.key});

  @override
  State<ActiveRailwaysRecordsPage> createState() => _ActiveRailwaysRecordsPageState();
}

class _ActiveRailwaysRecordsPageState extends State<ActiveRailwaysRecordsPage> {
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
      buildWhen: (a, b) => a.current != b.current || a.isLoadingUsers != b.isLoadingUsers,
      builder: (context, userState) {
        final currentUser = userState.current;
        if (currentUser == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return BlocBuilder<ActiveRailwaysBloc, ActiveRailwaysState>(
          builder: (context, st) {
            final bloc = context.read<ActiveRailwaysBloc>();

            // dispara warmup 1x se ainda não inicializado
            if (!_firedWarmup && !st.initialized) {
              _firedWarmup = true;
              bloc.add(const ActiveRailwaysWarmupRequested());
            }

            if (!st.initialized || st.loadStatus == ActiveRailwaysLoadStatus.loading) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
              return Scaffold(body: Center(child: Text('Erro: ${st.error ?? '-'}')));
            }

            return Stack(
              children: [
                const BackgroundClean(),
                Column(
                  children: [
                    const UpBar(showPhotoMenu: true),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            const DividerText(title: 'Cadastrar / Atualizar Ferrovia'),
                            const SizedBox(height: 12),

                            // ---------- FORM ----------
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: ActiveRailwaysForm(editing: _editing),
                            ),

                            const DividerText(title: 'Ferrovias cadastradas no sistema'),
                            const SizedBox(height: 12),

                            // ---------- TABELA ----------
                            ActiveRailwaysRecordsTableSection(
                              futureRailways: Future.value(st.all),
                              onTapItem: (item) {
                                setState(() => _editing = item); // carrega no form
                                final rotulo = item.codigo ?? item.nome ?? item.id ?? '';
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
                                bloc.add(ActiveRailwaysDeleteRequested(id));
                                if (_editing?.id == id) {
                                  setState(() => _editing = null);
                                }
                                NotificationCenter.instance.show(
                                  AppNotification(
                                    title: Text('Solicitando exclusão...'),
                                    type: AppNotificationType.warning,
                                    duration: Duration(seconds: 3),
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
                      ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.35)),
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
