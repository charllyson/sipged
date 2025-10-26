import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:siged/_widgets/table/magic/magic_adapter.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/budget/budget_store.dart';
import 'package:siged/_blocs/process/budget/budget_data.dart';

import 'package:siged/_widgets/table/magic/magic_table_controller.dart' as bc;
import 'package:siged/_widgets/table/magic/magic_table_changed.dart';

// 🔔 Notificações
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, required this.contractData});
  final ContractData contractData;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  bool _saving = false;

  Future<void> _load(
      BudgetStore store,
      bc.MagicTableController ctrl,
      String contractId,
      ) async {
    await store.ensureFor(contractId);

    final data = store.dataFor(contractId);
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
      BudgetStore store,
      bc.MagicTableController c,
      String contractId,
      ) async {
    setState(() => _saving = true);
    try {
      final domain = MagicAdapter.buildDomainFromController(controller: c);
      await store.saveDomain(contractId: contractId, data: domain);
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
        cellPadHorizontal: const EdgeInsets.symmetric(horizontal: 12).horizontal,
      ),
      builder: (context, _) {
        final ctrl = context.watch<bc.MagicTableController>();
        final store = context.read<BudgetStore>();

        final isLoading = context.select<BudgetStore, bool>(
              (s) => s.loadingFor(contractId),
        );
        final isBusy = isLoading || _saving;

        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: BackgroundClean()),
              Positioned.fill(
                child: MagicTableChanged(
                  selectAllOnEdit: false,
                  controller: ctrl,
                  onInit: (c) => _load(store, c, contractId),

                  // 🔒 esconda apenas no BudgetPage:
                  allowAddColumn: false,
                  allowRemoveColumn: false,
                  allowAddRow: false,

                  // (se usar auto-save quando estrutura muda)
                  onRequestSaveAfterStructureChange: (c) =>
                      _saveNow(store, c, contractId),

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
                              subtitle: const Text('Cole dados do Excel antes de salvar.'),
                              type: AppNotificationType.info,
                            ),
                          );
                          return;
                        }
                        await _saveNow(store, c, contractId);
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
                const ModalBarrier(dismissible: false, color: Colors.black38),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(blurRadius: 10, spreadRadius: 1, color: Colors.black26),
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
                          _saving ? 'Salvando orçamento...' : 'Carregando orçamento...',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
