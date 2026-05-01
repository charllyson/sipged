import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_cubit.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_data.dart';
import 'package:sipged/_blocs/system/notification/local/notification_type.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'active_railways_form.dart';
import 'active_railways_records_table_section.dart';

class ActiveRailwaysRecordsPage extends StatefulWidget {
  const ActiveRailwaysRecordsPage({super.key});

  @override
  State<ActiveRailwaysRecordsPage> createState() =>
      _ActiveRailwaysRecordsPageState();
}

class _ActiveRailwaysRecordsPageState extends State<ActiveRailwaysRecordsPage> {
  bool _firedUserWarmup = false;
  bool _firedWarmup = false;

  ActiveRailwayData? _editing;
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
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Ferrovias',
        type: type,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      buildWhen: (a, b) {
        return a.current != b.current || a.isLoadingUsers != b.isLoadingUsers;
      },
      builder: (context, userState) {
        final currentUser = userState.current;

        if (currentUser == null) {
          return const Scaffold(
            body: Center(
              child: LoadingTreeDots(size: 110),
            ),
          );
        }

        return BlocBuilder<ActiveRailwaysCubit, ActiveRailwaysState>(
          builder: (context, st) {
            final cubit = context.read<ActiveRailwaysCubit>();

            if (!_firedWarmup && !st.initialized) {
              _firedWarmup = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                cubit.warmup();
              });
            }

            if (!st.initialized ||
                st.loadStatus == ActiveRailwaysLoadStatus.loading) {
              return const Scaffold(
                body: Stack(
                  children: [
                    BackgroundChange(),
                    Center(
                      child: LoadingTreeDots(size: 110),
                    ),
                  ],
                ),
              );
            }

            if (st.loadStatus == ActiveRailwaysLoadStatus.failure) {
              final error = st.error ?? 'Erro desconhecido';

              if (_lastFailureMessage != error) {
                _lastFailureMessage = error;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  _showNotification(
                    title: 'Falha ao carregar ferrovias',
                    subtitle: error,
                    type: NotificationType.error,
                    duration: const Duration(seconds: 6),
                  );
                });
              }

              return Scaffold(
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
                                setState(() => _editing = item);

                                final rotulo =
                                    item.codigo ?? item.nome ?? item.id ?? '';

                                _showNotification(
                                  title: 'Editando registro',
                                  subtitle: rotulo,
                                  type: NotificationType.info,
                                  duration: const Duration(seconds: 3),
                                );
                              },
                              onDelete: (id) {
                                cubit.deleteById(id);

                                if (_editing?.id == id) {
                                  setState(() => _editing = null);
                                }

                                _showNotification(
                                  title: 'Solicitando exclusão...',
                                  subtitle: 'Registro enviado para exclusão.',
                                  type: NotificationType.warning,
                                  duration: const Duration(seconds: 3),
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
                      const Center(
                        child: LoadingTreeDots(size: 120),
                      ),
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