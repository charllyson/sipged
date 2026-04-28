import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';

import 'package:sipged/_blocs/system/notification/notification_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

import 'package:sipged/screens/modules/actives/airports/records/active_airports_form.dart';
import 'package:sipged/screens/modules/actives/airports/records/active_airports_records_table_section.dart';

class ActiveAirportRecordsPage extends StatefulWidget {
  const ActiveAirportRecordsPage({super.key});

  @override
  State<ActiveAirportRecordsPage> createState() =>
      _ActiveAirportRecordsPageState();
}

class _ActiveAirportRecordsPageState extends State<ActiveAirportRecordsPage> {
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
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    context.read<NotificationCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Aeroportos',
        type: type,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      buildWhen: (a, b) {
        return a.current != b.current ||
            a.isLoadingUsers != b.isLoadingUsers;
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

            if (!st.initialized ||
                st.loadStatus == ActiveOaesLoadStatus.loading) {
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

            if (st.loadStatus == ActiveOaesLoadStatus.failure) {
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

            final labelsRegion = st.regionLabels;

            return Stack(
              children: [
                const BackgroundChange(),
                Column(
                  children: [
                    const UpBar(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SectionTitle(
                              text: 'Cadastrar OAE no sistema',
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: ActiveOaesForm(),
                            ),
                            const SectionTitle(
                              text: 'OAEs cadastradas no sistema',
                            ),
                            ActiveOaesRecordsTableSection(
                              oaes: st.all,
                              onTapItem: (item) {
                                final originalIndex = st.all.indexWhere(
                                      (e) => e.id == item.id,
                                );

                                if (originalIndex != -1) {
                                  cubit.selectByIndex(originalIndex);
                                }

                                final r = (item.region ?? '').toUpperCase();

                                final idxRegion = labelsRegion.indexWhere(
                                      (lab) => lab.toUpperCase() == r,
                                );

                                if (idxRegion != -1) {
                                  // Reservado para uso futuro.
                                }
                              },
                              onDelete: (id) {
                                cubit.delete(id);

                                _showNotification(
                                  title: 'Solicitando exclusão...',
                                  subtitle: 'Registro enviado para exclusão.',
                                  type: NotificationType.warning,
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
            );
          },
        );
      },
    );
  }
}