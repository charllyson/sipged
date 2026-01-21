import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Widgets genéricos
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';

// Dados do processo / contrato
import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

// Cubit novo de revisões
import 'package:siged/_blocs/modules/contracts/measurement/revision/revision_measurement_cubit.dart';
import 'package:siged/_blocs/modules/contracts/measurement/revision/revision_measurement_state.dart';
import 'package:siged/_blocs/modules/contracts/measurement/revision/revision_measurement_data.dart';

// Seções da página
import 'revision_measurement_form_section.dart';
import 'revision_measurement_graph_section.dart';
import 'revision_measurement_table_section.dart';

class RevisionMeasurement extends StatelessWidget {
  const RevisionMeasurement({super.key, required this.contractData});
  final ProcessData contractData;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
      RevisionMeasurementCubit()..loadByContract(contractData.id ?? ''),
      child: _RevisionMeasurementView(contractData: contractData),
    );
  }
}

class _RevisionMeasurementView extends StatefulWidget {
  const _RevisionMeasurementView({required this.contractData});
  final ProcessData contractData;

  @override
  State<_RevisionMeasurementView> createState() =>
      _RevisionMeasurementViewState();
}

class _RevisionMeasurementViewState extends State<_RevisionMeasurementView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _orderCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _valueCtrl = TextEditingController();

  bool _isSaving = false;

  /// `true` quando TODOS os campos obrigatórios estão preenchidos
  bool _formValidated = false;

  bool _isEditable = true;

  RevisionMeasurementData? _selectedRevision;
  String? _currentRevisionId;

  int? _selectedIndexGraph;

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _orderCtrl.addListener(_validateForm);
    _processCtrl.addListener(_validateForm);
    _dateCtrl.addListener(_validateForm);
    _valueCtrl.addListener(_validateForm);
  }

  @override
  void dispose() {
    _orderCtrl
      ..removeListener(_validateForm)
      ..dispose();
    _processCtrl
      ..removeListener(_validateForm)
      ..dispose();
    _dateCtrl
      ..removeListener(_validateForm)
      ..dispose();
    _valueCtrl
      ..removeListener(_validateForm)
      ..dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers de formulário
  // ---------------------------------------------------------------------------

  void _validateForm() {
    final ok = _orderCtrl.text.trim().isNotEmpty &&
        _processCtrl.text.trim().isNotEmpty &&
        _dateCtrl.text.trim().isNotEmpty &&
        _valueCtrl.text.trim().isNotEmpty;

    if (_formValidated != ok) {
      setState(() => _formValidated = ok);
    }
  }

  void _fillForm(RevisionMeasurementData data) {
    _selectedRevision = data;
    _currentRevisionId = data.id;

    _orderCtrl.text = (data.order ?? '').toString();
    _processCtrl.text = data.numberprocess ?? '';
    _dateCtrl.text = data.date != null ? _formatDate(data.date!) : '';
    _valueCtrl.text =
    data.value != null ? data.value!.toStringAsFixed(2) : '';

    // ao carregar de um registro já existente, forçamos recalcular
    _validateForm();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year.toString()}';
  }

  DateTime? _parseDate(String text) {
    if (text.trim().isEmpty) return null;
    try {
      final parts = text.split('/');
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
      return DateTime.tryParse(text);
    } catch (_) {
      return null;
    }
  }

  double? _parseCurrency(String text) {
    if (text.trim().isEmpty) return null;
    final cleaned = text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleaned);
  }

  int _nextAvailableOrder(List<RevisionMeasurementData> list) {
    final existing = list.map((e) => e.order ?? 0).where((e) => e > 0).toSet();
    if (existing.isEmpty) return 1;
    for (int i = 1; i <= existing.length + 1; i++) {
      if (!existing.contains(i)) return i;
    }
    final max = existing.reduce((a, b) => a > b ? a : b);
    return max + 1;
  }

  void _clearForm() {
    _selectedRevision = null;
    _currentRevisionId = null;
    _selectedIndexGraph = null;

    _orderCtrl.clear();
    _processCtrl.clear();
    _dateCtrl.clear();
    _valueCtrl.clear();

    _formValidated = false;
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------

  Future<void> _handleSave(BuildContext context) async {
    final cubit = context.read<RevisionMeasurementCubit>();
    final state = cubit.state;

    // não tem validators nos campos, então o que manda é `_formValidated`
    if (!_formValidated) return;

    final date = _parseDate(_dateCtrl.text);
    final value = _parseCurrency(_valueCtrl.text) ?? 0.0;
    final parsedOrder = int.tryParse(_orderCtrl.text);
    final order = (parsedOrder == null || parsedOrder <= 0)
        ? _nextAvailableOrder(state.revisions)
        : parsedOrder;

    final base = _selectedRevision ?? RevisionMeasurementData();

    final id = _currentRevisionId ??
        base.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final data = base.copyWith(
      id: id,
      order: order,
      numberprocess:
      _processCtrl.text.trim().isEmpty ? null : _processCtrl.text.trim(),
      date: date,
      value: value,
      contractId: widget.contractData.id,
    );

    final ok = await confirmDialog(
      context,
      'Deseja salvar esta medição de revisão?',
    );

    if (!ok) return;

    if (date == null) {
      NotificationCenter.instance.show(
        AppNotification(
          type: AppNotificationType.error,
          title: const Text('Data da revisão inválida'),
          subtitle: const Text('Use o formato dd/MM/aaaa.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final isNew = _currentRevisionId == null;

    try {
      await cubit.saveOrUpdate(
        contractId: widget.contractData.id ?? '',
        revisionMeasurementId: id,
        data: data,
      );
      _currentRevisionId = id;

      NotificationCenter.instance.show(
        AppNotification(
          type: AppNotificationType.success,
          title: Text(isNew ? 'Revisão criada' : 'Revisão atualizada'),
          subtitle: Text(
            'Revisão da medição ${data.order} salva com sucesso.',
          ),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          type: AppNotificationType.error,
          title: const Text('Erro ao salvar revisão'),
          subtitle: Text('$e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, String id) async {
    final cubit = context.read<RevisionMeasurementCubit>();

    final ok = await confirmDialog(
      context,
      'Deseja realmente apagar esta medição de revisão?',
    );
    if (!ok) return;

    setState(() => _isSaving = true);

    try {
      await cubit.delete(
        contractId: widget.contractData.id ?? '',
        revisionId: id,
      );

      if (_currentRevisionId == id) {
        _clearForm();
      }

      NotificationCenter.instance.show(
        AppNotification(
          type: AppNotificationType.warning,
          title: const Text('Revisão apagada'),
          subtitle: const Text(
            'A revisão de medição foi removida com sucesso.',
          ),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          type: AppNotificationType.error,
          title: const Text('Erro ao apagar revisão'),
          subtitle: Text('$e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: BlocBuilder<RevisionMeasurementCubit,
                  RevisionMeasurementState>(
                builder: (context, state) {
                  final revisions = state.revisions;

                  // se for novo e a ordem estiver vazia, sugere a próxima
                  if (_currentRevisionId == null &&
                      _orderCtrl.text.trim().isEmpty) {
                    final next = _nextAvailableOrder(revisions);
                    _orderCtrl.text = next.toString();
                  }

                  final labels = revisions
                      .map((r) => (r.order ?? '-').toString())
                      .toList();
                  final values =
                  revisions.map((r) => r.value ?? 0.0).toList();

                  final totalMedicoes =
                  context.read<RevisionMeasurementCubit>().sum(revisions);

                  // aqui você pode plugar valor inicial / aditivos se quiser
                  final valorInicialContrato = 0.0;
                  final valorAditivos = 0.0;
                  final valorTotalDisponivel =
                      valorInicialContrato + valorAditivos;
                  final saldo = valorTotalDisponivel - totalMedicoes;

                  if (state.status == RevisionMeasurementStatus.loading &&
                      revisions.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == RevisionMeasurementStatus.failure) {
                    return Center(
                      child: Text(
                        state.error ?? 'Erro ao carregar revisões',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  // opções para dropdown de ordem
                  final usedOrders = revisions
                      .map((r) => r.order)
                      .whereType<int>()
                      .toSet()
                      .toList()
                    ..sort();
                  final nextOrder = _nextAvailableOrder(revisions);

                  final orderOptions = <String>[
                    ...usedOrders.map((o) => o.toString()),
                    if (!usedOrders.contains(nextOrder)) nextOrder.toString(),
                  ];
                  final greyOrderItems =
                  usedOrders.map((o) => o.toString()).toSet();

                  return SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      // por enquanto não há validators; mantemos para futuro
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            text: 'Gráfico das revisões de medição',
                          ),
                          RevisionMeasurementGraphSection(
                            labels: labels,
                            values: values,
                            valorTotal: valorTotalDisponivel,
                            totalMedicoes: totalMedicoes,
                            selectedIndex: _selectedIndexGraph,
                            onSelectIndex: (index) {
                              setState(() {
                                _selectedIndexGraph = index;
                              });
                              if (index >= 0 &&
                                  index < revisions.length) {
                                _fillForm(revisions[index]);
                              }
                            },
                          ),
                          const DividerText(
                            text: 'Cadastrar revisões de medição',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0),
                            child: RevisionMeasurementFormSection(
                              isEditable: _isEditable,
                              formValidated: _formValidated,
                              selectedRevisionMeasurement: _selectedRevision,
                              currentRevisionMeasurementId:
                              _currentRevisionId,
                              contractData: widget.contractData,
                              orderRevisionController: _orderCtrl,
                              processNumberRevisionController: _processCtrl,
                              dateRevisionController: _dateCtrl,
                              valueRevisionController: _valueCtrl,
                              onSave: () => _handleSave(context),
                              onClear: _clearForm,
                              sideItems: const [],
                              selectedSideIndex: null,
                              onAddSideItem: null,
                              onTapSideItem: null,
                              onDeleteSideItem: null,
                              onEditLabelSideItem: null,
                              onUploadSaveToFirestore: null,
                              orderOptions: orderOptions,
                              greyOrderItems: greyOrderItems,
                              onChangedOrder: (value) {
                                _orderCtrl.text = value?.toString() ?? '';
                              },
                            ),
                          ),
                          const SectionTitle(
                            text: 'Revisões cadastradas no sistema',
                          ),
                          RevisionMeasurementTableSection(
                            onTapItem: (rev) {
                              _fillForm(rev);
                            },
                            onDelete: (id) => _handleDelete(context, id),
                            measurementsData: revisions,
                            valorInicial: valorInicialContrato,
                            valorAditivos: valorAditivos,
                            valorTotal: valorTotalDisponivel,
                            saldo: saldo,
                            contractData: widget.contractData,
                            selectedMeasurement: _selectedRevision,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const FootBar(),
          ],
        ),
        if (_isSaving)
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
  }
}
