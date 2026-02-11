// lib/screens/.../lane_regularization_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/formats/sipged_format_dates.dart';
import 'package:siged/_widgets/windows/show_window_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import 'lane_regularization_data.dart';
import 'lane_regularization_store.dart';
import 'lane_regularization_storage_bloc.dart';

import 'package:siged/_utils/validates/sipged_validation.dart';

// ✅ NOVO: sem intl
import 'package:siged/_utils/formats/sipged_format_numbers.dart';
import 'package:siged/_utils/formats/sipged_format_money.dart';

import 'package:siged/_blocs/modules/contracts/_process/process_data.dart';

// ✅ helpers papel
import 'package:siged/_blocs/system/permitions/user_permission.dart' as roles;

// ✅ Attachment (mesmo usado em Medições)
import 'package:siged/_widgets/list/files/attachment.dart';

// ✅ Preview interno de PDF (abre no Dialog)
import 'package:siged/_widgets/pdf/pdf_preview.dart';

// 🔔 Notificações centralizadas
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class LaneRegularizationController extends ChangeNotifier with SipGedValidation {
  final ProcessData contract;
  final LaneRegularizationStore store;
  final LaneRegularizationStorageBloc storage;

  final ValueNotifier<int> mapRefresh = ValueNotifier<int>(0);

  LaneRegularizationController({
    required this.contract,
    required this.store,
    LaneRegularizationStorageBloc? storageBloc,
  }) : storage = storageBloc ?? LaneRegularizationStorageBloc() {
    _init();
  }

  // state
  late Future<List<LaneRegularizationData>> futureProps;
  LaneRegularizationData? selected;
  String? currentId;
  UserData? currentUser;

  bool isSaving = false;
  bool editingMode = false;
  bool formValidated = false;
  bool isEditable = true;

  // ===== Arquivos: Attachment =====
  List<Attachment> geoItems = [];
  int? selectedGeoIndex;

  List<Attachment> docItems = [];
  int? selectedDocIndex;

  // ====== SideListBox NEW API: sync list ======
  void setGeoItems(List<dynamic> items) {
    geoItems = items.whereType<Attachment>().toList();
    if (selectedGeoIndex != null &&
        (selectedGeoIndex! < 0 || selectedGeoIndex! >= geoItems.length)) {
      selectedGeoIndex = null;
    }
    notifyListeners();
  }

  void setDocItems(List<dynamic> items) {
    docItems = items.whereType<Attachment>().toList();
    if (selectedDocIndex != null &&
        (selectedDocIndex! < 0 || selectedDocIndex! >= docItems.length)) {
      selectedDocIndex = null;
    }
    notifyListeners();
  }

  // ====== SideListBox NEW API: persist rename ======
  Future<bool> persistRenameGeo({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    try {
      if (index < 0 || index >= geoItems.length) return false;
      if (geoItems[index].id != oldItem.id) return false;

      final label = newItem.label.trim();
      if (label.isEmpty) return false;

      geoItems[index] = geoItems[index].copyWith(label: label);
      await _persistAttachments();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> persistRenameDoc({
    required int index,
    required Attachment oldItem,
    required Attachment newItem,
  }) async {
    try {
      if (index < 0 || index >= docItems.length) return false;
      if (docItems[index].id != oldItem.id) return false;

      final label = newItem.label.trim();
      if (label.isEmpty) return false;

      docItems[index] = docItems[index].copyWith(label: label);
      await _persistAttachments();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  // CONTROLLERS BÁSICOS
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

  // NOVOS (pipeline, rodovia, DUP, avaliação, pagamento etc.)
  final stageCtrl = TextEditingController();
  final negotiationCtrl = TextEditingController();
  final indemnityTypeCtrl = TextEditingController();
  final useOfLandCtrl = TextEditingController();
  final improvementsCtrl = TextEditingController();

  final laneSideCtrl = TextEditingController();
  final roadNameCtrl = TextEditingController();
  final kmStartCtrl = TextEditingController();
  final kmEndCtrl = TextEditingController();
  final corridorWidthCtrl = TextEditingController();
  final centroidLatCtrl = TextEditingController();
  final centroidLngCtrl = TextEditingController();

  final dupNumberCtrl = TextEditingController();
  final dupDateCtrl = TextEditingController();
  final doPublicationCtrl = TextEditingController();
  final doPublicationDateCtrl = TextEditingController();
  final arCtrl = TextEditingController();

  final appraisalNumberCtrl = TextEditingController();
  final appraiserNameCtrl = TextEditingController();
  final appraisalMethodCtrl = TextEditingController();
  final appraisalDateCtrl = TextEditingController();
  final appraisalValueCtrl = TextEditingController();

  final ownerCounterCtrl = TextEditingController();
  final govProposalCtrl = TextEditingController();

  final paymentFormCtrl = TextEditingController();
  final bankNameCtrl = TextEditingController();
  final bankAgencyCtrl = TextEditingController();
  final bankAccountCtrl = TextEditingController();
  final pixKeyCtrl = TextEditingController();
  final paymentDateCtrl = TextEditingController();

  final possessionDateCtrl = TextEditingController();
  final evictionDateCtrl = TextEditingController();
  final registryUpdateDateCtrl = TextEditingController();

  final carCtrl = TextEditingController();
  final ccirCtrl = TextEditingController();
  final nirfCtrl = TextEditingController();
  final sncrCtrl = TextEditingController();

  final courtCtrl = TextEditingController();
  final caseNumberCtrl = TextEditingController();
  final rpvPrecCtrl = TextEditingController();
  final depositInCourtCtrl = TextEditingController();

  final ressettlementCtrl = TextEditingController(); // "Sim/Não"
  final familyCountCtrl = TextEditingController();
  final socialNotesCtrl = TextEditingController();

  bool get isAdmin {
    final u = currentUser;
    if (u == null) return false;
    return roles.roleForUser(u) == roles.UserProfile.ADMINISTRADOR;
  }

  // =======================
  // ✅ Helpers de formatação
  // =======================
  String _fmtDec(double? v, {int digits = 2, String empty = ''}) {
    if (v == null) return empty;
    return SipGedFormatNumbers.decimalPtBr(v, fractionDigits: digits);
  }

  /// Mantém o mesmo comportamento do antigo priceToString (com "R$")
  String _fmtMoney(double? v, {String empty = ''}) {
    if (v == null) return empty;
    return SipGedFormatMoney.doubleToText(v);
  }

  double? _toDouble(String s) => SipGedFormatNumbers.toDouble(s);

  // ===== Helpers (rótulo/sugestão) =====
  String _baseName(String name) {
    var s = name.trim();
    final q = s.indexOf('?');
    if (q != -1) s = s.substring(0, q);
    final h = s.indexOf('#');
    if (h != -1) s = s.substring(0, h);
    s = s.split('/').last;
    return s.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '');
  }

  // ====== INIT ======
  Future<void> _init() async {
    futureProps = _getAll();

    setupValidation([
      registryCtrl,
      statusCtrl,
      stageCtrl,
      dupNumberCtrl,
      dupDateCtrl,
      appraisalNumberCtrl,
      appraisalDateCtrl,
      appraisalValueCtrl,
      indemnityCtrl,
      paymentFormCtrl,
    ], _validate);

    if (statusCtrl.text.trim().isEmpty) {
      statusCtrl.text = 'A NEGOCIAR';
    }
  }

  Future<List<LaneRegularizationData>> _getAll() async {
    if (contract.id == null) return [];
    await store.ensureFor(contract.id!);
    return store.listFor(contract.id!);
  }

  void _validate() {
    final obrig = <TextEditingController>[
      registryCtrl,
      statusCtrl,
    ];
    if (stageCtrl.text == 'DUP/NOTIFICAÇÃO') {
      obrig.addAll([dupNumberCtrl, dupDateCtrl]);
    } else if (stageCtrl.text == 'VISTORIA/LAUDO') {
      obrig.addAll([appraisalNumberCtrl, appraisalDateCtrl, appraisalValueCtrl]);
    } else if (stageCtrl.text == 'ACORDO' || stageCtrl.text == 'PAGAMENTO') {
      obrig.addAll([indemnityCtrl, paymentFormCtrl]);
    }
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

  void applySnapshot(List<LaneRegularizationData> list) {}

  // ====== Seleção
  void fillFields(LaneRegularizationData p) {
    selected = p;
    editingMode = true;
    currentId = p.id;

    ownerCtrl.text = p.ownerName ?? '';
    cpfCnpjCtrl.text = p.cpfCnpj ?? '';
    typeCtrl.text = p.propertyType ?? '';
    statusCtrl.text = p.status ?? '';
    stageCtrl.text = p.currentStage ?? '';
    negotiationCtrl.text = p.negotiationStatus ?? '';
    indemnityTypeCtrl.text = p.indemnityType ?? '';
    useOfLandCtrl.text = p.useOfLand ?? '';
    improvementsCtrl.text = p.improvementsSummary ?? '';

    registryCtrl.text = p.registryNumber ?? '';
    officeCtrl.text = p.registryOffice ?? '';
    addressCtrl.text = p.address ?? '';
    cityCtrl.text = p.city ?? '';
    ufCtrl.text = p.state ?? '';

    roadNameCtrl.text = p.roadName ?? '';
    laneSideCtrl.text = p.laneSide ?? '';

    kmStartCtrl.text = _fmtDec(p.kmStart, digits: 3);
    kmEndCtrl.text = _fmtDec(p.kmEnd, digits: 3);
    corridorWidthCtrl.text = _fmtDec(p.corridorWidthM, digits: 2);
    centroidLatCtrl.text = _fmtDec(p.centroidLat, digits: 6);
    centroidLngCtrl.text = _fmtDec(p.centroidLng, digits: 6);

    processCtrl.text = p.processNumber ?? '';
    dupNumberCtrl.text = p.dupNumber ?? '';
    dupDateCtrl.text =
    p.dupDate != null ? SipGedFormatDates.dateToDdMMyyyy(p.dupDate!) : '';
    doPublicationCtrl.text = p.doPublication ?? '';
    doPublicationDateCtrl.text = p.doPublicationDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.doPublicationDate!)
        : '';
    arCtrl.text = p.notificationAR ?? '';

    notifDateCtrl.text = p.notificationDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.notificationDate!)
        : '';
    inspDateCtrl.text = p.inspectionDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.inspectionDate!)
        : '';
    agreeDateCtrl.text = p.agreementDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.agreementDate!)
        : '';
    paymentDateCtrl.text = p.paymentDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.paymentDate!)
        : '';
    possessionDateCtrl.text = p.possessionDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.possessionDate!)
        : '';
    evictionDateCtrl.text = p.evictionDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.evictionDate!)
        : '';
    registryUpdateDateCtrl.text = p.registryUpdateDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.registryUpdateDate!)
        : '';

    appraisalNumberCtrl.text = p.appraisalNumber ?? '';
    appraiserNameCtrl.text = p.appraiserName ?? '';
    appraisalMethodCtrl.text = p.appraisalMethod ?? '';
    appraisalDateCtrl.text = p.appraisalDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.appraisalDate!)
        : '';

    appraisalValueCtrl.text = _fmtMoney(p.appraisalValue);

    totalAreaCtrl.text = _fmtDec(p.totalArea, digits: 2);
    affectedAreaCtrl.text = _fmtDec(p.affectedArea, digits: 2);

    indemnityCtrl.text = _fmtMoney(p.indemnityValue);
    ownerCounterCtrl.text = _fmtMoney(p.ownerCounterValue);
    govProposalCtrl.text = _fmtMoney(p.govProposalValue);

    paymentFormCtrl.text = p.paymentForm ?? '';
    bankNameCtrl.text = p.bankName ?? '';
    bankAgencyCtrl.text = p.bankAgency ?? '';
    bankAccountCtrl.text = p.bankAccount ?? '';
    pixKeyCtrl.text = p.pixKey ?? '';
    paymentDateCtrl.text = p.paymentDate != null
        ? SipGedFormatDates.dateToDdMMyyyy(p.paymentDate!)
        : '';

    carCtrl.text = p.carNumber ?? '';
    ccirCtrl.text = p.ccirNumber ?? '';
    nirfCtrl.text = p.nirfNumber ?? '';
    sncrCtrl.text = p.incraSncr ?? '';

    courtCtrl.text = p.courtName ?? '';
    caseNumberCtrl.text = p.caseNumber ?? '';
    rpvPrecCtrl.text = p.rpvOrPrecatorio ?? '';

    depositInCourtCtrl.text = _fmtMoney(p.depositInCourtValue);

    ressettlementCtrl.text = (p.resettlementRequired == true) ? 'Sim' : 'Não';
    familyCountCtrl.text = (p.familyCount ?? 0).toString();
    socialNotesCtrl.text = p.socialNotes ?? '';

    phoneCtrl.text = p.phone ?? '';
    emailCtrl.text = p.email ?? '';
    notesCtrl.text = p.notes ?? '';

    _validate();
    _refreshFilesForCurrentProperty();
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
      notesCtrl,
      stageCtrl,
      negotiationCtrl,
      indemnityTypeCtrl,
      useOfLandCtrl,
      improvementsCtrl,
      laneSideCtrl,
      roadNameCtrl,
      kmStartCtrl,
      kmEndCtrl,
      corridorWidthCtrl,
      centroidLatCtrl,
      centroidLngCtrl,
      dupNumberCtrl,
      dupDateCtrl,
      doPublicationCtrl,
      doPublicationDateCtrl,
      arCtrl,
      appraisalNumberCtrl,
      appraiserNameCtrl,
      appraisalMethodCtrl,
      appraisalDateCtrl,
      appraisalValueCtrl,
      ownerCounterCtrl,
      govProposalCtrl,
      paymentFormCtrl,
      bankNameCtrl,
      bankAgencyCtrl,
      bankAccountCtrl,
      pixKeyCtrl,
      paymentDateCtrl,
      possessionDateCtrl,
      evictionDateCtrl,
      registryUpdateDateCtrl,
      carCtrl,
      ccirCtrl,
      nirfCtrl,
      sncrCtrl,
      courtCtrl,
      caseNumberCtrl,
      rpvPrecCtrl,
      depositInCourtCtrl,
      ressettlementCtrl,
      familyCountCtrl,
      socialNotesCtrl,
    ]) {
      c.clear();
    }

    statusCtrl.text = 'A NEGOCIAR';

    geoItems.clear();
    selectedGeoIndex = null;
    docItems.clear();
    selectedDocIndex = null;

    _validate();
    notifyListeners();
  }

  // ====== CRUD
  Future<void> saveOrUpdate(BuildContext context) async {
    if (contract.id == null) return;
    isSaving = true;
    notifyListeners();
    final wasEditing = editingMode;
    try {
      final novo = LaneRegularizationData(
        id: currentId,
        contractId: contract.id,
        ownerName: ownerCtrl.text.trim(),
        status: (statusCtrl.text.trim().isEmpty) ? 'A NEGOCIAR' : statusCtrl.text,
        currentStage: stageCtrl.text,
        negotiationStatus: negotiationCtrl.text,
        indemnityType: indemnityTypeCtrl.text,
        useOfLand: useOfLandCtrl.text,
        hasImprovements: improvementsCtrl.text.trim().isNotEmpty,
        improvementsSummary: improvementsCtrl.text.trim(),
        registryNumber: registryCtrl.text.trim(),
        registryOffice: officeCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: ufCtrl.text.trim().toUpperCase(),
        roadName: roadNameCtrl.text.trim(),
        laneSide: laneSideCtrl.text,
        kmStart: _toDouble(kmStartCtrl.text),
        kmEnd: _toDouble(kmEndCtrl.text),
        corridorWidthM: _toDouble(corridorWidthCtrl.text),
        centroidLat: _toDouble(centroidLatCtrl.text),
        centroidLng: _toDouble(centroidLngCtrl.text),
        processNumber: processCtrl.text.trim(),
        dupNumber: dupNumberCtrl.text.trim(),
        dupDate: SipGedFormatDates.ddMMyyyyToDate(dupDateCtrl.text),
        doPublication: doPublicationCtrl.text.trim(),
        doPublicationDate: SipGedFormatDates.ddMMyyyyToDate(doPublicationDateCtrl.text),
        notificationAR: arCtrl.text.trim(),
        notificationDate: SipGedFormatDates.ddMMyyyyToDate(notifDateCtrl.text),
        inspectionDate: SipGedFormatDates.ddMMyyyyToDate(inspDateCtrl.text),
        appraisalDate: SipGedFormatDates.ddMMyyyyToDate(appraisalDateCtrl.text),
        agreementDate: SipGedFormatDates.ddMMyyyyToDate(agreeDateCtrl.text),
        paymentDate: SipGedFormatDates.ddMMyyyyToDate(paymentDateCtrl.text),
        possessionDate: SipGedFormatDates.ddMMyyyyToDate(possessionDateCtrl.text),
        evictionDate: SipGedFormatDates.ddMMyyyyToDate(evictionDateCtrl.text),
        registryUpdateDate: SipGedFormatDates.ddMMyyyyToDate(registryUpdateDateCtrl.text),
        appraisalNumber: appraisalNumberCtrl.text.trim(),
        appraiserName: appraiserNameCtrl.text.trim(),
        appraisalMethod: appraisalMethodCtrl.text.trim(),
        appraisalValue: _toDouble(appraisalValueCtrl.text),
        totalArea: _toDouble(totalAreaCtrl.text),
        affectedArea: _toDouble(affectedAreaCtrl.text),
        indemnityValue: _toDouble(indemnityCtrl.text),
        ownerCounterValue: _toDouble(ownerCounterCtrl.text),
        govProposalValue: _toDouble(govProposalCtrl.text),
        paymentForm: paymentFormCtrl.text,
        bankName: bankNameCtrl.text,
        bankAgency: bankAgencyCtrl.text,
        bankAccount: bankAccountCtrl.text,
        pixKey: pixKeyCtrl.text,
        isRural: (typeCtrl.text == 'RURAL'),
        carNumber: carCtrl.text,
        ccirNumber: ccirCtrl.text,
        nirfNumber: nirfCtrl.text,
        incraSncr: sncrCtrl.text,
        isJudicial: (indemnityTypeCtrl.text == 'Judicial') || (statusCtrl.text == 'JUDICIALIZADO'),
        courtName: courtCtrl.text,
        caseNumber: caseNumberCtrl.text,
        rpvOrPrecatorio: rpvPrecCtrl.text,
        depositInCourtValue: _toDouble(depositInCourtCtrl.text),
        resettlementRequired: ressettlementCtrl.text.toLowerCase() == 'sim',
        familyCount: int.tryParse(familyCountCtrl.text),
        socialNotes: socialNotesCtrl.text,
        phone: phoneCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      );

      await store.saveOrUpdate(contract.id!, novo);

      await _persistAttachments();

      await reload();
      clearForm();

      mapRefresh.value++;

      _notify(
        wasEditing ? 'Imóvel atualizado!' : 'Imóvel cadastrado!',
        type: AppNotificationType.success,
      );
    } catch (e) {
      _notify('Erro ao salvar', type: AppNotificationType.error, subtitle: '$e');
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> delete(BuildContext context, String id) async {
    if (contract.id == null) return;
    await store.delete(contract.id!, id);
    await reload();
    mapRefresh.value++;
    _notify('Imóvel removido.', type: AppNotificationType.warning);
  }

  // ====== Arquivos (GEO + DOCS) com Attachment e persistência =====

  DocumentReference<Map<String, dynamic>>? _propRef() {
    final cId = contract.id;
    final pId = selected?.id;
    if (cId == null || pId == null) return null;
    return FirebaseFirestore.instance
        .collection('contracts')
        .doc(cId)
        .collection('planning_right_way_properties')
        .doc(pId);
  }

  Future<void> _persistAttachments() async {
    final ref = _propRef();
    if (ref == null) return;
    await ref.set({
      'geoAttachments': geoItems.map((e) => e.toMap()).toList(),
      'docAttachments': docItems.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _refreshFilesForCurrentProperty() async {
    geoItems.clear();
    selectedGeoIndex = null;
    docItems.clear();
    selectedDocIndex = null;

    final ref = _propRef();
    if (ref == null) {
      notifyListeners();
      return;
    }

    try {
      final snap = await ref.get();
      final data = snap.data() ?? {};
      final geo = (data['geoAttachments'] as List?)
          ?.map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList() ??
          <Attachment>[];
      final docs = (data['docAttachments'] as List?)
          ?.map((e) => Attachment.fromMap(Map<String, dynamic>.from(e)))
          .toList() ??
          <Attachment>[];

      if (geo.isEmpty) {
        final listed = await storage.listarGeo(
          contractId: contract.id!,
          propertyId: selected!.id!,
        );
        geoItems = listed
            .map(
              (f) => Attachment(
            id: f.name,
            label: _baseName(f.name),
            url: f.url,
            path: f.path,
            ext: '',
            createdAt: DateTime.now(),
          ),
        )
            .toList();
      } else {
        geoItems = geo;
      }

      if (docs.isEmpty) {
        final listed = await storage.listarDocs(
          contractId: contract.id!,
          propertyId: selected!.id!,
        );
        docItems = listed
            .map(
              (f) => Attachment(
            id: f.name,
            label: _baseName(f.name),
            url: f.url,
            path: f.path,
            ext: '.pdf',
            createdAt: DateTime.now(),
          ),
        )
            .toList();
      } else {
        docItems = docs;
      }

      await _persistAttachments();
    } catch (_) {}

    notifyListeners();
  }

  Future<void> addGeoFile(BuildContext context) async {
    final ref = _propRef();
    if (ref == null) return;

    const progressId = 'lane_geo_upload_progress';
    try {
      String? last;

      final uploaded = await storage.uploadGeoWithPickerDetailed(
        contractId: contract.id!,
        propertyId: selected!.id!,
        onProgress: (p) {
          final pct = (p * 100).clamp(0, 100).toStringAsFixed(0);
          final m = 'Enviando georreferenciado $pct%';
          if (m != last) {
            _notify(
              'Enviando georreferenciado',
              type: AppNotificationType.info,
              subtitle: '$pct%',
              id: progressId,
            );
            last = m;
          }
        },
      );

      NotificationCenter.instance.dismissById(progressId);

      final suggestion = _baseName(uploaded.name);
      final label = (await askLabelDialog(context, suggestion))?.trim();
      final att = Attachment(
        id: uploaded.name,
        label: (label == null || label.isEmpty) ? suggestion : label,
        url: uploaded.url,
        path: uploaded.path,
        ext: '',
        createdAt: DateTime.now(),
      );
      geoItems = [att, ...geoItems];
      await _persistAttachments();
      notifyListeners();

      _notify('Arquivo georreferenciado adicionado!',
          type: AppNotificationType.success);
      mapRefresh.value++;
    } catch (e) {
      NotificationCenter.instance.dismissById(progressId);
      _notify('Falha ao adicionar georreferenciado',
          type: AppNotificationType.error, subtitle: '$e');
    }
  }

  Future<void> addDocFile(BuildContext context) async {
    final ref = _propRef();
    if (ref == null) return;

    const progressId = 'lane_doc_upload_progress';
    try {
      String? last;

      final uploaded = await storage.uploadDocWithPickerDetailed(
        contractId: contract.id!,
        propertyId: selected!.id!,
        onProgress: (p) {
          final pct = (p * 100).clamp(0, 100).toStringAsFixed(0);
          final m = 'Enviando arquivo $pct%';
          if (m != last) {
            _notify(
              'Enviando arquivo',
              type: AppNotificationType.info,
              subtitle: '$pct%',
              id: progressId,
            );
            last = m;
          }
        },
      );

      NotificationCenter.instance.dismissById(progressId);

      final suggestion = _baseName(uploaded.name);
      final label = (await askLabelDialog(context, suggestion))?.trim();
      final att = Attachment(
        id: uploaded.name,
        label: (label == null || label.isEmpty) ? suggestion : label,
        url: uploaded.url,
        path: uploaded.path,
        ext: '.pdf',
        createdAt: DateTime.now(),
      );
      docItems = [att, ...docItems];
      await _persistAttachments();
      notifyListeners();

      _notify('Arquivo adicionado!', type: AppNotificationType.success);
    } catch (e) {
      NotificationCenter.instance.dismissById(progressId);
      _notify('Falha ao adicionar anexo',
          type: AppNotificationType.error, subtitle: '$e');
    }
  }

  // abrir GEO (externo)
  void openGeoAt(int i) async {
    if (i < 0 || i >= geoItems.length) return;
    selectedGeoIndex = i;
    notifyListeners();
    final url = geoItems[i].url;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // abrir DOC (PDF) no dialog interno
  Future<void> openDocAt(BuildContext context, int i) async {
    if (i < 0 || i >= docItems.length) return;
    selectedDocIndex = i;
    notifyListeners();
    final url = docItems[i].url;
    if (url.isEmpty) return;

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url),
      ),
    );
  }

  // deletar
  Future<void> removeGeoAt(BuildContext context, int i) async {
    if (i < 0 || i >= geoItems.length) return;
    try {
      await storage.deleteByPath(geoItems[i].path);
      geoItems.removeAt(i);
      await _persistAttachments();
      notifyListeners();
      mapRefresh.value++;
      _notify('Arquivo georreferenciado removido.',
          type: AppNotificationType.warning);
    } catch (e) {
      _notify('Erro ao remover', type: AppNotificationType.error, subtitle: '$e');
    }
  }

  Future<void> removeDocAt(BuildContext context, int i) async {
    if (i < 0 || i >= docItems.length) return;
    try {
      await storage.deleteByPath(docItems[i].path);
      docItems.removeAt(i);
      await _persistAttachments();
      notifyListeners();
      _notify('Arquivo removido.', type: AppNotificationType.warning);
    } catch (e) {
      _notify('Erro ao remover', type: AppNotificationType.error, subtitle: '$e');
    }
  }

  // ============================================================
  // ✅ Métodos antigos (com dialog) — mantidos p/ compatibilidade
  // ============================================================
  Future<void> renameGeoLabel({
    required int index,
    required String newLabel,
  }) async {
    if (index < 0 || index >= geoItems.length) return;
    final trimmed = newLabel.trim();
    if (trimmed.isEmpty) return;

    final current = geoItems[index];
    if (current.label == trimmed) return;

    geoItems[index] = current.copyWith(label: trimmed);
    await _persistAttachments();
    notifyListeners();
  }

  Future<void> renameDocLabel({
    required int index,
    required String newLabel,
  }) async {
    if (index < 0 || index >= docItems.length) return;
    final trimmed = newLabel.trim();
    if (trimmed.isEmpty) return;

    final current = docItems[index];
    if (current.label == trimmed) return;

    docItems[index] = current.copyWith(label: trimmed);
    await _persistAttachments();
    notifyListeners();
  }

  Future<void> editGeoLabel(BuildContext context, int i) async {
    if (i < 0 || i >= geoItems.length) return;
    final current = geoItems[i];
    final newLabel = await askLabelDialog(context, current.label);
    if (newLabel == null) return;
    await renameGeoLabel(index: i, newLabel: newLabel);
  }

  Future<void> editDocLabel(BuildContext context, int i) async {
    if (i < 0 || i >= docItems.length) return;
    final current = docItems[i];
    final newLabel = await askLabelDialog(context, current.label);
    if (newLabel == null) return;
    await renameDocLabel(index: i, newLabel: newLabel);
  }

  // 🔔 util de notificação global
  void _notify(
      String title, {
        AppNotificationType type = AppNotificationType.info,
        String? subtitle,
        String? id,
      }) {
    if (id != null) {
      NotificationCenter.instance.dismissById(id);
    }
    NotificationCenter.instance.show(
      AppNotification(
        id: id,
        title: Text(title),
        subtitle: (subtitle != null && subtitle.isNotEmpty)
            ? Text(subtitle)
            : null,
        type: type,
      ),
    );
  }

  @override
  void dispose() {
    removeValidation([
      registryCtrl,
      statusCtrl,
      stageCtrl,
      dupNumberCtrl,
      dupDateCtrl,
      appraisalNumberCtrl,
      appraisalDateCtrl,
      appraisalValueCtrl,
      indemnityCtrl,
      paymentFormCtrl,
    ], _validate);

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
      notesCtrl,
      stageCtrl,
      negotiationCtrl,
      indemnityTypeCtrl,
      useOfLandCtrl,
      improvementsCtrl,
      laneSideCtrl,
      roadNameCtrl,
      kmStartCtrl,
      kmEndCtrl,
      corridorWidthCtrl,
      centroidLatCtrl,
      centroidLngCtrl,
      dupNumberCtrl,
      dupDateCtrl,
      doPublicationCtrl,
      doPublicationDateCtrl,
      arCtrl,
      appraisalNumberCtrl,
      appraiserNameCtrl,
      appraisalMethodCtrl,
      appraisalDateCtrl,
      appraisalValueCtrl,
      ownerCounterCtrl,
      govProposalCtrl,
      paymentFormCtrl,
      bankNameCtrl,
      bankAgencyCtrl,
      bankAccountCtrl,
      pixKeyCtrl,
      paymentDateCtrl,
      possessionDateCtrl,
      evictionDateCtrl,
      registryUpdateDateCtrl,
      carCtrl,
      ccirCtrl,
      nirfCtrl,
      sncrCtrl,
      courtCtrl,
      caseNumberCtrl,
      rpvPrecCtrl,
      depositInCourtCtrl,
      ressettlementCtrl,
      familyCountCtrl,
      socialNotesCtrl,
    ]) {
      c.dispose();
    }

    super.dispose();
  }
}
