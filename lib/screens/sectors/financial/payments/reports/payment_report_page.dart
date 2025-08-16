import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart' show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/sectors/financial/payments/reports/payment_report_chart_section.dart';
import 'package:sisged/screens/sectors/financial/payments/reports/payment_report_form_section.dart';
import 'package:sisged/screens/sectors/financial/payments/reports/payment_report_table_section.dart';

import '../../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../../_blocs/sectors/financial/payments/payments_reports_bloc.dart';
import '../../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../../_datas/documents/measurement/measurement_data.dart';
import '../../../../../_datas/sectors/financial/payments/payments_reports_data.dart';
import '../../../../../_datas/system/user_data.dart';
import '../../../../../../_widgets/texts/divider_text.dart';
import '../../../../../../_widgets/validates/form_validation_mixin.dart';
import '../../../../../admPanel/converters/importExcel/import_excel_page.dart';

class PaymentsReportPage extends StatefulWidget {
  const PaymentsReportPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<PaymentsReportPage> createState() => _PaymentsReportPageState();
}

class _PaymentsReportPageState extends State<PaymentsReportPage> with FormValidationMixin {
  late PaymentsReportBloc _paymentReportBloc;
  late UserBloc _userBloc;
  late AdditivesBloc _additivesBloc;
  late UserData _currentUser;

  late Future<void> _futureInit;

  List<PaymentsReportData> _paymentReportData = [];
  final List<ReportData> _reportData = [];


  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  int? _selectedLine;
  String? _currentPaymentReportId;
  bool _formValidated = false;
  bool _isEditable = false;
  bool _isSaving = false;

  final _orderPaymentReportController = TextEditingController();
  final _processPaymentReportController = TextEditingController();
  final _valuePaymentReportController = TextEditingController();
  final _datePaymentReportController = TextEditingController();
  final _statePaymentReportController = TextEditingController();
  final _observationPaymentReportController = TextEditingController();
  final _bankPaymentReportController = TextEditingController();
  final _electronicTicketPaymentReportController = TextEditingController();
  final _fontPaymentReportController = TextEditingController();
  final _taxPaymentReportController = TextEditingController();

  PaymentsReportData? _selectedPaymentReport;

  @override
  void initState() {
    super.initState();
    _paymentReportBloc = PaymentsReportBloc();
    _userBloc = UserBloc();
    _additivesBloc = AdditivesBloc();
    _currentUser = Provider.of<UserProvider>(context, listen: false).userData!;

    final user = _currentUser;
    _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);

    setupValidation([
      _orderPaymentReportController,
      _processPaymentReportController,
      _valuePaymentReportController,
      _datePaymentReportController,
    ], _validateForm);

    _futureInit = _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    if (widget.contractData?.id == null) return;

    _valorInicial = widget.contractData?.initialValueContract ?? 0.0;
    _valorAditivos = await _additivesBloc.getAllAdditivesValue(widget.contractData!.id!);
    _paymentReportData = await _paymentReportBloc.getAllReportPaymentsOfContract(contractId: widget.contractData!.id!);

    final ultimaOrdem = _paymentReportData.isNotEmpty
        ? _paymentReportData.map((e) => e.orderPaymentReport ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    _orderPaymentReportController.text = (ultimaOrdem + 1).toString();
  }

  void _validateForm() {
    final valid = areFieldsFilled([
      _orderPaymentReportController,
      _processPaymentReportController,
      _valuePaymentReportController,
      _datePaymentReportController,
    ], minLength: 1);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }

  void _fillFields(PaymentsReportData data) {
    setState(() {
      _selectedPaymentReport = data;
      _currentPaymentReportId = data.idPaymentReport;
      _orderPaymentReportController.text = data.orderPaymentReport.toString();
      _processPaymentReportController.text = data.processPaymentReport ?? '';
      _valuePaymentReportController.text = priceToString(data.valuePaymentReport);
      _datePaymentReportController.text = convertDateTimeToDDMMYYYY(data.datePaymentReport!);
      _statePaymentReportController.text = data.statePaymentReport ?? '';
      _observationPaymentReportController.text = data.observationPaymentReport ?? '';
      _bankPaymentReportController.text = data.orderBankPaymentReport ?? '';
      _electronicTicketPaymentReportController.text = data.electronicTicketPaymentReport ?? '';
      _fontPaymentReportController.text = data.fontPaymentReport ?? '';
      _taxPaymentReportController.text = priceToString(data.taxPaymentReport);
    });
  }


  void _createNew() {
    final lastPaymentReport = _paymentReportData.map((e) => e.orderPaymentReport ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _selectedLine = null;
      _orderPaymentReportController.text = (lastPaymentReport + 1).toString();
      _processPaymentReportController.clear();
      _valuePaymentReportController.clear();
      _datePaymentReportController.clear();
      _statePaymentReportController.clear();
      _observationPaymentReportController.clear();
      _bankPaymentReportController.clear();
      _electronicTicketPaymentReportController.clear();
      _fontPaymentReportController.clear();
      _taxPaymentReportController.clear();
    });
  }

  void _saveOrUpdate() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja salvar esta medição?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isSaving = true);

    final newPayment = PaymentsReportData(
      idPaymentReport: _currentPaymentReportId,
      contractId: widget.contractData!.id!,
      orderPaymentReport: int.tryParse(_orderPaymentReportController.text),
      processPaymentReport: _processPaymentReportController.text,
      valuePaymentReport: parseCurrencyToDouble(_valuePaymentReportController.text),
      datePaymentReport: convertDDMMYYYYToDateTime(_datePaymentReportController.text),
      statePaymentReport: _statePaymentReportController.text,
      observationPaymentReport: _observationPaymentReportController.text,
      orderBankPaymentReport: _bankPaymentReportController.text,
      electronicTicketPaymentReport: _electronicTicketPaymentReportController.text,
      fontPaymentReport: _fontPaymentReportController.text,
      taxPaymentReport: parseCurrencyToDouble(_taxPaymentReportController.text),
    );

    await _paymentReportBloc.saveOrUpdatePayment(newPayment);

    _paymentReportData = await _paymentReportBloc.getAllReportPaymentsOfContract(contractId: widget.contractData!.id!);
    _createNew();

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pagamento salvo com sucesso!'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
    );
  }

  void _deleteData(String idPaymentReport) async {
    if (widget.contractData?.id == null) return;
    await _paymentReportBloc.deletarPayment(widget.contractData!.id!, idPaymentReport);
    _paymentReportData = await _paymentReportBloc.getAllReportPaymentsOfContract(contractId: widget.contractData!.id!);
    setState(() => _selectedLine = null);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medição apagada com sucesso.'), backgroundColor: Colors.red),
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
        final labels = _paymentReportData.map((m) => (m.orderPaymentReport ?? 0).toString()).toList();
        final values = _paymentReportData.map((m) => m.valuePaymentReport ?? 0.0).toList();
        final totalMedicoes = values.fold(0.0, (a, b) => a + b);
        final valorTotal = _valorInicial + _valorAditivos;
        final saldo = valorTotal - totalMedicoes;

        return Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        DividerText(title: 'Gráfico dos pagamentos'),
                        const SizedBox(height: 12),
                        PaymentsReportChartsSection(
                          labels: labels,
                          values: values,
                          valorTotal: valorTotal,
                          totalMedicoes: totalMedicoes,
                          selectedIndex: _selectedLine,
                          onSelectIndex: (index) {
                            setState(() {
                              _selectedLine = index;
                              if (index >= 0 && index < _paymentReportData.length) {
                                _fillFields(_paymentReportData[index]);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        DividerText(title: 'Cadastrar pagamento no sistema'),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: PaymentReportFormSection(
                            isSaving: _isSaving,
                            selectedPaymentReportData: _selectedPaymentReport,
                            currentPaymentReportId: _currentPaymentReportId,
                            contractData: widget.contractData!,
                            orderPaymentReportController: _orderPaymentReportController,
                            processNumberPaymentReportController: _processPaymentReportController,
                            datePaymentReportController: _datePaymentReportController,
                            valuePaymentReportController: _valuePaymentReportController,
                            statePaymentReportController: _statePaymentReportController,
                            observationPaymentReportController: _observationPaymentReportController,
                            bankPaymentReportController: _bankPaymentReportController,
                            electronicTicketPaymentReportController: _electronicTicketPaymentReportController,
                            fontPaymentReportController: _fontPaymentReportController,
                            taxPaymentReportController: _taxPaymentReportController,
                            isEditable: _isEditable,
                            formValidated: _formValidated,
                            onSaveOrUpdate: _saveOrUpdate,
                            onClear: () async {
                              setState(() {
                                _currentPaymentReportId = null;
                                _selectedPaymentReport = null;
                                _selectedLine = null;
                              });
                              _createNew();
                            },
                            onUploadSaveToFirestore: (url) async {
                              if (_selectedPaymentReport?.idPaymentReport == null) return;
                              await _paymentReportBloc.salvarUrlPdfDePayment(
                                contractId: widget.contractData!.id!,
                                paymentId: _selectedPaymentReport!.idPaymentReport!,
                                url: url,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        DividerText(title: 'Pagamentos cadastrados no sistema',isSend: true),
                        ImportExcelPage(
                          firstCollection: widget.contractData?.id ?? '',
                          onFinished: () async {
                            setState(() {
                              _futureInit = _carregarDadosIniciais(); // 🔄 recarrega a lista
                            });
                          },
                          onSave: (dados) async {
                            final data = PaymentsReportData.fromMap(dados);
                            await _paymentReportBloc.saveOrUpdatePayment(data);
                          },
                        ),
                        const SizedBox(height: 12),
                        PaymentReportTableSection(
                          onTapItem: (data) {
                            final index = _paymentReportData.indexOf(data);
                            if (index != -1) {
                              setState(() {
                                _selectedPaymentReport = data;
                                _currentPaymentReportId = data.idPaymentReport;
                                _selectedLine = index;
                              });
                              _fillFields(data);
                            }
                          },
                          onDelete: _deleteData,
                          paymentReportData: _paymentReportData,
                          reportData: _reportData,
                          valorInicial: _valorInicial,
                          valorAditivos: _valorAditivos,
                          valorTotal: valorTotal,
                          saldo: saldo,
                          contractData: widget.contractData,
                          selectedPaymentReport: _selectedPaymentReport,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
      },
    );
  }


  @override
  void dispose() {
    removeValidation([
      _orderPaymentReportController,
      _processPaymentReportController,
      _valuePaymentReportController,
      _datePaymentReportController,
      _statePaymentReportController,
      _observationPaymentReportController,
      _bankPaymentReportController,
      _electronicTicketPaymentReportController,
      _fontPaymentReportController,
      _taxPaymentReportController,
    ], _validateForm);
    super.dispose();
  }
}
