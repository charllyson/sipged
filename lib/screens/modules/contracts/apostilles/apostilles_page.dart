// lib/screens/modules/contracts/apostilles/apostilles_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_cubit.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_state.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_utils/formats/converters_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'apostilles_form_section.dart';
import 'apostilles_graph_section.dart';
import 'apostilles_table_section.dart';

class ApostillesPage extends StatefulWidget {
  final ProcessData contractData;

  const ApostillesPage({
    super.key,
    required this.contractData,
  });

  @override
  State<ApostillesPage> createState() => _ApostillesPageState();
}

class _ApostillesPageState extends State<ApostillesPage> {
  final TextEditingController _orderCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _valueCtrl = TextEditingController();

  late final ApostillesCubit _cubit;

  String? _lastFilledId;
  int? _selectedAttachmentIndex;

  /// ✅ aplica o "próximo order" apenas UMA vez após o primeiro load (loaded)
  bool _initialNextOrderApplied = false;

  @override
  void initState() {
    super.initState();

    _cubit = ApostillesCubit(
      contract: widget.contractData,
      repository: ApostillesRepository(),
    );

    void recomputeValidity() {
      _cubit.updateFormValidity(
        orderText: _orderCtrl.text,
        dateText: _dateCtrl.text,
        processText: _processCtrl.text,
        valueText: _valueCtrl.text,
      );
    }

    _orderCtrl.addListener(recomputeValidity);
    _processCtrl.addListener(recomputeValidity);
    _dateCtrl.addListener(recomputeValidity);
    _valueCtrl.addListener(recomputeValidity);

    WidgetsBinding.instance.addPostFrameCallback((_) => recomputeValidity());
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _processCtrl.dispose();
    _dateCtrl.dispose();
    _valueCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _fillForm(dynamic a) {
    _lastFilledId = a.id;

    _orderCtrl.text = (a.apostilleOrder ?? '').toString();
    _processCtrl.text = a.apostilleNumberProcess ?? '';
    _dateCtrl.text =
    a.apostilleData != null ? dateTimeToDDMMYYYY(a.apostilleData!) : '';
    _valueCtrl.text =
    a.apostilleValue != null ? priceToString(a.apostilleValue) : '';

    _cubit.updateFormValidity(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  void _clearForm({bool keepOrder = false}) {
    _lastFilledId = null;

    if (!keepOrder) _orderCtrl.clear();

    _processCtrl.clear();
    _dateCtrl.clear();
    _valueCtrl.clear();
    _selectedAttachmentIndex = null;

    _cubit.updateFormValidity(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  Future<void> _save() async {
    await _cubit.saveOrUpdate(
      orderText: _orderCtrl.text,
      processText: _processCtrl.text,
      dateText: _dateCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  void _applyInitialNextOrderOnce(ApostillesState state) {
    if (_initialNextOrderApplied) return;

    // só aplica após carregar a lista
    if (state.status != ApostillesStatus.loaded) return;

    // não sobrescreve se já existe seleção (edição)
    if (state.selected != null) return;

    // não sobrescreve se o usuário já digitou algo
    if (_orderCtrl.text.trim().isNotEmpty) return;

    // aplica o próximo order disponível
    if (state.nextAvailableOrder <= 0) return;

    _initialNextOrderApplied = true;
    _orderCtrl.text = state.nextAvailableOrder.toString();

    // garante modo "novo"
    _cubit.createNewApostille();

    // revalida
    _cubit.updateFormValidity(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ApostillesCubit>.value(
      value: _cubit,
      child: BlocBuilder<ApostillesCubit, ApostillesState>(
        builder: (context, state) {
          // ✅ aplica o próximo order ao iniciar (uma única vez)
          _applyInitialNextOrderOnce(state);

          // Deseleção -> limpa form (mantém order se já está no dropdown)
          if (state.selected == null && _lastFilledId != null) {
            _clearForm(keepOrder: true);
          }

          // Preenche ao selecionar novo
          if (state.selected != null && state.selected!.id != _lastFilledId) {
            _fillForm(state.selected!);
            _cubit.reloadAttachments();
          }

          final bool isLoading = state.status == ApostillesStatus.loading;

          final labels = state.apostilles
              .map((e) => (e.apostilleOrder ?? '').toString())
              .toList();
          final values = state.apostilles
              .map((e) => (e.apostilleValue ?? 0.0).toDouble())
              .toList();

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(
                                  text: 'Cadastrar apostilamentos no sistema',
                                ),

                                // ======================
                                // FORMULÁRIO
                                // ======================
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: ApostilleFormSection(
                                    isEditable: state.isEditable,
                                    editingMode: state.editingMode,
                                    formValidated: state.formValid,
                                    selectedApostille: state.selected,
                                    currentApostilleId: state.selected?.id,
                                    contractData: widget.contractData,
                                    orderController: _orderCtrl,
                                    processController: _processCtrl,
                                    dateController: _dateCtrl,
                                    valueController: _valueCtrl,
                                    onSave: _save,
                                    onClear: () {
                                      _cubit.createNewApostille();
                                      _clearForm();

                                      // ✅ após limpar, sempre volta para o próximo order disponível
                                      _orderCtrl.text =
                                          state.nextAvailableOrder.toString();

                                      _cubit.updateFormValidity(
                                        orderText: _orderCtrl.text,
                                        dateText: _dateCtrl.text,
                                        processText: _processCtrl.text,
                                        valueText: _valueCtrl.text,
                                      );
                                    },
                                    orderNumberOptions: state.orderOptions,
                                    greyOrderItems: state.greyOrderItems,

                                    // mudar ordem seleciona registro existente e sincroniza tudo
                                    onChangedOrderNumber: (v) {
                                      if (v == null) return;

                                      _orderCtrl.text = v;

                                      final ord = int.tryParse(v.trim()) ?? 0;

                                      // Seleciona por ordem (se existir)
                                      _cubit.selectApostilleByOrder(ord);
                                      _cubit.reloadAttachments();

                                      // Se não existe, fica "novo" e limpa os demais campos
                                      if (_cubit.state.selected == null) {
                                        _clearForm(keepOrder: true);
                                      } else {
                                        final sel = _cubit.state.selected!;
                                        _fillForm(sel);
                                      }

                                      _cubit.updateFormValidity(
                                        orderText: _orderCtrl.text,
                                        dateText: _dateCtrl.text,
                                        processText: _processCtrl.text,
                                        valueText: _valueCtrl.text,
                                      );
                                    },

                                    sideItems: state.sideAttachments,
                                    selectedSideIndex: _selectedAttachmentIndex,
                                    onAddSideItem: state.canAddFile
                                        ? () => _cubit.addAttachmentWithPicker(
                                      context,
                                    )
                                        : null,
                                    onTapSideItem: (i) {
                                      setState(
                                              () => _selectedAttachmentIndex = i);
                                    },
                                    onDeleteSideItem: (i) async {
                                      await _cubit.deleteAttachment(i);
                                      setState(() =>
                                      _selectedAttachmentIndex = null);
                                    },
                                    onEditLabelSideItem: (i) async {
                                      final att = state.sideAttachments[i];
                                      final controller =
                                      TextEditingController(text: att.label);

                                      final newLabel = await showDialog<String>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title:
                                          const Text('Renomear anexo'),
                                          content: TextField(
                                            controller: controller,
                                            autofocus: true,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child:
                                              const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(
                                                ctx,
                                                controller.text,
                                              ),
                                              child: const Text('Salvar'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (newLabel != null) {
                                        await _cubit.renameAttachment(
                                          index: i,
                                          newLabel: newLabel,
                                        );
                                      }
                                    },
                                  ),
                                ),

                                // ======================
                                // GRÁFICO
                                // ======================
                                const SectionTitle(
                                  text: 'Gráfico dos apostilamentos',
                                ),

                                if (!isLoading && state.apostilles.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                      'Nenhum apostilamento cadastrado para exibir no gráfico.',
                                    ),
                                  )
                                else
                                  ApostilleGraphSection(
                                    labels: labels,
                                    values: values,
                                    selectedIndex: state.selectedIndex,
                                    onSelectIndex: (index) {
                                      if (index < 0) {
                                        _cubit.createNewApostille();
                                        _clearForm();
                                        _orderCtrl.text = state.nextAvailableOrder
                                            .toString();
                                        return;
                                      }

                                      _cubit.selectApostilleByIndex(index);
                                      _cubit.reloadAttachments();

                                      final sel = _cubit.state.selected;
                                      if (sel?.apostilleOrder != null) {
                                        _orderCtrl.text =
                                            sel!.apostilleOrder.toString();
                                      }
                                    },
                                  ),

                                // ======================
                                // TABELA
                                // ======================
                                const SectionTitle(
                                  text:
                                  'Apostilamentos cadastrados no sistema',
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: ApostilleTableSection(
                                    apostilles: state.apostilles,
                                    isLoading: isLoading,
                                    selectedItem: state.selected,
                                    onTapItem: (a) {
                                      _cubit.selectApostille(a);
                                      _cubit.reloadAttachments();

                                      if (a.apostilleOrder != null) {
                                        _orderCtrl.text =
                                            a.apostilleOrder.toString();
                                      }
                                    },
                                    onDelete: (a) async {
                                      _cubit.selectApostille(a);
                                      await _cubit.deleteSelectedApostille();
                                    },
                                  ),
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

              if (state.isSaving)
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
      ),
    );
  }
}
