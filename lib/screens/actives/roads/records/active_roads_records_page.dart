import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';
import 'package:siged/_widgets/upBar/up_bar.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/user/user_event.dart';

import 'package:siged/_blocs/actives/roads/active_roads_state.dart';
import 'package:siged/_blocs/actives/roads/active_roads_event.dart';
import 'package:siged/_blocs/actives/roads/active_roads_data.dart';

import 'active_roads_form.dart';
import 'active_roads_records_table_section.dart';

class ActiveRoadsRecordsPage extends StatefulWidget {
  const ActiveRoadsRecordsPage({super.key});

  @override
  State<ActiveRoadsRecordsPage> createState() => _ActiveRoadsRecordsPageState();
}

class _ActiveRoadsRecordsPageState extends State<ActiveRoadsRecordsPage> {
  bool _firedUserWarmup = false;
  bool _firedRoadsWarmup = false;

  ActiveRoadsData? _editing; // registro atualmente em edição

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

        return BlocBuilder<ActiveRoadsBloc, ActiveRoadsState>(
          builder: (context, st) {
            final bloc = context.read<ActiveRoadsBloc>();

            // dispara warmup 1x se ainda não inicializado
            if (!_firedRoadsWarmup && !st.initialized) {
              _firedRoadsWarmup = true;
              bloc.add(const ActiveRoadsWarmupRequested());
            }

            if (!st.initialized || st.loadStatus == ActiveRoadsLoadStatus.loading) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (st.loadStatus == ActiveRoadsLoadStatus.failure) {
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
                            const DividerText(title: 'Cadastrar / Atualizar Rodovia'),
                            const SizedBox(height: 12),

                            // ---------- FORM ----------
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: ActiveRoadsForm(editing: _editing),
                            ),

                            const DividerText(title: 'Rodovias cadastradas no sistema'),
                            const SizedBox(height: 12),

                            // ---------- TABELA ----------
                            ActiveRoadsRecordsTableSection(
                              futureRoads: Future.value(st.all),
                              onTapItem: (item) {
                                setState(() => _editing = item); // carrega no form
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Editando ${item.acronym ?? item.id ?? ''}')),
                                );
                              },
                              onDelete: (id) {
                                bloc.add(ActiveRoadsDeleteRequested(id));
                                if (_editing?.id == id) {
                                  setState(() => _editing = null);
                                }
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
