import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'package:sipged/_blocs/modules/planning/land/assessment/land_assessment_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/assessment/land_assessment_data.dart';
import 'package:sipged/_blocs/modules/planning/land/assessment/land_assessment_state.dart';

import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_numbers.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

class LandAssessment extends StatefulWidget {
  final String contractId;
  final String propertyId;

  const LandAssessment({
    super.key,
    required this.contractId,
    required this.propertyId,
  });

  @override
  State<LandAssessment> createState() => _LandAssessmentState();
}

class _LandAssessmentState extends State<LandAssessment> {
  late final ScrollController _scrollCtrl;

  final _appraisalNumberCtrl = TextEditingController();
  final _appraiserNameCtrl = TextEditingController();
  final _appraisalMethodCtrl = TextEditingController();

  final _inspectionDateCtrl = TextEditingController();
  final _appraisalDateCtrl = TextEditingController();

  final _appraisalValueCtrl = TextEditingController();
  final _indemnityTypeCtrl = TextEditingController();
  final _indemnityValueCtrl = TextEditingController();
  final _ownerCounterValueCtrl = TextEditingController();
  final _govProposalValueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _inspectionDate;
  DateTime? _appraisalDate;

  String? _lastSyncKey;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LandAssessment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contractId != widget.contractId ||
        oldWidget.propertyId != widget.propertyId) {
      _lastSyncKey = null;
      _initialize();
    }
  }

  void _initialize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LandAssessmentCubit>().initialize(
        contractId: widget.contractId,
        propertyId: widget.propertyId,
      );
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();

    _appraisalNumberCtrl.dispose();
    _appraiserNameCtrl.dispose();
    _appraisalMethodCtrl.dispose();
    _inspectionDateCtrl.dispose();
    _appraisalDateCtrl.dispose();
    _appraisalValueCtrl.dispose();
    _indemnityTypeCtrl.dispose();
    _indemnityValueCtrl.dispose();
    _ownerCounterValueCtrl.dispose();
    _govProposalValueCtrl.dispose();
    _notesCtrl.dispose();

    super.dispose();
  }

  double _responsiveWidth(BuildContext context, double reserved) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: reserved,
      spacing: 12,
      margin: 12,
      extraPadding: 24,
      spaceBetweenReserved: 12,
    );
  }

  double _toDouble(String value) {
    return SipGedFormatNumbers.toDouble(value) ?? 0;
  }

  void _syncFromState(LandAssessmentData d) {
    final key = [
      d.id ?? '',
      d.updatedAt?.millisecondsSinceEpoch ?? 0,
      d.createdAt?.millisecondsSinceEpoch ?? 0,
      d.appraisalNumber,
      d.appraiserName,
      d.appraisalMethod,
      d.inspectionDate?.millisecondsSinceEpoch ?? 0,
      d.appraisalDate?.millisecondsSinceEpoch ?? 0,
      d.appraisalValue,
      d.indemnityType,
      d.indemnityValue,
      d.ownerCounterValue,
      d.govProposalValue,
      d.notes,
    ].join('_');

    if (_lastSyncKey == key) return;
    _lastSyncKey = key;

    _appraisalNumberCtrl.text = d.appraisalNumber;
    _appraiserNameCtrl.text = d.appraiserName;
    _appraisalMethodCtrl.text = d.appraisalMethod;

    _inspectionDate = d.inspectionDate;
    _appraisalDate = d.appraisalDate;

    _inspectionDateCtrl.text = d.inspectionDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.inspectionDate!)
        : '';

    _appraisalDateCtrl.text = d.appraisalDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.appraisalDate!)
        : '';

    _appraisalValueCtrl.text =
    d.appraisalValue == 0 ? '' : d.appraisalValue.toStringAsFixed(2);

    _indemnityTypeCtrl.text = d.indemnityType;

    _indemnityValueCtrl.text =
    d.indemnityValue == 0 ? '' : d.indemnityValue.toStringAsFixed(2);

    _ownerCounterValueCtrl.text =
    d.ownerCounterValue == 0 ? '' : d.ownerCounterValue.toStringAsFixed(2);

    _govProposalValueCtrl.text =
    d.govProposalValue == 0 ? '' : d.govProposalValue.toStringAsFixed(2);

    _notesCtrl.text = d.notes;
  }

  LandAssessmentData _buildDraft(LandAssessmentState state) {
    return state.draft.copyWith(
      appraisalNumber: _appraisalNumberCtrl.text.trim(),
      appraiserName: _appraiserNameCtrl.text.trim(),
      appraisalMethod: _appraisalMethodCtrl.text.trim(),
      inspectionDate: _inspectionDate,
      appraisalDate: _appraisalDate,
      appraisalValue: _toDouble(_appraisalValueCtrl.text),
      indemnityType: _indemnityTypeCtrl.text.trim(),
      indemnityValue: _toDouble(_indemnityValueCtrl.text),
      ownerCounterValue: _toDouble(_ownerCounterValueCtrl.text),
      govProposalValue: _toDouble(_govProposalValueCtrl.text),
      notes: _notesCtrl.text.trim(),
    );
  }

  bool _canSave() {
    return _appraisalNumberCtrl.text.trim().isNotEmpty ||
        _appraiserNameCtrl.text.trim().isNotEmpty ||
        _appraisalMethodCtrl.text.trim().isNotEmpty ||
        _inspectionDate != null ||
        _appraisalDate != null ||
        _appraisalValueCtrl.text.trim().isNotEmpty ||
        _indemnityTypeCtrl.text.trim().isNotEmpty ||
        _indemnityValueCtrl.text.trim().isNotEmpty ||
        _ownerCounterValueCtrl.text.trim().isNotEmpty ||
        _govProposalValueCtrl.text.trim().isNotEmpty ||
        _notesCtrl.text.trim().isNotEmpty;
  }

  void _clearForm(LandAssessmentState state) {
    final cleared = LandAssessmentData.empty(
      contractId: state.contractId,
      id: state.propertyId,
    );

    context.read<LandAssessmentCubit>().updateDraft(cleared);
    _syncFromState(cleared);

    setState(() {
      _inspectionDate = null;
      _appraisalDate = null;
    });
  }

  Widget _buildMoneyField({
    required double width,
    required TextEditingController controller,
    required String label,
  }) {
    return CustomTextField(
      width: width,
      controller: controller,
      labelText: label,
      keyboardType: TextInputType.number,
      inputFormatters: [
        CurrencyInputFormatter(
          leadingSymbol: 'R\$ ',
          useSymbolPadding: true,
          thousandSeparator: ThousandSeparator.Period,
          mantissaLength: 2,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LandAssessmentCubit, LandAssessmentState>(
      listenWhen: (previous, current) =>
      previous.error != current.error ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.error != null && state.error!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (state.successMessage != null &&
            state.successMessage!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        _syncFromState(state.draft);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 920;
            final reserved = 0.0;
            final w = _responsiveWidth(context, reserved);

            final body = Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    CustomTextField(
                      width: w,
                      controller: _appraisalNumberCtrl,
                      labelText: 'Nº do Laudo',
                    ),
                    CustomTextField(
                      width: w,
                      controller: _appraiserNameCtrl,
                      labelText: 'Avaliador / Empresa',
                    ),
                    CustomTextField(
                      width: w,
                      controller: _appraisalMethodCtrl,
                      labelText: 'Método de Avaliação',
                    ),
                    DateFieldChange(
                      width: w,
                      enabled: !state.saving,
                      controller: _inspectionDateCtrl,
                      initialValue: _inspectionDate,
                      labelText: 'Data da Vistoria',
                      onChanged: (value) {
                        setState(() {
                          _inspectionDate = value;
                        });
                      },
                    ),
                    DateFieldChange(
                      width: w,
                      enabled: !state.saving,
                      controller: _appraisalDateCtrl,
                      initialValue: _appraisalDate,
                      labelText: 'Data do Laudo',
                      onChanged: (value) {
                        setState(() {
                          _appraisalDate = value;
                        });
                      },
                    ),
                    _buildMoneyField(
                      width: w,
                      controller: _appraisalValueCtrl,
                      label: 'Valor Avaliado (R\$)',
                    ),
                    CustomTextField(
                      width: w,
                      controller: _indemnityTypeCtrl,
                      labelText: 'Tipo de Indenização',
                    ),
                    _buildMoneyField(
                      width: w,
                      controller: _indemnityValueCtrl,
                      label: 'Valor da Indenização (R\$)',
                    ),
                    _buildMoneyField(
                      width: w,
                      controller: _ownerCounterValueCtrl,
                      label: 'Contraproposta do Proprietário (R\$)',
                    ),
                    _buildMoneyField(
                      width: w,
                      controller: _govProposalValueCtrl,
                      label: 'Proposta do Órgão (R\$)',
                    ),
                    CustomTextField(
                      width: isSmall ? constraints.maxWidth - 24 : (w * 2) + 12,
                      controller: _notesCtrl,
                      labelText: 'Observações',
                      maxLines: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: state.loading
                          ? null
                          : () => context.read<LandAssessmentCubit>().initialize(
                        contractId: widget.contractId,
                        propertyId: widget.propertyId,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Recarregar'),
                    ),
                    TextButton.icon(
                      onPressed: state.saving || !_canSave()
                          ? null
                          : () async {
                        final cubit = context.read<LandAssessmentCubit>();
                        cubit.updateDraft(_buildDraft(state));
                        await cubit.save();
                      },
                      icon: state.saving
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.save),
                      label: Text(
                        state.draft.createdAt != null ? 'Atualizar' : 'Salvar',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: state.saving ? null : () => _clearForm(state),
                      icon: const Icon(Icons.restore),
                      label: const Text('Limpar'),
                    ),
                    TextButton.icon(
                      onPressed: state.saving
                          ? null
                          : () async {
                        await context.read<LandAssessmentCubit>().delete();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir'),
                    ),
                  ],
                ),
              ],
            );

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Scrollbar(
                controller: _scrollCtrl,
                thumbVisibility: true,
                interactive: true,
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  primary: false,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  child: body,
                ),
              ),
            );
          },
        );
      },
    );
  }
}