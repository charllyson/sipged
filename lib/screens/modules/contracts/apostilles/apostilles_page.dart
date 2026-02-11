// lib/screens/modules/contracts/apostilles/apostilles_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_cubit.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_state.dart';
import 'package:siged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';
import 'package:siged/_utils/formats/sipged_format_dates.dart';
import 'package:siged/_utils/formats/sipged_format_money.dart';

import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_widgets/list/files/attachment.dart';

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
    _dateCtrl.text = a.apostilleData != null
        ? SipGedFormatDates.dateToDdMMyyyy(a.apostilleData!)
        : '';
    _valueCtrl.text = a.apostilleValue != null
        ? SipGedFormatMoney.doubleToText(a.apostilleValue)
        : '';

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

    if (state.status != ApostillesStatus.loaded) return;
    if (state.selected != null) return;
    if (_orderCtrl.text.trim().isNotEmpty) return;
    if (state.nextAvailableOrder <= 0) return;

    _initialNextOrderApplied = true;
    _orderCtrl.text = state.nextAvailableOrder.toString();

    _cubit.createNewApostille();

    _cubit.updateFormValidity(
      orderText: _orderCtrl.text,
      dateText: _dateCtrl.text,
      processText: _processCtrl.text,
      valueText: _valueCtrl.text,
    );
  }

  /// ✅ SideListBox renomeia e pede para persistir aqui
  Future<bool> _persistRenameAttachment({
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ApostillesCubit>.value(
      value: _cubit,
      child: BlocBuilder<ApostillesCubit, ApostillesState>(
        builder: (context, state) {
          _applyInitialNextOrderOnce(state);

          if (state.selected == null && _lastFilledId != null) {
            _clearForm(keepOrder: true);
          }

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
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
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

                                      _orderCtrl.text = state.nextAvailableOrder.toString();

                                      _cubit.updateFormValidity(
                                        orderText: _orderCtrl.text,
                                        dateText: _dateCtrl.text,
                                        processText: _processCtrl.text,
                                        valueText: _valueCtrl.text,
                                      );
                                    },
                                    orderNumberOptions: state.orderOptions,
                                    greyOrderItems: state.greyOrderItems,
                                    onChangedOrderNumber: (v) {
                                      if (v == null) return;

                                      _orderCtrl.text = v;

                                      final ord = int.tryParse(v.trim()) ?? 0;

                                      _cubit.selectApostilleByOrder(ord);
                                      _cubit.reloadAttachments();

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

                                    // ===== SideListBox =====
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

                                    // ✅ rename persist (o próprio FormSection vai decidir se habilita)
                                    onRenamePersist: _persistRenameAttachment,

                                    // mantém seleção válida
                                    onItemsChanged: (newItems) {
                                      final len = newItems.length;
                                      if (_selectedAttachmentIndex != null &&
                                          (_selectedAttachmentIndex! >= len)) {
                                        setState(() => _selectedAttachmentIndex = null);
                                      }
                                    },
                                  ),
                                ),

                                // ======================
                                // GRÁFICO
                                // ======================
                                const SectionTitle(text: 'Gráfico dos apostilamentos'),

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
                                        _orderCtrl.text = state.nextAvailableOrder.toString();
                                        return;
                                      }

                                      _cubit.selectApostilleByIndex(index);
                                      _cubit.reloadAttachments();

                                      final sel = _cubit.state.selected;
                                      if (sel?.apostilleOrder != null) {
                                        _orderCtrl.text = sel!.apostilleOrder.toString();
                                      }
                                    },
                                  ),

                                // ======================
                                // TABELA
                                // ======================
                                const SectionTitle(
                                  text: 'Apostilamentos cadastrados no sistema',
                                ),

                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: ApostilleTableSection(
                                    apostilles: state.apostilles,
                                    isLoading: isLoading,
                                    selectedItem: state.selected,
                                    onTapItem: (a) {
                                      _cubit.selectApostille(a);
                                      _cubit.reloadAttachments();

                                      if (a.apostilleOrder != null) {
                                        _orderCtrl.text = a.apostilleOrder.toString();
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
