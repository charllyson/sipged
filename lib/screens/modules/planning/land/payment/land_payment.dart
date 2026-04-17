import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:sipged/_blocs/modules/planning/land/payment/land_payment_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/payment/land_payment_data.dart';
import 'package:sipged/_blocs/modules/planning/land/payment/land_payment_state.dart';

import 'package:sipged/_utils/formats/sipged_format_dates.dart';
import 'package:sipged/_utils/formats/sipged_format_numbers.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

class LandPayment extends StatefulWidget {
  final String contractId;
  final String propertyId;
  final String? userId;

  const LandPayment({
    super.key,
    required this.contractId,
    required this.propertyId,
    this.userId,
  });

  @override
  State<LandPayment> createState() => _LandPaymentState();
}

class _LandPaymentState extends State<LandPayment> {
  late final ScrollController _scrollCtrl;

  final paymentStatusCtrl = TextEditingController();
  final paymentTypeCtrl = TextEditingController();

  final paymentRequestDateCtrl = TextEditingController();
  final paymentAuthorizationDateCtrl = TextEditingController();
  final paymentDateCtrl = TextEditingController();

  final paidValueCtrl = TextEditingController();
  final accountingCommitmentCtrl = TextEditingController();
  final accountingLiquidationCtrl = TextEditingController();
  final bankOrderCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  DateTime? _paymentRequestDate;
  DateTime? _paymentAuthorizationDate;
  DateTime? _paymentDate;

  String? _lastSyncKey;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant LandPayment oldWidget) {
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
      context.read<LandPaymentCubit>().initialize(
        contractId: widget.contractId,
        propertyId: widget.propertyId,
      );
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    paymentStatusCtrl.dispose();
    paymentTypeCtrl.dispose();
    paymentRequestDateCtrl.dispose();
    paymentAuthorizationDateCtrl.dispose();
    paymentDateCtrl.dispose();
    paidValueCtrl.dispose();
    accountingCommitmentCtrl.dispose();
    accountingLiquidationCtrl.dispose();
    bankOrderCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  double _responsiveWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 3,
      reservedWidth: 0,
      spacing: 12,
      margin: 12,
      extraPadding: 24,
      spaceBetweenReserved: 12,
    );
  }

  double _toDouble(String value) {
    return SipGedFormatNumbers.toDouble(value) ?? 0;
  }

  void _syncFromState(LandPaymentData d) {
    final key = [
      d.id,
      d.updatedAt?.millisecondsSinceEpoch,
      d.paymentStatus,
      d.paymentType,
      d.paymentRequestDate?.millisecondsSinceEpoch,
      d.paymentAuthorizationDate?.millisecondsSinceEpoch,
      d.paymentDate?.millisecondsSinceEpoch,
      d.paidValue,
      d.accountingCommitment,
      d.accountingLiquidation,
      d.bankOrder,
      d.notes,
    ].join('_');

    if (_lastSyncKey == key) return;
    _lastSyncKey = key;

    paymentStatusCtrl.text = d.paymentStatus;
    paymentTypeCtrl.text = d.paymentType;

    paymentRequestDateCtrl.text = d.paymentRequestDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.paymentRequestDate!)
        : '';

    paymentAuthorizationDateCtrl.text = d.paymentAuthorizationDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(d.paymentAuthorizationDate!)
        : '';

    paymentDateCtrl.text =
    d.paymentDate != null ? SipGedFormatDates.dateToDdMMyyyy(d.paymentDate!) : '';

    paidValueCtrl.text = d.paidValue > 0 ? d.paidValue.toStringAsFixed(2) : '';

    accountingCommitmentCtrl.text = d.accountingCommitment;
    accountingLiquidationCtrl.text = d.accountingLiquidation;
    bankOrderCtrl.text = d.bankOrder;
    notesCtrl.text = d.notes;

    _paymentRequestDate = d.paymentRequestDate;
    _paymentAuthorizationDate = d.paymentAuthorizationDate;
    _paymentDate = d.paymentDate;
  }

  LandPaymentData _buildDraft(LandPaymentState state) {
    return state.draft.copyWith(
      paymentStatus: paymentStatusCtrl.text.trim(),
      paymentType: paymentTypeCtrl.text.trim(),
      paymentRequestDate: _paymentRequestDate,
      paymentAuthorizationDate: _paymentAuthorizationDate,
      paymentDate: _paymentDate,
      paidValue: _toDouble(paidValueCtrl.text),
      accountingCommitment: accountingCommitmentCtrl.text.trim(),
      accountingLiquidation: accountingLiquidationCtrl.text.trim(),
      bankOrder: bankOrderCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
    );
  }

  void _clearForm(LandPaymentState state) {
    final empty = LandPaymentData.empty(
      contractId: state.contractId,
      id: state.propertyId,
    );

    paymentStatusCtrl.clear();
    paymentTypeCtrl.clear();
    paymentRequestDateCtrl.clear();
    paymentAuthorizationDateCtrl.clear();
    paymentDateCtrl.clear();
    paidValueCtrl.clear();
    accountingCommitmentCtrl.clear();
    accountingLiquidationCtrl.clear();
    bankOrderCtrl.clear();
    notesCtrl.clear();

    _paymentRequestDate = null;
    _paymentAuthorizationDate = null;
    _paymentDate = null;

    context.read<LandPaymentCubit>().updateDraft(empty);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LandPaymentCubit, LandPaymentState>(
      listenWhen: (previous, current) =>
      previous.error != current.error ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.error != null && state.error!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }

        if (state.successMessage != null &&
            state.successMessage!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
      },
      builder: (context, state) {
        _syncFromState(state.draft);
        final bloc = context.read<LandPaymentCubit>();
        final w = _responsiveWidth(context);

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
              child: AbsorbPointer(
                absorbing: state.loading || state.saving,
                child: Column(
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
                        DropDownChange(
                          width: w,
                          enabled: true,
                          labelText: 'Status do Pagamento',
                          controller: paymentStatusCtrl,
                          items: const [
                            'Pendente',
                            'Solicitado',
                            'Autorizado',
                            'Pago',
                            'Parcialmente Pago',
                            'Cancelado',
                          ],
                        ),
                        DropDownChange(
                          width: w,
                          enabled: true,
                          labelText: 'Tipo de Pagamento',
                          controller: paymentTypeCtrl,
                          items: const [
                            'Administrativo',
                            'Judicial',
                            'Depósito Judicial',
                            'RPV',
                            'Precatório',
                            'Outro',
                          ],
                        ),
                        CustomTextField(
                          width: w,
                          controller: paidValueCtrl,
                          labelText: 'Valor Pago (R\$)',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            CurrencyInputFormatter(
                              leadingSymbol: 'R\$ ',
                              useSymbolPadding: true,
                              thousandSeparator: ThousandSeparator.Period,
                              mantissaLength: 2,
                            ),
                          ],
                        ),
                        DateFieldChange(
                          width: w,
                          enabled: true,
                          controller: paymentRequestDateCtrl,
                          initialValue: _paymentRequestDate,
                          labelText: 'Data da Solicitação',
                          onChanged: (value) {
                            setState(() => _paymentRequestDate = value);
                          },
                        ),
                        DateFieldChange(
                          width: w,
                          enabled: true,
                          controller: paymentAuthorizationDateCtrl,
                          initialValue: _paymentAuthorizationDate,
                          labelText: 'Data da Autorização',
                          onChanged: (value) {
                            setState(() => _paymentAuthorizationDate = value);
                          },
                        ),
                        DateFieldChange(
                          width: w,
                          enabled: true,
                          controller: paymentDateCtrl,
                          initialValue: _paymentDate,
                          labelText: 'Data do Pagamento',
                          onChanged: (value) {
                            setState(() => _paymentDate = value);
                          },
                        ),
                        CustomTextField(
                          width: w,
                          controller: accountingCommitmentCtrl,
                          labelText: 'Empenho Contábil',
                        ),
                        CustomTextField(
                          width: w,
                          controller: accountingLiquidationCtrl,
                          labelText: 'Liquidação Contábil',
                        ),
                        CustomTextField(
                          width: w,
                          controller: bankOrderCtrl,
                          labelText: 'Ordem Bancária',
                        ),
                        CustomTextField(
                          width: (w * 2) + 12,
                          controller: notesCtrl,
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
                          icon: const Icon(Icons.refresh),
                          label: const Text('Recarregar'),
                          onPressed: state.loading
                              ? null
                              : () => bloc.initialize(
                            contractId: widget.contractId,
                            propertyId: widget.propertyId,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.cleaning_services_outlined),
                          label: const Text('Limpar'),
                          onPressed:
                          state.saving ? null : () => _clearForm(state),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Excluir'),
                          onPressed: state.saving ? null : () => bloc.delete(),
                        ),
                        ElevatedButton.icon(
                          icon: state.saving
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.save),
                          label: Text(
                            state.saving ? 'Salvando...' : 'Salvar',
                          ),
                          onPressed: state.saving
                              ? null
                              : () {
                            bloc.updateDraft(_buildDraft(state));
                            bloc.save(userId: widget.userId);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}