import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

// BLoC de usuário
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_event.dart';

// BLoC de OAEs (já injetado no main)
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_state.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'active_airports_form.dart';
import 'active_airports_records_table_section.dart';

class ActiveAirportsRecordsPage extends StatefulWidget {
  const ActiveAirportsRecordsPage({super.key});

  @override
  State<ActiveAirportsRecordsPage> createState() => _ActiveAirportsRecordsPageState();
}

class _ActiveAirportsRecordsPageState extends State<ActiveAirportsRecordsPage> {
// índice original (na lista st.all)
// índice da fatia (0..5)
// índice da barra de região
  bool _firedUserWarmup = false;
  bool _firedOaesWarmup = false;

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

        // Consome o ActiveOaesBloc já injetado no main()
        return BlocBuilder<ActiveOaesBloc, ActiveOaesState>(
          builder: (context, st) {
            final bloc = context.read<ActiveOaesBloc>();

            // Se o main não disparou o warmup, garante aqui 1x
            if (!_firedOaesWarmup && !st.initialized) {
              _firedOaesWarmup = true;
              bloc.add(const ActiveOaesWarmupRequested());
            }

            if (!st.initialized || st.loadStatus == ActiveOaesLoadStatus.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (st.loadStatus == ActiveOaesLoadStatus.failure) {
              return Scaffold(
                body: Center(child: Text('Erro: ${st.error ?? '-'}')),
              );
            }

// labels semânticos (0..5)
// contagem por nota
// cores por nota

            final labelsRegion = st.regionLabels;

            return Stack(
              children: [
                const BackgroundClean(),
                Column(
                  children: [
                    UpBar(
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            const DividerText(title: 'Cadastrar OAE no sistema'),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12.0),
                              child: ActiveAirportsForm(),
                            ),
                            const DividerText(title: 'OAEs cadastradas no sistema'),
                            const SizedBox(height: 12),

                            // ===================== TABELA =====================
                            ActiveAirportsRecordsTableSection(
                              futureOaes: Future.value(st.all),
                              onTapItem: (item) {
                                // espelha seleção no BLoC
                                final originalIndex = st.all.indexWhere((e) => e.id == item.id);
                                if (originalIndex != -1) {
                                  context
                                      .read<ActiveOaesBloc>()
                                      .add(ActiveOaesSelectByIndex(originalIndex));
                                }

                                // espelha no PIE: nota -> índice da fatia (0..5)
                                ((item.score ?? -1).toInt()).clamp(0, 5);

                                // espelha na barra de região
                                final r = (item.region ?? '').toUpperCase();
                                final idxRegion = labelsRegion.indexWhere(
                                      (lab) => lab.toUpperCase() == r,
                                );
                                if (idxRegion != -1) {
                                }
                              },
                              onDelete: (id) {
                                context.read<ActiveOaesBloc>().add(ActiveOaesDeleteRequested(id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Solicitando exclusão...'),
                                    backgroundColor: Colors.red,
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

                if (st.saving)
                  Stack(
                    children: [
                      ModalBarrier(
                        dismissible: false,
                        color: Colors.black.withOpacity(0.4),
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
