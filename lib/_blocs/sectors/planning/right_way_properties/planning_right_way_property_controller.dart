import 'dart:async';
import 'package:flutter/material.dart';
import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_storage_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_blocs/sectors/planning/right_way_properties/planning_right_way_property_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/date_utils.dart';
import 'package:siged/_utils/formats/format_field.dart';
import '../../../system/user/user_data.dart';
import 'planning_right_way_property_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';

class PlanningRightWayPropertyController extends ChangeNotifier
    with FormValidationMixin {
  final ContractData contract;
  final PlanningRightWayPropertyStore store;
  final PlanningRightWayPropertyStorageBloc storage;

  /// Notificador para o mapa: cada incremento sinaliza “recarregue geometrias”.
  /// Passe isso ao widget do mapa como `refreshListenable`.
  final ValueNotifier<int> mapRefresh = ValueNotifier<int>(0);

  PlanningRightWayPropertyController({
    required this.contract,
    required this.store,
    PlanningRightWayPropertyStorageBloc? storageBloc,
  }) : storage = storageBloc ?? PlanningRightWayPropertyStorageBloc() {
    _init();
  }

  // state
  late Future<List<PlanningRightWayPropertyData>> futureProps;
  List<PlanningRightWayPropertyData> _snapshot = [];
  PlanningRightWayPropertyData? selected;
  String? currentId;
  UserData? currentUser;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = true; // ajuste com UserBloc se desejar

  // arquivos: GEO (kml/kmz/geojson) + DOCS (pdfs)
  List<String> geoNames = [];
  List<String> geoUrls = [];
  int? selectedGeoIndex;

  List<String> docNames = [];
  List<String> docUrls = [];
  int? selectedDocIndex;

  // controllers
  final ownerCtrl = TextEditingController();
  final cpfCnpjCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final statusCtrl = TextEditingController();

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

  bool get isAdmin =>
      (currentUser?.baseProfile ?? '').trim().toLowerCase() == 'administrador';

  Future<void> _init() async {
    futureProps = _getAll();
    // ✅ Somente proprietário, matrícula e status são obrigatórios
    setupValidation(
      [ownerCtrl, registryCtrl, statusCtrl],
      _validate,
    );
  }

  Future<List<PlanningRightWayPropertyData>> _getAll() async {
    if (contract.id == null) return [];
    await store.ensureFor(contract.id!);
    return store.listFor(contract.id!);
  }

  void _validate() {
    final obrig = <TextEditingController>[
      ownerCtrl, registryCtrl, statusCtrl,
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

  void applySnapshot(List<PlanningRightWayPropertyData> list) {
    _snapshot = list;
  }

  // ====== Seleção / Preenchimento ===========================================
  void fillFields(PlanningRightWayPropertyData p) {
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
    notifDateCtrl.text =
    p.notificationDate != null ? dateTimeToDDMMYYYY(p.notificationDate!) : '';
    inspDateCtrl.text =
    p.inspectionDate != null ? dateTimeToDDMMYYYY(p.inspectionDate!) : '';
    agreeDateCtrl.text =
    p.agreementDate != null ? dateTimeToDDMMYYYY(p.agreementDate!) : '';

    totalAreaCtrl.text = doubleToString(p.totalArea);
    affectedAreaCtrl.text = doubleToString(p.affectedArea);
    indemnityCtrl.text = priceToString(p.indemnityValue);

    phoneCtrl.text = p.phone ?? '';
    emailCtrl.text = p.email ?? '';
    notesCtrl.text = p.notes ?? '';

    _validate();

    _loadFilesForCurrentProperty(); // <- carrega GEO + DOCS
    notifyListeners();
  }

  void clearForm() {
    editingMode = false;
    currentId = null;
    selected = null;

    for (final c in [
      ownerCtrl,
      cpfCnpjCtrl,
      typeCtrl,
      statusCtrl,
      registryCtrl,
      officeCtrl,
      addressCtrl,
      cityCtrl,
      ufCtrl,
      processCtrl,
      notifDateCtrl,
      inspDateCtrl,
      agreeDateCtrl,
      totalAreaCtrl,
      affectedAreaCtrl,
      indemnityCtrl,
      phoneCtrl,
      emailCtrl,
      notesCtrl
    ]) {
      c.clear();
    }

    // limpa listas de arquivos
    geoNames.clear();
    geoUrls.clear();
    selectedGeoIndex = null;
    docNames.clear();
    docUrls.clear();
    selectedDocIndex = null;

    _validate();
    notifyListeners();
  }

  String _onlyDigits(String s) => s.replaceAll(RegExp(r'[^\d]'), '');
  double? _toDouble(String s) => stringToDouble(s);

  // ====== CRUD ===============================================================
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;
    isSaving = true;
    notifyListeners();
    try {
      final novo = PlanningRightWayPropertyData(
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

      // 👇 avisa o mapa para recarregar (rótulos/geo, se necessário)
      mapRefresh.value++;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text(editingMode ? 'Imóvel atualizado!' : 'Imóvel cadastrado!'),
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
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> delete(BuildContext context, String id) async {
    if (contract.id == null) return;
    await store.delete(contract.id!, id);
    await reload();

    // 👇 também sinaliza o mapa para recarregar
    mapRefresh.value++;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Imóvel removido.'), backgroundColor: Colors.red),
      );
    }
  }

  // ====== Arquivos (GEO + DOCS) =============================================
  Future<void> _loadFilesForCurrentProperty() async {
    geoNames.clear();
    geoUrls.clear();
    selectedGeoIndex = null;
    docNames.clear();
    docUrls.clear();
    selectedDocIndex = null;

    final cId = contract.id;
    final pId = selected?.id;
    if (cId == null || pId == null) {
      notifyListeners();
      return;
    }

    try {
      final geos = await storage.listarGeo(contractId: cId, propertyId: pId);
      for (final f in geos) {
        geoNames.add(f.name);
        geoUrls.add(f.url);
      }

      final docs = await storage.listarDocs(contractId: cId, propertyId: pId);
      for (final f in docs) {
        docNames.add(f.name);
        docUrls.add(f.url);
      }
    } catch (_) {/* ignore */}

    notifyListeners();
  }

  Future<void> addGeoFile(BuildContext context) async {
    final cId = contract.id, pId = selected?.id;
    if (cId == null || pId == null) return;

    try {
      String? last;
      await storage.uploadGeoWithPicker(
        contractId: cId,
        propertyId: pId,
        onProgress: (p) {
          final m =
              'Enviando georreferenciado ${(p * 100).toStringAsFixed(0)}%';
          if (m != last && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(m),
                duration: const Duration(milliseconds: 700)));
            last = m;
          }
        },
      );
      await _loadFilesForCurrentProperty();

      // 👇 sinaliza o mapa para recarregar geometrias
      mapRefresh.value++;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Arquivo georreferenciado adicionado!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao adicionar georreferenciado: $e')));
      }
    }
  }

  Future<void> addDocFile(BuildContext context) async {
    final cId = contract.id, pId = selected?.id;
    if (cId == null || pId == null) return;

    try {
      String? last;
      await storage.uploadDocWithPicker(
        contractId: cId,
        propertyId: pId,
        onProgress: (p) {
          final m = 'Enviando arquivo ${(p * 100).toStringAsFixed(0)}%';
          if (m != last && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(m),
                duration: const Duration(milliseconds: 700)));
            last = m;
          }
        },
      );
      await _loadFilesForCurrentProperty();

      // DOC não altera mapa, então não precisa sinalizar (opcional)

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Arquivo adicionado!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Falha ao adicionar anexo: $e')));
      }
    }
  }

  void openGeoAt(int i) async {
    if (i < 0 || i >= geoUrls.length) return;
    selectedGeoIndex = i;
    notifyListeners();
    try {
      await launchUrl(Uri.parse(geoUrls[i]),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void openDocAt(int i) async {
    if (i < 0 || i >= docUrls.length) return;
    selectedDocIndex = i;
    notifyListeners();
    try {
      await launchUrl(Uri.parse(docUrls[i]),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> removeGeoAt(BuildContext context, int i) async {
    if (i < 0 || i >= geoUrls.length) return;
    try {
      await storage.deleteByUrl(geoUrls[i]);
      await _loadFilesForCurrentProperty();

      // 👇 sinaliza o mapa para recarregar geometrias
      mapRefresh.value++;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Arquivo georreferenciado removido.'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
      }
    }
  }

  Future<void> removeDocAt(BuildContext context, int i) async {
    if (i < 0 || i >= docUrls.length) return;
    try {
      await storage.deleteByUrl(docUrls[i]);
      await _loadFilesForCurrentProperty();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Arquivo removido.'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
      }
    }
  }

  @override
  void dispose() {
    removeValidation([ownerCtrl, registryCtrl, statusCtrl], _validate);
    for (final c in [
      ownerCtrl,
      cpfCnpjCtrl,
      typeCtrl,
      statusCtrl,
      registryCtrl,
      officeCtrl,
      addressCtrl,
      cityCtrl,
      ufCtrl,
      processCtrl,
      notifDateCtrl,
      inspDateCtrl,
      agreeDateCtrl,
      totalAreaCtrl,
      affectedAreaCtrl,
      indemnityCtrl,
      phoneCtrl,
      emailCtrl,
      notesCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
