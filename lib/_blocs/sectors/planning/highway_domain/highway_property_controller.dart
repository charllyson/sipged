import 'dart:async';
import 'package:flutter/material.dart';
import 'package:siged/_blocs/sectors/planning/highway_domain/highway_property_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'right_way_properties_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

class RightWayPropertyController extends ChangeNotifier with FormValidationMixin {
  final ContractData contract;
  final RightWayPropertiesStore store;

  RightWayPropertyController({
    required this.contract,
    required this.store,
  }) {
    _init();
  }

  // state
  late Future<List<RightWayPropertyData>> futureProps;
  List<RightWayPropertyData> _snapshot = [];
  RightWayPropertyData? selected;
  String? currentId;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = true; // ajuste com seu UserBloc se desejar

  // controllers
  final ownerCtrl = TextEditingController();
  final cpfCnpjCtrl = TextEditingController();
  final typeCtrl = TextEditingController();     // URBANO/RURAL
  final statusCtrl = TextEditingController();   // A NEGOCIAR/INDENIZADO/JUDICIALIZADO

  final registryCtrl = TextEditingController();
  final officeCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final cityCtrl = TextEditingController();
  final ufCtrl = TextEditingController();

  final processCtrl = TextEditingController();
  final notifDateCtrl = TextEditingController();
  final inspDateCtrl = TextEditingController();
  final agreeDateCtrl = TextEditingController();

  final totalAreaCtrl = TextEditingController();
  final affectedAreaCtrl = TextEditingController();
  final indemnityCtrl = TextEditingController();

  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  Future<void> _init() async {
    futureProps = _getAll();
    setupValidation(
      [
        ownerCtrl, cpfCnpjCtrl, typeCtrl, statusCtrl,
        cityCtrl, ufCtrl,
      ],
      _validate,
    );
  }

  Future<List<RightWayPropertyData>> _getAll() async {
    if (contract.id == null) return [];
    await store.ensureFor(contract.id!);
    return store.listFor(contract.id!);
  }

  void _validate() {
    final obrig = <TextEditingController>[
      ownerCtrl, cpfCnpjCtrl, typeCtrl, statusCtrl, cityCtrl, ufCtrl
    ];
    final valid = areFieldsFilled(obrig, minLength: 1);
    if (valid != formValidated) {
      formValidated = valid;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    if (contract.id == null) return;
    await store.refreshFor(contract.id!);
    futureProps = Future.value(store.listFor(contract.id!));
    notifyListeners();
  }

  void applySnapshot(List<RightWayPropertyData> list) {
    _snapshot = list;
  }

  void fillFields(RightWayPropertyData p) {
    selected = p;
    editingMode = true;
    currentId = p.id;

    ownerCtrl.text = p.ownerName ?? '';
    cpfCnpjCtrl.text = p.cpfCnpj ?? '';
    typeCtrl.text = p.propertyType ?? '';
    statusCtrl.text = p.status ?? '';

    registryCtrl.text = p.registryNumber ?? '';
    officeCtrl.text = p.registryOffice ?? '';
    addressCtrl.text = p.address ?? '';
    cityCtrl.text = p.city ?? '';
    ufCtrl.text = p.state ?? '';

    processCtrl.text = p.processNumber ?? '';
    notifDateCtrl.text = p.notificationDate != null ? dateTimeToDDMMYYYY(p.notificationDate!) : '';
    inspDateCtrl.text = p.inspectionDate != null ? dateTimeToDDMMYYYY(p.inspectionDate!) : '';
    agreeDateCtrl.text = p.agreementDate != null ? dateTimeToDDMMYYYY(p.agreementDate!) : '';

    totalAreaCtrl.text = doubleToString(p.totalArea);
    affectedAreaCtrl.text = doubleToString(p.affectedArea);
    indemnityCtrl.text = priceToString(p.indemnityValue);

    phoneCtrl.text = p.phone ?? '';
    emailCtrl.text = p.email ?? '';
    notesCtrl.text = p.notes ?? '';

    _validate();
    notifyListeners();
  }

  void clearForm() {
    editingMode = false;
    currentId = null;
    selected = null;

    for (final c in [
      ownerCtrl, cpfCnpjCtrl, typeCtrl, statusCtrl, registryCtrl, officeCtrl,
      addressCtrl, cityCtrl, ufCtrl, processCtrl, notifDateCtrl, inspDateCtrl,
      agreeDateCtrl, totalAreaCtrl, affectedAreaCtrl, indemnityCtrl,
      phoneCtrl, emailCtrl, notesCtrl
    ]) { c.clear(); }

    _validate();
    notifyListeners();
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^\d]'), '');
  double? _toDouble(String s) => stringToDouble(s);

  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;
    isSaving = true; notifyListeners();
    try {
      final novo = RightWayPropertyData(
        id: currentId,
        contractId: contract.id,
        ownerName: ownerCtrl.text.trim(),
        cpfCnpj: _onlyDigits(cpfCnpjCtrl.text),
        propertyType: typeCtrl.text,
        status: statusCtrl.text,
        registryNumber: registryCtrl.text.trim(),
        registryOffice: officeCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: ufCtrl.text.trim().toUpperCase(),
        processNumber: processCtrl.text.trim(),
        notificationDate: convertDDMMYYYYToDateTime(notifDateCtrl.text),
        inspectionDate: convertDDMMYYYYToDateTime(inspDateCtrl.text),
        agreementDate: convertDDMMYYYYToDateTime(agreeDateCtrl.text),
        totalArea: _toDouble(totalAreaCtrl.text),
        affectedArea: _toDouble(affectedAreaCtrl.text),
        indemnityValue: _toDouble(indemnityCtrl.text),
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      );

      await store.saveOrUpdate(contract.id!, novo);
      await reload();
      clearForm();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(editingMode ? 'Imóvel atualizado!' : 'Imóvel cadastrado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      isSaving = false; notifyListeners();
    }
  }

  Future<void> delete(BuildContext context, String id) async {
    if (contract.id == null) return;
    await store.delete(contract.id!, id);
    await reload();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imóvel removido.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    removeValidation([
      ownerCtrl, cpfCnpjCtrl, typeCtrl, statusCtrl, cityCtrl, ufCtrl
    ], _validate);
    for (final c in [
      ownerCtrl, cpfCnpjCtrl, typeCtrl, statusCtrl, registryCtrl, officeCtrl,
      addressCtrl, cityCtrl, ufCtrl, processCtrl, notifDateCtrl, inspDateCtrl,
      agreeDateCtrl, totalAreaCtrl, affectedAreaCtrl, indemnityCtrl,
      phoneCtrl, emailCtrl, notesCtrl
    ]) { c.dispose(); }
    super.dispose();
  }
}
