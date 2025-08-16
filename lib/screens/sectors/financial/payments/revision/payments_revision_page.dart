import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart' show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/sectors/financial/payments/revision/payment_revision_chart_section.dart';
import 'package:sisged/screens/sectors/financial/payments/revision/payment_revision_form_section.dart';
import 'package:sisged/screens/sectors/financial/payments/revision/payment_revision_table_section.dart';

import '../../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../../_blocs/sectors/financial/payments/payments_revision_bloc.dart';
import '../../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../../_datas/sectors/financial/payments/payments_revisions_data.dart';
import '../../../../../_datas/system/user_data.dart';
import '../../../../../../_widgets/texts/divider_text.dart';
import '../../../../../../_widgets/validates/form_validation_mixin.dart';
import '../../../../../admPanel/converters/importExcel/import_excel_page.dart';

class PaymentsRevisionPage extends StatefulWidget {
  const PaymentsRevisionPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<PaymentsRevisionPage> createState() => _PaymentsRevisionPageState();
}

class _PaymentsRevisionPageState extends State<PaymentsRevisionPage>
    with FormValidationMixin {
  late PaymentsRevisionBloc _paymentRevisionBloc;
  late UserBloc _userBloc;
  late AdditivesBloc _additivesBloc;
  late UserData _currentUser;

  late Future<void> _futureInit;

  List<PaymentsRevisionsData> _paymentsRevisionData = [];
  PaymentsRevisionsData? _selectedPaymentRevisionData;

  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  int? _selectedLine;
  String? _currentPaymentRevisionId;
  bool _formValidated = false;
  bool _isEditable = false;
  bool _isSaving = false;

  final _orderPaymentRevisionController = TextEditingController();
  final _processPaymentRevisionController = TextEditingController();
  final _valuePaymentRevisionController = TextEditingController();
  final _datePaymentRevisionController = TextEditingController();
  final _statePaymentRevisionController = TextEditingController();
  final _observationPaymentRevisionController = TextEditingController();
  final _bankPaymentRevisionController = TextEditingController();
  final _electronicTicketPaymentRevisionController = TextEditingController();
  final _fontPaymentRevisionController = TextEditingController();
  final _taxPaymentRevisionController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _paymentRevisionBloc = PaymentsRevisionBloc();
    _userBloc = UserBloc();
    _additivesBloc = AdditivesBloc();
    _currentUser = Provider.of<UserProvider>(context, listen: false).userData!;

    final user = _currentUser;
    _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);

    setupValidation([
      _orderPaymentRevisionController,
      _processPaymentRevisionController,
      _valuePaymentRevisionController,
      _datePaymentRevisionController,
    ], _validateForm);

    _futureInit = _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    if (widget.contractData?.id == null) return;

    _valorInicial = widget.contractData?.initialValueContract ?? 0.0;
    _valorAditivos = await _additivesBloc.getAllAdditivesValue(widget.contractData!.id!);
    _paymentsRevisionData = await _paymentRevisionBloc.getAllReportPaymentsOfContract(contractId: widget.contractData!.id!);

    final ultimaOrdem = _paymentsRevisionData.isNotEmpty
        ? _paymentsRevisionData.map((e) => e.orderPaymentRevision ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    _orderPaymentRevisionController.text = (ultimaOrdem + 1).toString();
  }

  void _validateForm() {
    final valid = areFieldsFilled([
      _orderPaymentRevisionController,
      _processPaymentRevisionController,
      _valuePaymentRevisionController,
      _datePaymentRevisionController,
    ], minLength: 1);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }

  void _fillFields(PaymentsRevisionsData data) {
    setState(() {
      _selectedPaymentRevisionData = data;
      _currentPaymentRevisionId = data.idRevisionPayment;
      _orderPaymentRevisionController.text = data.orderPaymentRevision.toString();
      _processPaymentRevisionController.text = data.processPaymentRevision ?? '';
      _valuePaymentRevisionController.text = priceToString(data.valuePaymentRevision);
      _datePaymentRevisionController.text = convertDateTimeToDDMMYYYY(data.datePaymentRevision!);
      _statePaymentRevisionController.text = data.statePaymentRevision ?? '';
      _observationPaymentRevisionController.text = data.observationPaymentRevision ?? '';
      _bankPaymentRevisionController.text = data.orderBankPaymentRevision ?? '';
      _electronicTicketPaymentRevisionController.text = data.electronicTicketPaymentRevision ?? '';
      _fontPaymentRevisionController.text = data.fontPaymentRevision ?? '';
      _taxPaymentRevisionController.text = priceToString(data.taxPaymentRevision);
    });
  }


  void _createNew() {
    final lastPaymentAdjustment = _paymentsRevisionData.map((e) => e.orderPaymentRevision ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _selectedLine = null;
      _orderPaymentRevisionController.text = (lastPaymentAdjustment + 1).toString();
      _processPaymentRevisionController.clear();
      _valuePaymentRevisionController.clear();
      _datePaymentRevisionController.clear();
      _statePaymentRevisionController.clear();
      _observationPaymentRevisionController.clear();
      _bankPaymentRevisionController.clear();
      _electronicTicketPaymentRevisionController.clear();
      _fontPaymentRevisionController.clear();
      _taxPaymentRevisionController.clear();
    });
  }

  void _saveOrUpdate() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja salvar este pagamento da revião?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isSaving = true);

    final newPayment = PaymentsRevisionsData(
      contractId: widget.contractData!.id!,
      idRevisionPayment: _currentPaymentRevisionId,
      orderPaymentRevision: int.tryParse(_orderPaymentRevisionController.text),
      processPaymentRevision: _processPaymentRevisionController.text,
      valuePaymentRevision: parseCurrencyToDouble(_valuePaymentRevisionController.text),
      datePaymentRevision: convertDDMMYYYYToDateTime(_datePaymentRevisionController.text),
      statePaymentRevision: _statePaymentRevisionController.text,
      observationPaymentRevision: _observationPaymentRevisionController.text,
      orderBankPaymentRevision: _bankPaymentRevisionController.text,
      electronicTicketPaymentRevision: _electronicTicketPaymentRevisionController.text,
      fontPaymentRevision: _fontPaymentRevisionController.text,
      taxPaymentRevision: parseCurrencyToDouble(_taxPaymentRevisionController.text),
    );

    await _paymentRevisionBloc.saveOrUpdatePayment(newPayment);

    _paymentsRevisionData = await _paymentRevisionBloc.getAllReportPaymentsOfContract(contractId: widget.contractData!.id!);
    _createNew();

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pagamento salvo com sucesso!'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
    );
  }

  void _deleteData(String idPaymentRevision) async {
    if (widget.contractData?.id == null) return;
    await _paymentRevisionBloc.deletarPayment(widget.contractData!.id!, idPaymentRevision);
    _paymentsRevisionData = await _paymentRevisionBloc.getAllReportPaymentsOfContract(contractId: widget.contractData!.id!);
    setState(() => _selectedLine = null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pagamento de reajustamento apagado com sucesso.'), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _futureInit,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final labels = _paymentsRevisionData.map((m) => (m.orderPaymentRevision ?? 0).toString()).toList();
          final values = _paymentsRevisionData.map((m) => m.valuePaymentRevision ?? 0.0).toList();
          final totalMedicoes = values.fold(0.0, (a, b) => a + b);
          final valorTotal = _valorInicial + _valorAditivos;
          final saldo = valorTotal - totalMedicoes;

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
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  DividerText(title: 'Gráfico dos pagamentos de reajuste'),
                                  const SizedBox(height: 12),
                                  PaymentsRevisionChartsSection(
                                    labels: labels,
                                    values: values,
                                    valorTotal: valorTotal,
                                    totalMedicoes: totalMedicoes,
                                    selectedIndex: _selectedLine,
                                    onSelectIndex: (index) {
                                      setState(() {
                                        _selectedLine = index;
                                        _fillFields(_selectedPaymentRevisionData!);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  DividerText(title: 'Cadastrar pagamento de reajuste no sistema'),
                                  const SizedBox(height: 12),
                                  PaymentRevisionFormSection(
                                    orderPaymentRevisionController: _orderPaymentRevisionController,
                                    processPaymentRevisionController: _processPaymentRevisionController,
                                    valuePaymentRevisionController: _valuePaymentRevisionController,
                                    statePaymentRevisionController: _statePaymentRevisionController,
                                    observationPaymentRevisionController: _observationPaymentRevisionController,
                                    bankPaymentRevisionController: _bankPaymentRevisionController,
                                    electronicTicketPaymentRevisionController: _electronicTicketPaymentRevisionController,
                                    fontPaymentRevisionController: _fontPaymentRevisionController,
                                    datePaymentRevisionController: _datePaymentRevisionController,
                                    taxPaymentRevisionController: _taxPaymentRevisionController,
                                    selectedPaymentsRevisionData: _selectedPaymentRevisionData,
                                    isEditable: _isEditable,
                                    isSaving: _isSaving,
                                    formValidated: _formValidated,
                                    onSaveOrUpdate: _saveOrUpdate,
                                    contractData: widget.contractData,
                                    paymentRevisionBloc: _paymentRevisionBloc,
                                    onClear: _createNew,
                                  ),
                                  const SizedBox(height: 12),
                                  DividerText(
                                    title: 'Pagamentos de reajustes cadastrados no sistema',
                                    isSend: true,
                                  ),
                                  ImportExcelPage(
                                    firstCollection: widget.contractData?.id ?? '',
                                    onFinished: () async {
                                      setState(() {
                                        _futureInit = _carregarDadosIniciais();
                                      });
                                    },
                                    onSave: (dados) async {
                                      final data = PaymentsRevisionsData.fromMap(dados);
                                      await _paymentRevisionBloc.saveOrUpdatePayment(data);
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  PaymentRevisionTableSection(
                                    onTapItem: (data) {
                                      final index = _paymentsRevisionData.indexOf(data);
                                      if (index != -1) {
                                        setState(() {
                                          _selectedPaymentRevisionData = data;
                                          _currentPaymentRevisionId = data.idRevisionPayment;
                                          _selectedLine = index;
                                        });
                                        _fillFields(data);
                                      }
                                    },
                                    onDelete: _deleteData,
                                    paymentsRevisionsData: _paymentsRevisionData,
                                    valorInicial: _valorInicial,
                                    valorAditivos: _valorAditivos,
                                    valorTotal: valorTotal,
                                    saldo: saldo,
                                    contractData: widget.contractData,
                                    selectedPaymentsRevisionsData: _selectedPaymentRevisionData,
                                  )
                                ],
                              ),
                            ),
                          );
                        }
                    ),
                  ),
                  const FootBar(),
                ],
              ),
              if (_isSaving)
                Stack(
                  children: [
                    ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
            ],
          );
        }
    );
  }


  @override
  void dispose() {
    removeValidation([
      _orderPaymentRevisionController,
      _processPaymentRevisionController,
      _valuePaymentRevisionController,
      _datePaymentRevisionController,
      _statePaymentRevisionController,
      _observationPaymentRevisionController,
      _bankPaymentRevisionController,
      _electronicTicketPaymentRevisionController,
      _fontPaymentRevisionController,
      _taxPaymentRevisionController,
    ], _validateForm);
    super.dispose();
  }
}
