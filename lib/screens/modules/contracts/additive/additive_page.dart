// lib/screens/modules/contracts/additives/additive_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_cubit.dart';

// Cubit / State / Repo
import 'package:sipged/_blocs/modules/contracts/additives/additives_state.dart';
import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_money.dart';

// Widgets auxiliares
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

// ✅ Attachment para callback do rename
import 'package:sipged/_widgets/list/files/attachment.dart';

import 'additive_form_section.dart';
import 'additive_graph_section.dart';
import 'additive_table_section.dart';

class AdditivePage extends StatefulWidget {
  final ProcessData contractData;

  const AdditivePage({
    super.key,
    required this.contractData,
  });

  @override
  State<AdditivePage> createState() => _AdditivePageState();
}

class _AdditivePageState extends State<AdditivePage> {
  final TextEditingController _orderCtrl = TextEditingController();
  final TextEditingController _processCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  final TextEditingController _typeCtrl = TextEditingController();
  final TextEditingController _valueCtrl = TextEditingController();
  final TextEditingController _addDaysExecCtrl = TextEditingController();
  final TextEditingController _addDaysContractCtrl = TextEditingController();

  late final AdditivesCubit _cubit;

  String? _lastFilledId;
  int? _selectedAttachmentIndex;

  /// ✅ aplica o "próximo order" apenas UMA vez após o primeiro load (loaded)
  bool _initialNextOrderApplied = false;

  @override
  void initState() {
    super.initState();

    _cubit = AdditivesCubit(
      contract: widget.contractData,
      repository: AdditivesRepository(),
    );

    void recomputeValidity() {
      _cubit.updateFormValidity(
        typeText: _typeCtrl.text,
        dateText: _dateCtrl.text,
        processText: _processCtrl.text,
        valueText: _valueCtrl.text,
        addExecText: _addDaysExecCtrl.text,
        addContractText: _addDaysContractCtrl.text,
      );
    }

    _orderCtrl.addListener(recomputeValidity);
    _processCtrl.addListener(recomputeValidity);
    _dateCtrl.addListener(recomputeValidity);
    _typeCtrl.addListener(recomputeValidity);
    _valueCtrl.addListener(recomputeValidity);
    _addDaysExecCtrl.addListener(recomputeValidity);
    _addDaysContractCtrl.addListener(recomputeValidity);

    WidgetsBinding.instance.addPostFrameCallback((_) => recomputeValidity());
  }

  @override
  void dispose() {
    _orderCtrl.dispose();
    _processCtrl.dispose();
    _dateCtrl.dispose();
    _typeCtrl.dispose();
    _valueCtrl.dispose();
    _addDaysExecCtrl.dispose();
    _addDaysContractCtrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _fillForm(AdditivesData a) {
    _lastFilledId = a.id;

    _orderCtrl.text = (a.additiveOrder ?? '').toString();
    _processCtrl.text = a.additiveNumberProcess ?? '';
    _dateCtrl.text =
    a.additiveDate != null ? SipGedFormatDates.dateToDdMMyyyy(a.additiveDate!) : '';
    _typeCtrl.text = a.typeOfAdditive ?? '';
    _valueCtrl.text =
    a.additiveValue != null ? SipGedFormatMoney.doubleToText(a.additiveValue) : '';
    _addDaysExecCtrl.text = a.additiveValidityExecutionDays?.toString() ?? '';
    _addDaysContractCtrl.text = a.additiveValidityContractDays?.toString() ?? '';

    _cubit.updateFormValidity(
      typeText: _typeCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
      addExecText: _addDaysExecCtrl.text,
      addContractText: _addDaysContractCtrl.text,
    );
  }

  void _clearForm({bool keepOrder = false}) {
    _lastFilledId = null;

    if (!keepOrder) _orderCtrl.clear();

    _processCtrl.clear();
    _dateCtrl.clear();
    _typeCtrl.clear();
    _valueCtrl.clear();
    _addDaysExecCtrl.clear();
    _addDaysContractCtrl.clear();

    _selectedAttachmentIndex = null;

    _cubit.updateFormValidity(
      typeText: _typeCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
      addExecText: _addDaysExecCtrl.text,
      addContractText: _addDaysContractCtrl.text,
    );
  }

  Future<void> _save() async {
    await _cubit.saveOrUpdate(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      valueText: _valueCtrl.text,
      addDaysExecText: _addDaysExecCtrl.text,
      addDaysContractText: _addDaysContractCtrl.text,
      processText: _processCtrl.text,
      typeText: _typeCtrl.text,
    );
  }

  void _applyInitialNextOrderOnce(AdditivesState state) {
    if (_initialNextOrderApplied) return;

    if (state.status != AdditivesStatus.loaded) return;
    if (state.selected != null) return;
    if (_orderCtrl.text.trim().isNotEmpty) return;
    if (state.nextAvailableOrder <= 0) return;

    _initialNextOrderApplied = true;
    _orderCtrl.text = state.nextAvailableOrder.toString();

    // garante modo "novo"
    _cubit.createNewAdditive();

    // revalida
    _cubit.updateFormValidity(
      typeText: _typeCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
      addExecText: _addDaysExecCtrl.text,
      addContractText: _addDaysContractCtrl.text,
    );
  }

  void _ensureSelectedAttachmentIndexValid(int newLen) {
    if (_selectedAttachmentIndex == null) return;
    if (newLen <= 0) {
      setState(() => _selectedAttachmentIndex = null);
      return;
    }
    if (_selectedAttachmentIndex! >= newLen) {
      setState(() => _selectedAttachmentIndex = newLen - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdditivesCubit>.value(
      value: _cubit,
      child: BlocBuilder<AdditivesCubit, AdditivesState>(
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

          final bool isLoading = state.status == AdditivesStatus.loading;

          final labels = state.additives.map((e) => (e.additiveOrder ?? '').toString()).toList();

          final values = state.additives.map((e) => (e.additiveValue ?? 0.0).toDouble()).toList();

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SectionTitle(text: 'Cadastrar aditivos no sistema'),

                                // ======================
                                // FORMULÁRIO
                                // ======================
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: AdditiveFormSection(
                                    isEditable: state.isEditable,
                                    editingMode: state.editingMode,
                                    formValidated: state.formValid,
                                    selectedAdditive: state.selected,
                                    currentAdditiveId: state.selected?.id,
                                    contractData: widget.contractData,
                                    orderController: _orderCtrl,
                                    processController: _processCtrl,
                                    dateController: _dateCtrl,
                                    typeOfAdditiveCtrl: _typeCtrl,
                                    valueController: _valueCtrl,
                                    additionalDaysExecutionController: _addDaysExecCtrl,
                                    additionalDaysContractController: _addDaysContractCtrl,
                                    sideLoading: state.sideLoading,
                                    uploadProgress: state.uploadProgress,
                                    onSave: _save,
                                    onClear: () {
                                      _cubit.createNewAdditive();
                                      _clearForm();

                                      // ✅ após limpar, sempre volta para o próximo order disponível
                                      _orderCtrl.text = state.nextAvailableOrder.toString();

                                      _cubit.updateFormValidity(
                                        typeText: _typeCtrl.text,
                                        dateText: _dateCtrl.text,
                                        processText: _processCtrl.text,
                                        valueText: _valueCtrl.text,
                                        addExecText: _addDaysExecCtrl.text,
                                        addContractText: _addDaysContractCtrl.text,
                                      );
                                    },
                                    orderOptions: state.orderOptions,
                                    greyOrderItems: state.greyOrderItems,

                                    // ✅ mudar ordem seleciona registro existente e sincroniza tudo
                                    onChangedOrder: (v) {
                                      if (v == null) return;

                                      _orderCtrl.text = v;
                                      final ord = int.tryParse(v.trim()) ?? 0;

                                      _cubit.selectAdditiveByOrder(ord);
                                      _cubit.reloadAttachments();

                                      if (_cubit.state.selected == null) {
                                        _clearForm(keepOrder: true);
                                      } else {
                                        _fillForm(_cubit.state.selected!);
                                      }

                                      _cubit.updateFormValidity(
                                        typeText: _typeCtrl.text,
                                        dateText: _dateCtrl.text,
                                        processText: _processCtrl.text,
                                        valueText: _valueCtrl.text,
                                        addExecText: _addDaysExecCtrl.text,
                                        addContractText: _addDaysContractCtrl.text,
                                      );
                                    },

                                    // SideList
                                    sideItems: state.sideAttachments,
                                    selectedSideIndex: _selectedAttachmentIndex,
                                    onAddSideItem: state.canAddFile
                                        ? () => _cubit.addAttachmentWithPicker(context)
                                        : null,
                                    onTapSideItem: (i) {
                                      setState(() => _selectedAttachmentIndex = i);
                                    },
                                    onDeleteSideItem: (i) async {
                                      await _cubit.deleteAttachment(i);
                                      if (!mounted) return;
                                      setState(() => _selectedAttachmentIndex = null);
                                    },

                                    // ✅ NOVO: apenas garante índice selecionado válido
                                    onSideItemsChanged: (newItems) {
                                      _ensureSelectedAttachmentIndexValid(newItems.length);
                                    },

                                    // ✅ NOVO: persist rename (SideListBox abre dialog; aqui só salva)
                                    onRenamePersistSideItem: ({
                                      required int index,
                                      required Attachment oldItem,
                                      required Attachment newItem,
                                    }) async {
                                      try {
                                        await _cubit.renameAttachment(
                                          index: index,
                                          newLabel: newItem.label,
                                        );
                                        return true;
                                      } catch (_) {
                                        return false;
                                      }
                                    },
                                  ),
                                ),

                                // ======================
                                // GRÁFICO
                                // ======================
                                const SectionTitle(text: 'Gráfico dos aditivos'),

                                if (!isLoading && state.additives.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text('Nenhum aditivo cadastrado para exibir no gráfico.'),
                                  )
                                else
                                  AdditiveGraphSection(
                                    labels: labels,
                                    values: values,
                                    selectedIndex: state.selectedIndex,
                                    onSelectIndex: (index) {
                                      if (index < 0) {
                                        _cubit.createNewAdditive();
                                        _clearForm();
                                        _orderCtrl.text = state.nextAvailableOrder.toString();
                                        return;
                                      }

                                      _cubit.selectAdditiveByIndex(index);
                                      _cubit.reloadAttachments();

                                      final sel = _cubit.state.selected;
                                      if (sel?.additiveOrder != null) {
                                        _orderCtrl.text = sel!.additiveOrder.toString();
                                      }
                                    },
                                  ),

                                // ======================
                                // TABELA
                                // ======================
                                const SectionTitle(text: 'Aditivos cadastrados no sistema'),

                                AdditiveTableSection(
                                  additives: state.additives,
                                  isLoading: isLoading,
                                  selectedItem: state.selected,
                                  onTapItem: (a) {
                                    _cubit.selectAdditive(a);
                                    _cubit.reloadAttachments();

                                    if (a.additiveOrder != null) {
                                      _orderCtrl.text = a.additiveOrder.toString();
                                    }
                                  },
                                  onDelete: (a) async {
                                    _cubit.selectAdditive(a);
                                    await _cubit.deleteSelectedAdditive();
                                  },
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

              // Overlay de salvamento (mantém)
              if (state.isSaving)
                Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.4),
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
