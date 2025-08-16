// payments_revision_controller.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/sectors/financial/payments/payments_revision_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/additives/additives_bloc.dart';
import 'package:sisged/_blocs/system/user_bloc.dart';

import 'package:sisged/_provider/user/user_provider.dart';
import 'package:sisged/_datas/system/user_data.dart';

import 'package:sisged/_datas/documents/contracts/contracts/contracts_data.dart';
import 'package:sisged/_datas/sectors/financial/payments/payments_revisions_data.dart';

import 'package:sisged/_utils/date_utils.dart'
    show convertDateTimeToDDMMYYYY, convertDDMMYYYYToDateTime;
import 'package:sisged/_widgets/formats/format_field.dart'
    show parseCurrencyToDouble, priceToString;

class PaymentsRevisionController extends ChangeNotifier {
  // --- Blocs/Deps ---
  final PaymentsRevisionBloc paymentsBloc;
  final AdditivesBloc additivesBloc;
  final UserBloc userBloc;

  // --- Contexto do contrato (opcional) ---
  final ContractData? contract;

  PaymentsRevisionController({this.contract})
      : paymentsBloc = PaymentsRevisionBloc(),
        additivesBloc = AdditivesBloc(),
        userBloc = UserBloc();

  // --- Estado de tela/form ---
  bool isEditable = false;
  bool formValidated = false;
  bool isSaving = false;

  // --- Seleção ---
  PaymentsRevisionsData? selectedItem;
  String? currentPaymentRevisionId;

  // --- Dados/Paginação ---
  final int _itemsPerPage = 50;
  List<PaymentsRevisionsData> _universe = [];
  List<PaymentsRevisionsData> pageItems = [];
  int currentPage = 1;
  int totalPages = 1;

  // --- Totais ---
  double valorInicial = 0.0;
  double valorAditivos = 0.0;

  // --- Controllers de formulário ---
  final orderCtrl = TextEditingController();
  final processCtrl = TextEditingController();
  final valueCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final stateCtrl = TextEditingController();
  final observationCtrl = TextEditingController();
  final bankCtrl = TextEditingController();
  final electronicTicketCtrl = TextEditingController();
  final fontCtrl = TextEditingController();
  final taxCtrl = TextEditingController();

  // --- Getters úteis (gráfico e resumos) ---
  List<String> get chartLabels =>
      _universe.map((e) => (e.orderPaymentRevision ?? 0).toString()).toList();
  List<double> get chartValues =>
      _universe.map((e) => e.valuePaymentRevision ?? 0.0).toList();

  double get totalMedicoes =>
      chartValues.fold(0.0, (a, b) => a + b);

  double get valorTotal => valorInicial + valorAditivos;
  double get saldo => valorTotal - totalMedicoes;

  // ========== LIFECYCLE ==========
  Future<void> postFrameInit(BuildContext context) async {
    // Permissões
    try {
      final UserData? user =
          Provider.of<UserProvider>(context, listen: false).userData;
      if (user != null) {
        isEditable = userBloc.getUserCreateEditPermissions(userData: user);
      }
    } catch (_) {
      isEditable = false;
    }

    // Carrega dados do contrato (se houver)
    await _reloadAll();
  }

  @override
  void dispose() {
    orderCtrl.dispose();
    processCtrl.dispose();
    valueCtrl.dispose();
    dateCtrl.dispose();
    stateCtrl.dispose();
    observationCtrl.dispose();
    bankCtrl.dispose();
    electronicTicketCtrl.dispose();
    fontCtrl.dispose();
    taxCtrl.dispose();
    super.dispose();
  }

  // ========== LOAD / REFRESH ==========
  Future<void> _reloadAll() async {
    final id = contract?.id;
    if (id == null || id.isEmpty) {
      _universe = [];
      _refreshPagination();
      return;
    }

    valorInicial = contract?.initialValueContract ?? 0.0;
    valorAditivos = await additivesBloc.getAllAdditivesValue(id);

    _universe = await paymentsBloc.getAllReportPaymentsOfContract(
      contractId: id,
    );

    // Sugerir próxima ordem
    final lastOrder = _universe.isNotEmpty
        ? _universe
        .map((e) => e.orderPaymentRevision ?? 0)
        .reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (lastOrder + 1).toString();

    currentPage = 1;
    _refreshPagination();
  }

  void _refreshPagination() {
    final total = _universe.length;
    totalPages = (total == 0) ? 1 : ((total - 1) ~/ _itemsPerPage + 1);
    final start = (currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > total) ? total : (start + _itemsPerPage);
    pageItems = (start < end) ? _universe.sublist(start, end) : [];
    notifyListeners();
  }

  Future<void> loadPage(int page) async {
    if (page < 1 || page > totalPages) return;
    currentPage = page;
    _refreshPagination();
  }

  // ========== TABLE -> FORM ==========
  void selectFromTable(PaymentsRevisionsData item, int indexInPage) {
    selectedItem = item;
    currentPaymentRevisionId = item.idRevisionPayment;

    orderCtrl.text = (item.orderPaymentRevision ?? '').toString();
    processCtrl.text = item.processPaymentRevision ?? '';
    valueCtrl.text = priceToString(item.valuePaymentRevision);
    dateCtrl.text = item.datePaymentRevision != null
        ? convertDateTimeToDDMMYYYY(item.datePaymentRevision!)
        : '';
    stateCtrl.text = item.statePaymentRevision ?? '';
    observationCtrl.text = item.observationPaymentRevision ?? '';
    bankCtrl.text = item.orderBankPaymentRevision ?? '';
    electronicTicketCtrl.text = item.electronicTicketPaymentRevision ?? '';
    fontCtrl.text = item.fontPaymentRevision ?? '';
    taxCtrl.text = priceToString(item.taxPaymentRevision);

    _revalidate();
    notifyListeners();
  }

  void createNew() {
    selectedItem = null;
    currentPaymentRevisionId = null;

    processCtrl.clear();
    valueCtrl.clear();
    dateCtrl.clear();
    stateCtrl.clear();
    observationCtrl.clear();
    bankCtrl.clear();
    electronicTicketCtrl.clear();
    fontCtrl.clear();
    taxCtrl.clear();

    // próxima ordem sugerida
    final lastOrder = _universe.isNotEmpty
        ? _universe
        .map((e) => e.orderPaymentRevision ?? 0)
        .reduce((a, b) => a > b ? a : b)
        : 0;
    orderCtrl.text = (lastOrder + 1).toString();

    _revalidate();
    notifyListeners();
  }

  // ========== SAVE / DELETE ==========
  Future<void> saveOrUpdate(BuildContext context) async {
    final idContract = contract?.id;
    if (idContract == null || idContract.isEmpty) {
      _snack(context, 'Contrato inválido.');
      return;
    }

    // validação simples
    _revalidate();
    if (!formValidated) {
      _snack(context, 'Preencha os campos obrigatórios.');
      return;
    }

    final ok = await confirm(context, 'Deseja salvar este pagamento de reajuste?');
    if (ok != true) return;

    isSaving = true;
    notifyListeners();

    try {
      final model = PaymentsRevisionsData(
        contractId: idContract,
        idRevisionPayment: currentPaymentRevisionId,
        orderPaymentRevision: int.tryParse(orderCtrl.text.trim()),
        processPaymentRevision: _nz(processCtrl.text),
        valuePaymentRevision: parseCurrencyToDouble(valueCtrl.text),
        datePaymentRevision: convertDDMMYYYYToDateTime(dateCtrl.text),
        statePaymentRevision: _nz(stateCtrl.text),
        observationPaymentRevision: _nz(observationCtrl.text),
        orderBankPaymentRevision: _nz(bankCtrl.text),
        electronicTicketPaymentRevision: _nz(electronicTicketCtrl.text),
        fontPaymentRevision: _nz(fontCtrl.text),
        taxPaymentRevision: parseCurrencyToDouble(taxCtrl.text),
      );

      await paymentsBloc.saveOrUpdatePayment(model);

      // recarrega, reposiciona e limpa form
      await _reloadAll();
      _snack(context, 'Pagamento salvo com sucesso.');
      createNew();
    } catch (e) {
      _snack(context, 'Erro ao salvar: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deletePayment(BuildContext context, String idPaymentRevision) async {
    final idContract = contract?.id;
    if (idContract == null || idContract.isEmpty) return;

    final ok = await confirm(context, 'Deseja apagar este pagamento de reajuste?');
    if (ok != true) return;

    isSaving = true;
    notifyListeners();

    try {
      await paymentsBloc.deletarPayment(idContract, idPaymentRevision);
      await _reloadAll();
      if (currentPaymentRevisionId == idPaymentRevision) createNew();
      _snack(context, 'Pagamento de reajuste removido.');
    } catch (e) {
      _snack(context, 'Erro ao remover: $e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  // ========== HELPERS ==========
  void _revalidate() {
    final requiredFilled =
        orderCtrl.text.trim().isNotEmpty &&
            processCtrl.text.trim().isNotEmpty &&
            valueCtrl.text.trim().isNotEmpty &&
            dateCtrl.text.trim().isNotEmpty;
    if (formValidated != requiredFilled) {
      formValidated = requiredFilled;
    }
  }

  String? _nz(String? s) {
    final t = (s ?? '').trim();
    return t.isEmpty ? null : t;
  }

  Future<bool> confirm(BuildContext context, String message) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    return res ?? false;
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
