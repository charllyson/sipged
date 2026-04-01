import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/table/magic/magic_adapter.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

// 🔁 NOVO PADRÃO
import 'package:sipged/_blocs/modules/contracts/budget/budget_cubit.dart';

import 'package:sipged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'package:sipged/_widgets/table/magic/magic_table_changed.dart';

// 🔔 Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

class HiringBudgetPage extends StatefulWidget {
  const HiringBudgetPage({super.key, required this.contractData});
  final ProcessData contractData;

  @override
  State<HiringBudgetPage> createState() => _HiringBudgetPageState();
}

class _HiringBudgetPageState extends State<HiringBudgetPage> {
  bool _saving = false;

  Future<void> _load(
      BudgetCubit cubit,
      bc.MagicTableController ctrl,
      String contractId,
      ) async {
    await cubit.ensureFor(contractId);

    final st = cubit.state;
    final data = st.dataFor(contractId);

    if (data == null || data.isEmpty) {
      ctrl.loadFromSnapshot(
        table: const <List<String>>[<String>[]],
        colTypesAsString: const <String>[],
        widths: const <double>[],
      );
      return;
    }

    MagicAdapter.loadControllerFromDomain(
      controller: ctrl,
      data: data,
    );
  }

  Future<void> _saveNow(
      BudgetCubit cubit,
      bc.MagicTableController c,
      String contractId,
      ) async {
    setState(() => _saving = true);

    try {
      final domain = MagicAdapter.buildDomainFromController(controller: c);

      await cubit.saveDomain(
        contractId: contractId,
        data: domain,
      );

      if (mounted) {
        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('Orçamento'),
            subtitle: const Text('Alterações salvas'),
            type: AppNotificationType.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('Falha ao salvar'),
            subtitle: Text('$e'),
            type: AppNotificationType.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractId = widget.contractData.id!;

    return ChangeNotifierProvider<bc.MagicTableController>(
      create: (_) => bc.MagicTableController(
        cellPadHorizontal:
        const EdgeInsets.symmetric(horizontal: 12).horizontal,
      ),
      builder: (context, _) {
        final ctrl = context.watch<bc.MagicTableController>();

        // ✅ BudgetCubit agora é a fonte
        final cubit = context.read<BudgetCubit>();

        final isLoading = context.select<BudgetCubit, bool>(
              (c) => c.state.loadingFor(contractId),
        );

        final isBusy = isLoading || _saving;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: UpBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: const BackCircleButton(),
              ),
            ),
          ),
          body: Stack(
            children: [
              const Positioned.fill(child: BackgroundChange()),

              Positioned.fill(
                child: MagicTableChanged(
                  selectAllOnEdit: false,
                  controller: ctrl,
                  onInit: (c) => _load(cubit, c, contractId),

                  // 🔒 esconda apenas no BudgetPage:
                  allowAddColumn: false,
                  allowRemoveColumn: false,
                  allowAddRow: false,

                  // auto-save após mudança estrutural (se existir no seu fluxo)
                  onRequestSaveAfterStructureChange: (c) =>
                      _saveNow(cubit, c, contractId),

                  bottomScrollGap: 90,
                  rightScrollGap: 60,

                  floatingActionsBuilder: (ctx, c) => [
                    FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      heroTag: 'pasteExcel',
                      tooltip: 'Colar do Excel (Ctrl+V)',
                      onPressed: isBusy ? null : () => c.pasteFromClipboard(),
                      child: const Icon(Icons.paste),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      heroTag: 'saveBudget',
                      tooltip: 'Salvar orçamento no Firestore',
                      onPressed: isBusy
                          ? null
                          : () async {
                        if (!c.hasData) {
                          NotificationCenter.instance.show(
                            AppNotification(
                              title: const Text('Nada para salvar'),
                              subtitle: const Text(
                                  'Cole dados do Excel antes de salvar.'),
                              type: AppNotificationType.info,
                            ),
                          );
                          return;
                        }
                        await _saveNow(cubit, c, contractId);
                      },
                      child: const Icon(Icons.save),
                    ),
                  ],
                ),
              ),

              // Rodapé fixo
              const Align(
                alignment: Alignment.bottomCenter,
                child: FootBar(),
              ),

              if (isBusy) ...[
                const ModalBarrier(
                    dismissible: false, color: Colors.black38),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            blurRadius: 10,
                            spreadRadius: 1,
                            color: Colors.black26),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _saving
                              ? 'Salvando orçamento...'
                              : 'Carregando orçamento...',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
