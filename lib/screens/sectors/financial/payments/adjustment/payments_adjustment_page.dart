import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';
import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_utils/date_utils.dart' show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;
import 'package:sisged/_widgets/formats/format_field.dart';
import 'package:sisged/screens/commons/footBar/foot_bar.dart';
import 'package:sisged/screens/sectors/financial/payments/adjustment/payment_adjustment_chart_section.dart';
import 'package:sisged/screens/sectors/financial/payments/adjustment/payment_adjustment_form_section.dart';
import 'package:sisged/screens/sectors/financial/payments/adjustment/payment_adjustment_table_section.dart';

import '../../../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../../../_blocs/sectors/financial/payments/payments_adjustment_bloc.dart';
import '../../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../../_datas/sectors/financial/payments/payments_adjustments_data.dart';
import '../../../../../_datas/system/user_data.dart';
import '../../../../../../_widgets/texts/divider_text.dart';
import '../../../../../../_widgets/validates/form_validation_mixin.dart';
import '../../../../../admPanel/converters/importExcel/import_excel_page.dart';

class PaymentsAdjustmentPage extends StatefulWidget {
  const PaymentsAdjustmentPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<PaymentsAdjustmentPage> createState() => _PaymentsAdjustmentPageState();
}

class _PaymentsAdjustmentPageState extends State<PaymentsAdjustmentPage>
    with FormValidationMixin {
  late PaymentsAdjustmentBloc _paymentAdjustmentBloc;
  late UserBloc _userBloc;
  late AdditivesBloc _additivesBloc;
  late UserData _currentUser;

  late Future<void> _futureInit;

  List<PaymentsAdjustmentsData> _paymentsAdjustmentData = [];
  PaymentsAdjustmentsData? _selectedAdjustmentPaymentData;

  double _valorInicial = 0.0;
  double _valorAditivos = 0.0;

  int? _selectedLine;
  String? _currentPaymentAdjustmentId;
  bool _formValidated = false;
  bool _isEditable = false;
  bool _isSaving = false;

  final _orderPaymentAdjustmentController = TextEditingController();
  final _processPaymentAdjustmentController = TextEditingController();
  final _valuePaymentAdjustmentController = TextEditingController();
  final _datePaymentAdjustmentController = TextEditingController();
  final _statePaymentAdjustmentController = TextEditingController();
  final _observationPaymentAdjustmentController = TextEditingController();
  final _bankPaymentAdjustmentController = TextEditingController();
  final _electronicTicketPaymentAdjustmentController = TextEditingController();
  final _fontPaymentAdjustmentController = TextEditingController();
  final _taxPaymentAdjustmentController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _paymentAdjustmentBloc = PaymentsAdjustmentBloc();
    _userBloc = UserBloc();
    _additivesBloc = AdditivesBloc();
    _currentUser = Provider.of<UserProvider>(context, listen: false).userData!;

    final user = _currentUser;
    _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);

    setupValidation([
      _orderPaymentAdjustmentController,
      _processPaymentAdjustmentController,
      _valuePaymentAdjustmentController,
      _datePaymentAdjustmentController,
    ], _validateForm);

    _futureInit = _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    if (widget.contractData?.id == null) return;

    _valorInicial = widget.contractData?.initialValueContract ?? 0.0;
    _valorAditivos = await _additivesBloc.getAllAdditivesValue(widget.contractData!.id!);
    _paymentsAdjustmentData = await _paymentAdjustmentBloc.getAllAdjustmentPaymentsOfContract(contractId: widget.contractData!.id!);

    final ultimaOrdem = _paymentsAdjustmentData.isNotEmpty
        ? _paymentsAdjustmentData.map((e) => e.orderPaymentAdjustment ?? 0).reduce((a, b) => a > b ? a : b)
        : 0;
    _orderPaymentAdjustmentController.text = (ultimaOrdem + 1).toString();
  }

  void _validateForm() {
    final valid = areFieldsFilled([
      _orderPaymentAdjustmentController,
      _processPaymentAdjustmentController,
      _valuePaymentAdjustmentController,
      _datePaymentAdjustmentController,
    ], minLength: 1);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }

  void _fillFields(PaymentsAdjustmentsData data) {
    setState(() {
      _selectedAdjustmentPaymentData = data;
      _currentPaymentAdjustmentId = data.idPaymentAdjustment;
      _orderPaymentAdjustmentController.text = data.orderPaymentAdjustment.toString();
      _processPaymentAdjustmentController.text = data.processPaymentAdjustment ?? '';
      _valuePaymentAdjustmentController.text = priceToString(data.valuePaymentAdjustment);
      _datePaymentAdjustmentController.text = convertDateTimeToDDMMYYYY(data.datePaymentAdjustment!);
      _statePaymentAdjustmentController.text = data.statePaymentAdjustment ?? '';
      _observationPaymentAdjustmentController.text = data.observationPaymentAdjustment ?? '';
      _bankPaymentAdjustmentController.text = data.orderBankPaymentAdjustment ?? '';
      _electronicTicketPaymentAdjustmentController.text = data.electronicTicketPaymentAdjustment ?? '';
      _fontPaymentAdjustmentController.text = data.fontPaymentAdjustment ?? '';
      _taxPaymentAdjustmentController.text = priceToString(data.taxPaymentAdjustment);
    });
  }


  void _createNew() {
    final lastPaymentAdjustment = _paymentsAdjustmentData.map((e) => e.orderPaymentAdjustment ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _selectedLine = null;
      _orderPaymentAdjustmentController.text = (lastPaymentAdjustment + 1).toString();
      _processPaymentAdjustmentController.clear();
      _valuePaymentAdjustmentController.clear();
      _datePaymentAdjustmentController.clear();
      _statePaymentAdjustmentController.clear();
      _observationPaymentAdjustmentController.clear();
      _bankPaymentAdjustmentController.clear();
      _electronicTicketPaymentAdjustmentController.clear();
      _fontPaymentAdjustmentController.clear();
      _taxPaymentAdjustmentController.clear();
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

    final newPayment = PaymentsAdjustmentsData(
      idPaymentAdjustment: _currentPaymentAdjustmentId,
      contractId: widget.contractData!.id!,
      orderPaymentAdjustment: int.tryParse(_orderPaymentAdjustmentController.text),
      processPaymentAdjustment: _processPaymentAdjustmentController.text,
      valuePaymentAdjustment: parseCurrencyToDouble(_valuePaymentAdjustmentController.text),
      datePaymentAdjustment: convertDDMMYYYYToDateTime(_datePaymentAdjustmentController.text),
      statePaymentAdjustment: _statePaymentAdjustmentController.text,
      observationPaymentAdjustment: _observationPaymentAdjustmentController.text,
      orderBankPaymentAdjustment: _bankPaymentAdjustmentController.text,
      electronicTicketPaymentAdjustment: _electronicTicketPaymentAdjustmentController.text,
      fontPaymentAdjustment: _fontPaymentAdjustmentController.text,
      taxPaymentAdjustment: parseCurrencyToDouble(_taxPaymentAdjustmentController.text),
    );

    await _paymentAdjustmentBloc.saveOrUpdatePayment(newPayment);

    _paymentsAdjustmentData = await _paymentAdjustmentBloc.getAllAdjustmentPaymentsOfContract(contractId: widget.contractData!.id!);
    _createNew();

    setState(() => _isSaving = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pagamento salvo com sucesso!'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
    );
  }

  void _deleteData(String idPaymentAdjustment) async {
    if (widget.contractData?.id == null) return;
    await _paymentAdjustmentBloc.deletarPayment(widget.contractData!.id!, idPaymentAdjustment);
    _paymentsAdjustmentData = await _paymentAdjustmentBloc.getAllAdjustmentPaymentsOfContract(contractId: widget.contractData!.id!);
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
          final labels = _paymentsAdjustmentData.map((m) => (m.orderPaymentAdjustment ?? 0).toString()).toList();
          final values = _paymentsAdjustmentData.map((m) => m.valuePaymentAdjustment ?? 0.0).toList();
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
                                PaymentsAdjustmentChartsSection(
                                  labels: labels,
                                  values: values,
                                  valorTotal: valorTotal,
                                  totalMedicoes: totalMedicoes,
                                  selectedIndex: _selectedLine,
                                  onSelectIndex: (index) {
                                    setState(() {
                                      _selectedLine = index;
                                      _fillFields(_selectedAdjustmentPaymentData!);
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                DividerText(title: 'Cadastrar pagamento de reajuste no sistema'),
                                const SizedBox(height: 12),
                                PaymentAdjustmentFormSection(
                                    orderPaymentAdjustmentController: _orderPaymentAdjustmentController,
                                    processPaymentAdjustmentController: _processPaymentAdjustmentController,
                                    valuePaymentAdjustmentController: _valuePaymentAdjustmentController,
                                    statePaymentAdjustmentController: _statePaymentAdjustmentController,
                                    observationPaymentAdjustmentController: _observationPaymentAdjustmentController,
                                    bankPaymentAdjustmentController: _bankPaymentAdjustmentController,
                                    electronicTicketPaymentAdjustmentController: _electronicTicketPaymentAdjustmentController,
                                    fontPaymentAdjustmentController: _fontPaymentAdjustmentController,
                                    datePaymentAdjustmentController: _datePaymentAdjustmentController,
                                    taxPaymentAdjustmentController: _taxPaymentAdjustmentController,
                                    selectedPaymentsAdjustmentData: _selectedAdjustmentPaymentData,
                                    isEditable: _isEditable,
                                    isSaving: _isSaving,
                                    formValidated: _formValidated,
                                    onSaveOrUpdate: _saveOrUpdate,
                                    contractData: widget.contractData,
                                    paymentAdjustmentBloc: _paymentAdjustmentBloc,
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
                                      _futureInit = _carregarDadosIniciais(); // 🔄 recarrega a lista
                                    });
                                  },
                                  onSave: (dados) async {
                                    final data = PaymentsAdjustmentsData.fromMap(dados);
                                    await _paymentAdjustmentBloc.saveOrUpdatePayment(data);
                                  },
                                ),
                                const SizedBox(height: 12),
                                PaymentAdjustmentTableSection(
                                  onTapItem: (data) {
                                    final index = _paymentsAdjustmentData.indexOf(data);
                                    if (index != -1) {
                                      setState(() {
                                        _selectedAdjustmentPaymentData = data;
                                        _currentPaymentAdjustmentId = data.idPaymentAdjustment;
                                        _selectedLine = index;
                                      });
                                      _fillFields(data);
                                    }
                                  },
                                  onDelete: _deleteData,
                                  paymentAdjustmentData: _paymentsAdjustmentData,
                                  valorInicial: _valorInicial,
                                  valorAditivos: _valorAditivos,
                                  valorTotal: valorTotal,
                                  saldo: saldo,
                                  contractData: widget.contractData,
                                  selectedPaymentAdjustment: _selectedAdjustmentPaymentData,
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
      _orderPaymentAdjustmentController,
      _processPaymentAdjustmentController,
      _valuePaymentAdjustmentController,
      _datePaymentAdjustmentController,
      _statePaymentAdjustmentController,
      _observationPaymentAdjustmentController,
      _bankPaymentAdjustmentController,
      _electronicTicketPaymentAdjustmentController,
      _fontPaymentAdjustmentController,
      _taxPaymentAdjustmentController,
    ], _validateForm);
    super.dispose();
  }
}
