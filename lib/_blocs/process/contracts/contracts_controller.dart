// lib/_blocs/process/contracts/contracts_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:siged/_widgets/list/files/attachment.dart';

// ===== Measurements (separados) =====
import 'package:siged/_blocs/process/report/report_measurement_data.dart';
import 'package:siged/_blocs/process/report/report_measurement_store.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_store.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_store.dart';

// ===== Contracts / Additives / Apostilles =====
import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_bloc.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/process/contracts/contract_rules.dart';
import 'package:siged/_blocs/process/contracts/contract_store.dart';
import 'package:siged/_blocs/process/contracts/contract_data.dart';
import 'package:siged/_blocs/process/contracts/contract_storage_bloc.dart';

// ===== Map/Charts =====
import 'package:siged/_services/geo_json_manager.dart';
import 'package:siged/_widgets/charts/radar/radar_series_data.dart';
import 'package:siged/_widgets/charts/treemap/treemap_chart_changed.dart';

// ===== PDF viewer interno =====
import 'package:siged/_services/pdf/pdf_preview.dart';

// ===== Notificações ricas =====
import 'package:intl/intl.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class ContractsController extends ChangeNotifier {
  ContractsController({
    required this.store,
    required this.additivesStore,
    required this.apostillesStore,
    required this.reportsMeasurementStore,
    required this.adjustmentsStore,
    required this.revisionsStore,
    required this.contractStorageBloc,
    AdditivesBloc? additivesBloc,
    ApostillesBloc? apostillesBloc,
    GeoJsonManager? geoManager,
    this.moduleKey = 'contracts',
    this.forceEditable = false,
  })  : additivesBloc = additivesBloc ?? AdditivesBloc(),
        apostillesBloc = apostillesBloc ?? ApostillesBloc(),
        geoManager = geoManager ?? GeoJsonManager();

  // =======================================================================
  // INJEÇÕES
  // =======================================================================
  final ContractsStore store;
  final AdditivesStore additivesStore;
  final ApostillesStore apostillesStore;

  final ReportsMeasurementStore reportsMeasurementStore;
  final AdjustmentsMeasurementStore adjustmentsStore;
  final RevisionsMeasurementStore revisionsStore;

  final AdditivesBloc additivesBloc;
  final ApostillesBloc apostillesBloc;
  final GeoJsonManager geoManager;

  final ContractStorageBloc contractStorageBloc;

  final String moduleKey;
  final bool forceEditable;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Helpers para rótulo rico nas notificações
  String _userName() {
    final u = FirebaseAuth.instance.currentUser;
    return (u?.displayName ?? u?.email ?? 'Usuário').trim();
  }

  String _stamp([DateTime? dt]) {
    final d = dt ?? DateTime.now();
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }

  // =======================================================================
  // ESTADO DASHBOARD / AGREGAÇÕES
  // =======================================================================
  List<ContractData> allContracts = [];
  List<ContractData> filteredContracts = [];
  List<ReportMeasurementData> allMeasurements = [];

  List<String> uniqueCompanies = [];
  List<String> selectedRegions = [];

  String? selectedRegion;
  String? selectedCompany;
  String? selectedStatus;
  int? selectedRegionIndex;
  int? selectedCompanyIndex;

  bool initialized = false;
  int? selectedYear = DateTime.now().year;
  int? selectedMonth;

  Map<String, double> totaisStatusIniciais = {};
  Map<String, double> totaisStatusAditivos = {};
  Map<String, double> totaisStatusApostilas = {};

  Map<String, double> totaisRegiaoIniciais = {};
  Map<String, double> totaisRegiaoAditivos = {};
  Map<String, double> totaisRegiaoApostilas = {};

  Map<String, double> totaisEmpresaIniciais = {};
  Map<String, double> totaisEmpresaAditivos = {};
  Map<String, double> totaisEmpresaApostilas = {};

  double? _totalMedicoes;
  double? _totalReajustes;
  double? _totalRevisoes;

  double? get totaisMedicoes => _totalMedicoes;
  double? get totaisReajustes => _totalReajustes;
  double? get totaisRevisoes => _totalRevisoes;

  String tipoDeValorSelecionado = 'Somatório total';

  bool _disposed = false;
  int _applyRunId = 0;

  void _safeNotify() {
    if (!_disposed && hasListeners) notifyListeners();
  }

  // =======================================================================
  // ESTADO DO FORMULÁRIO
  // =======================================================================
  final formKey = GlobalKey<FormState>();
  bool showErrors = false;
  bool isSaving = false;

  bool get isEditable => forceEditable;

  bool get isBtnEnabled {
    return !isSaving &&
        (contractStatusCtrl.text.trim().isNotEmpty) &&
        (contractBiddingProcessNumberCtrl.text.trim().isNotEmpty) &&
        (contractNumberCtrl.text.trim().isNotEmpty) &&
        (initialValueOfContractCtrl.text.trim().isNotEmpty) &&
        (summarySubjectContractCtrl.text.trim().isNotEmpty) &&
        (contractRegionOfStateCtrl.text.trim().isNotEmpty) &&
        (contractTextKmCtrl.text.trim().isNotEmpty) &&
        (initialValidityContractDaysCtrl.text.trim().isNotEmpty) &&
        (initialValidityExecutionDaysCtrl.text.trim().isNotEmpty) &&
        (contractWorkTypeCtrl.text.trim().isNotEmpty);
  }

  late ContractData contractData;

  // ===== Controllers de texto (empresa)
  final TextEditingController contractCompanyLeaderCtrl = TextEditingController();
  final TextEditingController contractCompaniesInvolvedCtrl = TextEditingController();
  final TextEditingController cnoNumberCtrl = TextEditingController();
  final TextEditingController cnpjNumberCtrl = TextEditingController();
  final TextEditingController generalNumberCtrl = TextEditingController();

  // ===== Controllers de texto (gerais do contrato)
  final TextEditingController contractStatusCtrl = TextEditingController();
  final TextEditingController contractBiddingProcessNumberCtrl = TextEditingController();
  final TextEditingController contractNumberCtrl = TextEditingController();
  final TextEditingController initialValueOfContractCtrl = TextEditingController();
  final TextEditingController contractHighWayCtrl = TextEditingController();
  final TextEditingController summarySubjectContractCtrl = TextEditingController();
  final TextEditingController contractRegionOfStateCtrl = TextEditingController();
  final TextEditingController contractTextKmCtrl = TextEditingController();
  final TextEditingController contractTypeCtrl = TextEditingController();
  final TextEditingController contractWorkTypeCtrl = TextEditingController();
  final TextEditingController contractServiceTypeCtrl = TextEditingController();
  final TextEditingController datapublicacaodoeCtrl = TextEditingController();
  final TextEditingController initialValidityContractDaysCtrl = TextEditingController();
  final TextEditingController initialValidityExecutionDaysCtrl = TextEditingController();

  // ===== Descrição
  final TextEditingController contractObjectDescriptionCtrl = TextEditingController();

  // ===== Gestor
  final TextEditingController regionalManagerCtrl = TextEditingController();
  final TextEditingController managerIdCtrl = TextEditingController();
  final TextEditingController managerPhoneNumberCtrl = TextEditingController();
  final TextEditingController cpfContractManagerCtrl = TextEditingController();
  final TextEditingController contractManagerArtNumberCtrl = TextEditingController();

  // =======================================================================
  // ANEXOS (SideListBox)
  // =======================================================================
  final List<Attachment> _attachments = [];
  List<Attachment> get attachments => List.unmodifiable(_attachments);
  int? selectedContractDocIndex;

  bool _busyAttachments = false;
  bool get isBusyAttachments => _busyAttachments;

  String _ext(Attachment a) {
    final e = (a.ext).trim();
    if (e.isEmpty) return '';
    return e.startsWith('.') ? e.substring(1).toLowerCase() : e.toLowerCase();
  }

  String _baseNoExt(Attachment a) {
    final ext = _ext(a);
    if (ext.isEmpty) return a.label;
    final low = a.label.toLowerCase();
    return low.endsWith('.$ext')
        ? a.label.substring(0, a.label.length - ext.length - 1)
        : a.label;
  }

  // ===== Firestore (attachments + urlContractPdf) =====
  Future<({List<Attachment> atts, String? url})> _fetchDocMeta(String contractId) async {
    final snap = await _db.collection('contracts').doc(contractId).get();
    final data = snap.data();
    if (data == null) return (atts: const <Attachment>[], url: null);

    final raw = (data['attachments'] as List?) ?? const [];
    final atts = raw.map((e) => Attachment.fromMap(Map<String, dynamic>.from(e))).toList();

    final url = (data['urlContractPdf'] as String?) ?? (data['urlpdf'] as String?);
    return (atts: atts, url: url);
  }

  Future<void> _saveAttachmentsToDoc(String contractId, List<Attachment> atts) async {
    await _db.collection('contracts').doc(contractId).set({
      'attachments': atts.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _currentUserId ?? '',
    }, SetOptions(merge: true));
  }

  Future<void> refreshContractDocs() async {
    final id = contractData.id;
    if (id == null || id.isEmpty) {
      _attachments.clear();
      selectedContractDocIndex = null;
      _safeNotify();
      return;
    }

    try {
      final files = await contractStorageBloc.listarDocsContrato(contractId: id);

      final byUrl = <String, Attachment>{
        for (final f in files)
          f.url: Attachment(
            id: f.id,
            label: f.label,
            url: f.url,
            path: f.path,
            ext: f.ext,
            size: f.size,
            createdAt: f.createdAt,
            updatedAt: f.updatedAt,
            createdBy: f.createdBy,
            updatedBy: f.updatedBy,
          ),
      };

      final meta = await _fetchDocMeta(id);

      final urlFirestore = meta.url;
      if (urlFirestore != null && urlFirestore.trim().isNotEmpty) {
        byUrl.putIfAbsent(urlFirestore, () {
          String label = 'Contrato.pdf';
          try {
            final uri = Uri.parse(urlFirestore);
            final idx = uri.path.indexOf('/o/');
            if (idx != -1) {
              final encoded = uri.path.substring(idx + 3);
              final decoded = Uri.decodeComponent(encoded);
              final parts = decoded.split('/');
              if (parts.isNotEmpty) label = parts.last;
            }
          } catch (_) {}
          return Attachment(
            id: 'main-url',
            label: label,
            url: urlFirestore,
            path: '',
            ext: 'pdf',
            createdAt: DateTime.now(),
          );
        });
      }

      final saved = meta.atts;
      if (saved.isNotEmpty) {
        for (final att in saved) {
          if (att.url.isEmpty) continue;
          final existing = byUrl[att.url];
          if (existing != null) {
            existing.label = att.label;
          } else {
            byUrl[att.url] = att;
          }
        }
      }

      final list = byUrl.values.toList()
        ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));

      _attachments
        ..clear()
        ..addAll(list);

      if (selectedContractDocIndex != null &&
          selectedContractDocIndex! >= _attachments.length) {
        selectedContractDocIndex = _attachments.isEmpty ? null : 0;
      }
    } catch (_) {
      _attachments.clear();
      selectedContractDocIndex = null;
    }
    _safeNotify();
  }

  Future<void> addContractDoc(BuildContext context) async {
    final id = contractData.id;
    if (id == null) return;

    _busyAttachments = true;
    _safeNotify();

    // Notificação de progresso
    final notifId = 'contract-upload-$id';
    int lastShownPct = -1;

    try {
      NotificationCenter.instance.show(
        AppNotification(
          id: notifId,
          title: const Text('Enviando arquivo...'),
          subtitle: const Text('Aguarde, estamos subindo o documento do contrato'),
          type: AppNotificationType.info,
          duration: const Duration(seconds: 3),
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );

      await contractStorageBloc.uploadDocContratoWithPicker(
        contractId: id,
        onProgress: (p) {
          final pct = (p * 100).floor();
          if (pct ~/ 10 != lastShownPct ~/ 10) {
            lastShownPct = pct;
            NotificationCenter.instance.dismissById(notifId);
            NotificationCenter.instance.show(
              AppNotification(
                id: notifId,
                title: Text('Enviando arquivo $pct%'),
                type: AppNotificationType.info,
                duration: const Duration(milliseconds: 900),
                details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
              ),
            );
          }
        },
      );

      await refreshContractDocs();
      await _saveAttachmentsToDoc(id, _attachments);

      NotificationCenter.instance.dismissById(notifId);
      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Arquivo adicionado'),
          subtitle: Text('Total de anexos: ${_attachments.length}'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.dismissById(notifId);
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Falha ao adicionar anexo: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      _busyAttachments = false;
      _safeNotify();
    }
  }

  /// Agora abre PDF no viewer interno; outros formatos seguem externos.
  Future<void> openContractDocAt(BuildContext context, int i) async {
    if (i < 0 || i >= _attachments.length) return;

    selectedContractDocIndex = i;
    _safeNotify();

    final att = _attachments[i];
    final url = att.url;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url),
      ),
    );
  }

  Future<void> removeContractDocAt(BuildContext context, int i) async {
    if (i < 0 || i >= _attachments.length) return;
    final att = _attachments[i];

    _busyAttachments = true;
    _safeNotify();
    try {
      final ok = await contractStorageBloc.deleteByUrl(att.url);
      if (!ok) {
        throw Exception('Não foi possível excluir no Storage.');
      }

      _attachments.removeAt(i);

      if (contractData.id != null && contractData.id!.isNotEmpty) {
        await _saveAttachmentsToDoc(contractData.id!, _attachments);
      }

      await refreshContractDocs();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Arquivo removido'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao remover: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      _busyAttachments = false;
      _safeNotify();
    }
  }

  Future<void> renameContractDocAt(BuildContext context, int index) async {
    if (index < 0 || index >= _attachments.length) return;
    final att = _attachments[index];

    final ctrl = TextEditingController(text: _baseNoExt(att));
    final newBase = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rótulo do arquivo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Rótulo do arquivo'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );

    if (newBase == null || newBase.trim().isEmpty) return;

    _busyAttachments = true;
    _safeNotify();
    try {
      final ext = _ext(att);
      att.label = newBase.trim(); // guardamos sem extensão

      if (contractData.id != null && contractData.id!.isNotEmpty) {
        await _saveAttachmentsToDoc(contractData.id!, _attachments);
      }

      await refreshContractDocs();

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Rótulo atualizado'),
          subtitle: Text(ext.isNotEmpty ? '$newBase.$ext' : newBase),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      _busyAttachments = false;
      _safeNotify();
    }
  }

  // =======================================================================
  // CICLO DE VIDA
  // =======================================================================
  @override
  void dispose() {
    _disposed = true;

    contractCompanyLeaderCtrl.dispose();
    contractCompaniesInvolvedCtrl.dispose();
    cnoNumberCtrl.dispose();
    cnpjNumberCtrl.dispose();
    generalNumberCtrl.dispose();

    contractStatusCtrl.dispose();
    contractBiddingProcessNumberCtrl.dispose();
    contractNumberCtrl.dispose();
    initialValueOfContractCtrl.dispose();
    contractHighWayCtrl.dispose();
    summarySubjectContractCtrl.dispose();
    contractRegionOfStateCtrl.dispose();
    contractTextKmCtrl.dispose();
    contractTypeCtrl.dispose();
    contractWorkTypeCtrl.dispose();
    contractServiceTypeCtrl.dispose();
    datapublicacaodoeCtrl.dispose();
    initialValidityContractDaysCtrl.dispose();
    initialValidityExecutionDaysCtrl.dispose();

    contractObjectDescriptionCtrl.dispose();

    regionalManagerCtrl.dispose();
    managerIdCtrl.dispose();
    managerPhoneNumberCtrl.dispose();
    cpfContractManagerCtrl.dispose();
    contractManagerArtNumberCtrl.dispose();

    super.dispose();
  }

  Future<void> initialize() async {
    geoManager.loadLimitsRegionalsPolygonDERAL();

    allContracts = store.all;
    if (allContracts.isEmpty && !store.loading) {
      await store.refresh();
      if (_disposed) return;
      allContracts = store.all;
    }

    await reportsMeasurementStore.ensureAllLoaded();
    await adjustmentsStore.ensureAllLoaded();
    await revisionsStore.ensureAllLoaded();
    if (_disposed) return;

    allMeasurements = reportsMeasurementStore.all;

    filteredContracts = allContracts;
    uniqueCompanies = _extractCompanies(allContracts);

    await aplicarFiltrosERecalcular();

    if (_disposed) return;
    initialized = true;
    _safeNotify();
  }

  Future<void> init(BuildContext context, {ContractData? initial}) async {
    contractData = _clone(initial ?? ContractData.empty());
    _fillControllersFromModel();
    await refreshContractDocs();
    notifyListeners();
  }

  Future<void> refreshAndRecalc() async {
    final runId = ++_applyRunId;
    allContracts = store.all;
    allMeasurements = reportsMeasurementStore.all;
    filteredContracts = allContracts;

    if (_disposed || runId != _applyRunId) return;
    await aplicarFiltrosERecalcular();
  }

  Future<void> onHotReload() => refreshAndRecalc();

  bool get houveInteracaoComFiltros =>
      selectedStatus != null || selectedCompany != null || selectedRegions.isNotEmpty;

  Future<void> onStatusSelected(String? status) async {
    if (selectedStatus?.toUpperCase() == status?.toUpperCase()) {
      _limparTudo();
    } else {
      selectedStatus = status;
      selectedCompany = null;
      selectedCompanyIndex = null;
      selectedRegion = null;
      selectedRegionIndex = null;

      selectedRegions = store.all
          .where((c) => (c.contractStatus ?? '').toUpperCase() == status?.toUpperCase())
          .map((c) => (c.regionOfState ?? '').trim().toUpperCase())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
    }
    await aplicarFiltrosERecalcular();
  }

  Future<void> onCompanySelected(String company) async {
    final isSame = selectedCompany?.toUpperCase() == company.toUpperCase();

    if (isSame) {
      selectedCompany = null;
      selectedCompanyIndex = null;
      selectedRegions = [];
    } else {
      selectedCompany = company;
      selectedCompanyIndex =
          uniqueCompanies.indexWhere((e) => e.toUpperCase() == company.toUpperCase());

      final contratosEmpresa = store.all.where(
            (c) => (c.companyLeader ?? '').toUpperCase() == company.toUpperCase(),
      );

      selectedRegions = contratosEmpresa
          .map((c) => (c.regionOfState ?? '').trim().toUpperCase())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();
    }
    await aplicarFiltrosERecalcular();
  }

  Future<void> onRegionSelected(String? region) async {
    final same = region != null && selectedRegions.contains(region.toUpperCase());

    if (region == null || same) {
      selectedRegion = null;
      selectedRegions = [];
      selectedRegionIndex = null;
    } else {
      selectedRegion = region;
      selectedRegions = [region.toUpperCase()];
      selectedRegionIndex =
          ContractRules.regions.indexWhere((r) => r.toUpperCase() == region.toUpperCase());
    }
    await aplicarFiltrosERecalcular();
  }

  Future<void> limparSelecoes() async {
    _limparTudo();
    await aplicarFiltrosERecalcular();
  }

  void _limparTudo() {
    selectedStatus = null;
    selectedCompany = null;
    selectedCompanyIndex = null;
    selectedRegion = null;
    selectedRegionIndex = null;
    selectedRegions = [];
  }

  void filterContracts() {
    allContracts = store.all;

    final base = allContracts;

    filteredContracts = base.where((c) {
      final region = (c.regionOfState ?? '').toUpperCase();
      final company = (c.companyLeader ?? '').toUpperCase();
      final status = (c.contractStatus ?? '').toUpperCase();

      final matchCompany =
          selectedCompany == null || company == selectedCompany!.toUpperCase();
      final matchRegion =
          selectedRegions.isEmpty || selectedRegions.any((r) => region.contains(r));
      final matchStatus =
          selectedStatus == null || status == selectedStatus!.toUpperCase();
      return matchCompany && matchRegion && matchStatus;
    }).toList();
  }

  List<String> _extractCompanies(List<ContractData> data) {
    final set = <String>{for (final c in data) (c.companyLeader ?? 'NÃO INFORMADO').trim().toUpperCase()};
    final list = set.toList()..sort();
    return list;
  }

  String? _idToString(Object? id) {
    if (id == null) return null;
    try {
      final dynamic dyn = id;
      final hasId = (() {
        try {
          return (dyn as dynamic).id is String;
        } catch (_) {
          return false;
        }
      })();
      if (hasId) return (dyn as dynamic).id as String;
    } catch (_) {}
    return id.toString();
  }

  // =========================
  // HELPERS: contractId
  // =========================
  String? _parseContractIdFromPath(String? p) {
    if (p == null || p.isEmpty) return null;
    final m = RegExp(r'/contracts/([^/]+)').firstMatch(p);
    return m != null ? m.group(1) : null;
  }

  String? _dynString(dynamic v) {
    try {
      if (v == null) return null;
      if (v is String && v.trim().isNotEmpty) return v.trim();
      final id = (v as dynamic).id;
      if (id is String && id.trim().isNotEmpty) return id.trim();
    } catch (_) {}
    return null;
  }

  /// Extrai o contractId de diferentes modelos/estruturas,
  /// tentando: campo direto -> campos alternativos -> path -> id contendo path.
  String? _extractContractId(dynamic entry) {
    try {
      // 1) campo direto ou variantes
      final direct =
          _dynString((entry as dynamic).contractId) ??
              _dynString((entry as dynamic).idContract) ??
              _dynString((entry as dynamic).contractRef);
      if (direct != null) return direct;

      // 2) caminhos comuns
      final path =
          (entry as dynamic).path ??
              (entry as dynamic).docPath ??
              (entry as dynamic).parentPath ??
              (entry as dynamic).fullPath ??
              (entry as dynamic).storagePath ??
              (entry as dynamic).measurementPath;
      final fromPath = _parseContractIdFromPath(path?.toString());
      if (fromPath != null) return fromPath;

      // 3) fallback: id que contenha o caminho
      final idMaybePath = (entry as dynamic).id?.toString();
      final fromId = _parseContractIdFromPath(idMaybePath);
      if (fromId != null) return fromId;
    } catch (_) {}
    return null;
  }

  Future<void> _calcularTotaisIniciais() async {
    totaisStatusIniciais.clear();
    totaisEmpresaIniciais.clear();
    totaisRegiaoIniciais.clear();

    for (final contrato in filteredContracts) {
      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor = contrato.initialValueContract ?? 0.0;

      totaisStatusIniciais[status] = (totaisStatusIniciais[status] ?? 0.0) + valor;
      totaisEmpresaIniciais[empresa] = (totaisEmpresaIniciais[empresa] ?? 0.0) + valor;
      totaisRegiaoIniciais[regiao] = (totaisRegiaoIniciais[regiao] ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisAditivos() async {
    final contratosIds = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };

    final aditivos = await additivesStore.getForContractIds(contratosIds);
    if (_disposed) return;

    totaisStatusAditivos.clear();
    totaisEmpresaAditivos.clear();
    totaisRegiaoAditivos.clear();

    final byId = <String, ContractData>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!: c,
    };

    for (final ad in aditivos) {
      final adId = _idToString(ad.contractId);
      final contrato = adId == null ? null : byId[adId];
      if (contrato == null) continue;

      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor = ad.additiveValue ?? 0.0;

      totaisStatusAditivos[status] = (totaisStatusAditivos[status] ?? 0.0) + valor;
      totaisEmpresaAditivos[empresa] = (totaisEmpresaAditivos[empresa] ?? 0.0) + valor;
      totaisRegiaoAditivos[regiao] = (totaisRegiaoAditivos[regiao] ?? 0.0) + valor;
    }
  }

  Future<void> _calcularTotaisApostilas() async {
    final contratosIds = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };

    final apostilas = await apostillesStore.getForContractIds(contratosIds);
    if (_disposed) return;

    totaisStatusApostilas.clear();
    totaisEmpresaApostilas.clear();
    totaisRegiaoApostilas.clear();

    final byId = <String, ContractData>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!: c,
    };

    for (final ap in apostilas) {
      final apId = _idToString(ap.contractId);
      final contrato = apId == null ? null : byId[apId];
      if (contrato == null) continue;

      final status = contrato.contractStatus ?? 'SEM STATUS';
      final empresa = contrato.companyLeader ?? 'SEM EMPRESA';
      final regiao = contrato.regionOfState ?? 'SEM REGIÃO';
      final valor = ap.apostilleValue ?? 0.0;

      totaisStatusApostilas[status] = (totaisStatusApostilas[status] ?? 0.0) + valor;
      totaisEmpresaApostilas[empresa] =
          (totaisEmpresaApostilas[empresa] ?? 0.0) + valor;
      totaisRegiaoApostilas[regiao] =
          (totaisRegiaoApostilas[regiao] ?? 0.0) + valor;
    }
  }

  // =========================
  // TOTALIZAÇÃO por FILTRO ATUAL (apenas contratos visíveis)
  // =========================
  Future<void> _calcularTotaisMedicoes() async {
    final idsFiltro = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };

    allMeasurements = reportsMeasurementStore.all;

    final filtradas = allMeasurements.where((m) {
      final cid = _extractContractId(m);
      return cid != null && idsFiltro.contains(cid);
    }).toList();

    _totalMedicoes = reportsMeasurementStore.sumMedicoes(filtradas);
  }

  Future<void> _calcularTotaisReajustes() async {
    final idsFiltro = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };

    final entries = adjustmentsStore.all;
    final filtradas = entries.where((e) {
      final cid = _extractContractId(e);
      return cid != null && idsFiltro.contains(cid);
    }).toList();

    _totalReajustes = adjustmentsStore.sumAdjustments(filtradas);
  }

  Future<void> _calcularTotaisRevisoes() async {
    final idsFiltro = <String>{
      for (final c in filteredContracts)
        if (_idToString(c.id) != null) _idToString(c.id)!,
    };

    final entries = revisionsStore.all;
    final filtradas = entries.where((e) {
      final cid = _extractContractId(e);
      return cid != null && idsFiltro.contains(cid);
    }).toList();

    _totalRevisoes = revisionsStore.sumRevisions(filtradas);
  }

  Future<void> aplicarFiltrosERecalcular() async {
    final runId = ++_applyRunId;

    allContracts = store.all;
    allMeasurements = reportsMeasurementStore.all;

    filterContracts();

    await _calcularTotaisIniciais();
    if (_disposed || runId != _applyRunId) return;

    await _calcularTotaisAditivos();
    if (_disposed || runId != _applyRunId) return;

    await _calcularTotaisApostilas();
    if (_disposed || runId != _applyRunId) return;

    await _calcularTotaisMedicoes();
    if (_disposed || runId != _applyRunId) return;

    await _calcularTotaisReajustes();
    if (_disposed || runId != _applyRunId) return;

    await _calcularTotaisRevisoes();
    if (_disposed || runId != _applyRunId) return;

    uniqueCompanies = _extractCompanies(allContracts);
    _safeNotify();
  }

  void onTipoDeValorSelecionado(String novoTipo) {
    tipoDeValorSelecionado = novoTipo;
    _safeNotify();
  }

  Map<String, double> get totaisStatusAtuais {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return totaisStatusIniciais;
      case 'Total em aditivos':
        return totaisStatusAditivos;
      case 'Total em apostilas':
        return totaisStatusApostilas;
      case 'Somatório total':
      default:
        return _somarMapas([
          totaisStatusIniciais,
          totaisStatusAditivos,
          totaisStatusApostilas,
        ]);
    }
  }

  Map<String, double> get totaisRegiaoAtuais {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return totaisRegiaoIniciais;
      case 'Total em aditivos':
        return totaisRegiaoAditivos;
      case 'Total em apostilas':
        return totaisRegiaoApostilas;
      case 'Somatório total':
      default:
        return _somarMapas([
          totaisRegiaoIniciais,
          totaisRegiaoAditivos,
          totaisRegiaoApostilas,
        ]);
    }
  }

  Map<String, double> get totaisEmpresaAtuais {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return totaisEmpresaIniciais;
      case 'Total em aditivos':
        return totaisEmpresaAditivos;
      case 'Total em apostilas':
        return totaisEmpresaApostilas;
      case 'Somatório total':
      default:
        return _somarMapas([
          totaisEmpresaIniciais,
          totaisEmpresaAditivos,
          totaisEmpresaApostilas,
        ]);
    }
  }

  Map<String, double> _somarMapas(List<Map<String, double>> mapas) {
    final Map<String, double> resultado = {};
    for (final mapa in mapas) {
      for (final entry in mapa.entries) {
        resultado[entry.key] = (resultado[entry.key] ?? 0.0) + entry.value;
      }
    }
    return resultado;
  }

  List<String> get labelsStatusGeneralContracts {
    final entries = totaisStatusAtuais.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  List<double> get valuesStatusGeneralContracts {
    final entries = totaisStatusAtuais.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.value).toList();
  }

  List<String> get labelsRegionOfMap => ContractRules.regions;
  List<double?> get valuesRegionOfMap =>
      ContractRules.regions.map((r) => totaisRegiaoAtuais[r]).toList();

  List<Color> get barColorsRegion {
    return List.generate(ContractRules.regions.length, (i) {
      final valor = valuesRegionOfMap[i] ?? 0.0;
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedRegionIndex != null && selectedRegionIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.blueAccent;
    });
  }

  List<String> get labelsCompany => uniqueCompanies;
  List<double> get valuesCompany =>
      uniqueCompanies.map((e) => totaisEmpresaAtuais[e] ?? 0.0).toList();

  List<Color> get barColorsEmpresa {
    return List.generate(uniqueCompanies.length, (i) {
      final valor = valuesCompany[i];
      if (valor == 0.0) return Colors.grey.shade300;
      if (selectedCompanyIndex != null && selectedCompanyIndex == i) {
        return Colors.orangeAccent;
      }
      return Colors.blueAccent;
    });
  }

  List<String> get radarServiceLabels {
    final set = <String>{};
    for (final c in allContracts) {
      final s = (c.contractServices ?? '').trim();
      if (s.isNotEmpty) set.add(s);
    }
    final ordered = set.toList()..sort();
    return ordered;
  }

  double _valorRadarParaContrato(ContractData c) {
    switch (tipoDeValorSelecionado) {
      case 'Valor contratado':
        return c.initialValueContract ?? 0.0;
      case 'Total em aditivos':
        return 0.0;
      case 'Total em apostilas':
        return 0.0;
      case 'Somatório total':
      default:
        return (c.initialValueContract ?? 0.0);
    }
  }

  List<double> _sumRadarPorContractServices(
      List<ContractData> base, List<String> labels) {
    final mapa = {for (final t in labels) t: 0.0};

    for (final c in base) {
      final valor = _valorRadarParaContrato(c);
      if (valor == 0) continue;

      final service = (c.contractServices ?? '').trim();
      if (service.isEmpty) continue;

      if (mapa.containsKey(service)) {
        mapa[service] = (mapa[service] ?? 0.0) + valor;
      }
    }
    return labels.map((t) => mapa[t] ?? 0.0).toList();
  }

  List<double> radarServiceValuesGeral() {
    final labels = radarServiceLabels;
    return _sumRadarPorContractServices(filteredContracts, labels);
  }

  List<double> radarServiceValuesEmpresaSelecionada() {
    if (selectedCompany == null) return const [];
    final labels = radarServiceLabels;
    final alvo = (selectedCompany ?? '').toUpperCase();

    final base = filteredContracts
        .where((c) => (c.companyLeader ?? '').toUpperCase() == alvo)
        .toList();

    return _sumRadarPorContractServices(base, labels);
  }

  List<double> radarServiceValuesRegiaoSelecionada() {
    if (selectedRegion == null && selectedRegions.isEmpty) return const [];
    final labels = radarServiceLabels;
    final alvo = (selectedRegion ?? selectedRegions.first).toUpperCase();

    final base = filteredContracts
        .where((c) => (c.regionOfState ?? '').toUpperCase().contains(alvo))
        .toList();

    return _sumRadarPorContractServices(base, labels);
  }

  List<RadarSeriesData> radarDatasetsServices({
    required Color primary,
    required Color warning,
    required Color success,
  }) {
    final labels = radarServiceLabels;
    if (labels.isEmpty) return const <RadarSeriesData>[];

    final geral = radarServiceValuesGeral();
    final empresa = radarServiceValuesEmpresaSelecionada();
    final regiao = radarServiceValuesRegiaoSelecionada();

    final List<RadarSeriesData> raw = [
      RadarSeriesData(
        name: 'Geral',
        values: geral,
        color: primary,
      ),
      if (empresa.isNotEmpty)
        RadarSeriesData(
          name: selectedCompany ?? 'Empresa',
          values: empresa,
          color: warning,
        ),
      if (regiao.isNotEmpty)
        RadarSeriesData(
          name: selectedRegion ??
              (selectedRegions.isNotEmpty ? selectedRegions.first : 'Região'),
          values: regiao,
          color: success,
        ),
    ];

    return raw
        .where((s) => s.values.length == labels.length && s.values.any((v) => v > 0))
        .toList(growable: false);
  }

  List<TreemapItem> get treemapRodovias {
    final mapa = <String, double>{};

    for (final contrato in filteredContracts) {
      final rodovia = (contrato.mainContractHighway ?? 'SEM RODOVIA').trim();
      if (rodovia.isEmpty) continue;

      double valor;
      switch (tipoDeValorSelecionado) {
        case 'Valor contratado':
          valor = contrato.initialValueContract ?? 0.0;
          break;
        case 'Total em aditivos':
          valor = 0.0;
          break;
        case 'Total em apostilas':
          valor = 0.0;
          break;
        case 'Somatório total':
        default:
          valor = (contrato.initialValueContract ?? 0.0);
          break;
      }

      if (valor == 0.0) continue;
      mapa[rodovia] = (mapa[rodovia] ?? 0.0) + valor;
    }

    final ordenado = mapa.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = <Color>[
      Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.red, Colors.teal, Colors.indigo, Colors.brown,
      Colors.cyan, Colors.deepOrange, Colors.pink, Colors.lime,
    ];

    int i = 0;
    return ordenado.map((e) {
      final color = colors[i % colors.length];
      i++;
      return TreemapItem(
        label: e.key,
        value: e.value,
        color: color,
      );
    }).toList(growable: false);
  }

  // =======================================================================
  // ------ BLOCO DE FORM ---------------------------------------------------
  // =======================================================================
  Future<void> saveInformation(
      BuildContext context, {
        void Function(ContractData)? onSaved,
      }) async {
    showErrors = true;
    notifyListeners();
    if (!(formKey.currentState?.validate() ?? false)) return;

    _applyControllersToModel();

    isSaving = true;
    notifyListeners();

    try {
      final saved = await store.saveOrUpdate(contractData);
      contractData = _clone(saved);
      onSaved?.call(contractData);

      NotificationCenter.instance.show(
        AppNotification(
          title: const Text('Contrato salvo'),
          type: AppNotificationType.success,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao salvar contrato: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> salvarUrlPdfDoContratoEAtualizarUI(
      BuildContext context, {
        required String contractId,
        required String url,
        void Function(ContractData)? onSaved,
      }) async {
    try {
      await store.salvarUrlPdfDoContrato(contractId, url);
      final updated = await store.getById(contractId);
      if (updated != null) {
        contractData = _clone(updated);
        onSaved?.call(contractData);
        notifyListeners();

        NotificationCenter.instance.show(
          AppNotification(
            title: const Text('PDF do contrato atualizado'),
            type: AppNotificationType.success,
            details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
          ),
        );
      }
    } catch (e) {
      NotificationCenter.instance.show(
        AppNotification(
          title: Text('Erro ao atualizar PDF: $e'),
          type: AppNotificationType.error,
          details: Text('${_userName()} • ${_stamp()}', style: const TextStyle(fontSize: 11)),
        ),
      );
    }
  }

  ContractData _clone(ContractData src) {
    return ContractData(
      id: src.id,
      managerId: src.managerId,
      summarySubjectContract: src.summarySubjectContract,
      contractNumber: src.contractNumber,
      mainContractHighway: src.mainContractHighway,
      restriction: src.restriction,
      contractServices: src.contractServices,
      contractManagerArtNumber: src.contractManagerArtNumber,
      contractExtKm: src.contractExtKm,
      regionOfState: src.regionOfState,
      managerPhoneNumber: src.managerPhoneNumber,
      companyLeader: src.companyLeader,
      generalNumber: src.generalNumber,
      contractNumberProcess: src.contractNumberProcess,
      automaticNumberSiafe: src.automaticNumberSiafe,
      physicalPercentage: src.physicalPercentage,
      regionalManager: src.regionalManager,
      contractStatus: src.contractStatus,
      contractObjectDescription: src.contractObjectDescription,
      contractType: src.contractType,
      workType: src.workType,
      contractCompaniesInvolved: src.contractCompaniesInvolved,
      urlContractPdf: src.urlContractPdf,
      initialValidityExecutionDays: src.initialValidityExecutionDays,
      initialValidityContractDays: src.initialValidityContractDays,
      cpfContractManager: src.cpfContractManager,
      cnoNumber: src.cnoNumber,
      cnpjNumber: src.cnpjNumber,
      existContract: src.existContract,
      publicationDateDoe: src.publicationDateDoe,
      financialPercentage: src.financialPercentage,
      initialValueContract: src.initialValueContract,
      permissionContractId: Map<String, Map<String, bool>>.fromEntries(
        src.permissionContractId.entries.map(
              (e) => MapEntry(e.key, Map<String, bool>.from(e.value)),
        ),
      ),
    );
  }

  void _fillControllersFromModel() {
    contractCompanyLeaderCtrl.text = (contractData.companyLeader ?? '');
    contractCompaniesInvolvedCtrl.text = (contractData.contractCompaniesInvolved ?? '');
    cnoNumberCtrl.text = (contractData.cnoNumber ?? '');
    cnpjNumberCtrl.text = (contractData.cnpjNumber?.toString() ?? '');
    generalNumberCtrl.text = (contractData.generalNumber ?? '');

    contractStatusCtrl.text = (contractData.contractStatus ?? '');
    contractBiddingProcessNumberCtrl.text = (contractData.contractNumberProcess ?? '');
    contractNumberCtrl.text = (contractData.contractNumber ?? '');
    initialValueOfContractCtrl.text = _formatCurrency(contractData.initialValueContract);
    contractHighWayCtrl.text = (contractData.mainContractHighway ?? '');
    summarySubjectContractCtrl.text = (contractData.summarySubjectContract ?? '');
    contractRegionOfStateCtrl.text = (contractData.regionOfState ?? '');
    contractTextKmCtrl.text = _formatNumber(contractData.contractExtKm, decimals: 3);
    contractTypeCtrl.text = (contractData.contractType ?? '');
    contractWorkTypeCtrl.text = (contractData.workType ?? '');
    contractServiceTypeCtrl.text = (contractData.contractServices ?? '');

    datapublicacaodoeCtrl.text = contractData.publicationDateDoe != null
        ? _dateToDDMMYYYY(contractData.publicationDateDoe!)
        : '';

    initialValidityContractDaysCtrl.text =
    (contractData.initialValidityContractDays?.toString() ?? '');
    initialValidityExecutionDaysCtrl.text =
    (contractData.initialValidityExecutionDays?.toString() ?? '');

    contractObjectDescriptionCtrl.text = (contractData.contractObjectDescription ?? '');

    regionalManagerCtrl.text = (contractData.regionalManager ?? '');
    managerIdCtrl.text = (contractData.managerId ?? '');
    managerPhoneNumberCtrl.text = (contractData.managerPhoneNumber ?? '');
    cpfContractManagerCtrl.text = (contractData.cpfContractManager?.toString() ?? '');
    contractManagerArtNumberCtrl.text = (contractData.contractManagerArtNumber ?? '');
  }

  void _applyControllersToModel() {
    contractData.companyLeader = _nullIfEmpty(contractCompanyLeaderCtrl.text);
    contractData.contractCompaniesInvolved = _nullIfEmpty(contractCompaniesInvolvedCtrl.text);
    contractData.cnoNumber = _nullIfEmpty(cnoNumberCtrl.text);
    contractData.cnpjNumber = _tryParseInt(cnpjNumberCtrl.text);
    contractData.generalNumber = _nullIfEmpty(generalNumberCtrl.text);

    contractData.contractStatus =
        _normalizeFromList(contractStatusCtrl.text, ContractRules.statusTypes);
    contractData.contractNumberProcess = _nullIfEmpty(contractBiddingProcessNumberCtrl.text);
    contractData.contractNumber = _nullIfEmpty(contractNumberCtrl.text);
    contractData.initialValueContract = _parseCurrency(initialValueOfContractCtrl.text);
    contractData.mainContractHighway = _nullIfEmpty(contractHighWayCtrl.text);
    contractData.summarySubjectContract = _nullIfEmpty(summarySubjectContractCtrl.text);
    contractData.regionOfState = _nullIfEmpty(contractRegionOfStateCtrl.text);
    contractData.contractExtKm = _tryParseDouble(contractTextKmCtrl.text);
    contractData.contractType = _nullIfEmpty(contractTypeCtrl.text);
    contractData.workType =
        _normalizeFromList(contractWorkTypeCtrl.text, ContractRules.workTypes);
    contractData.contractServices = _nullIfEmpty(contractServiceTypeCtrl.text);

    // publicationDateDoe é setado pelo CustomDateField via onChanged

    contractData.initialValidityContractDays =
        _tryParseInt(initialValidityContractDaysCtrl.text);
    contractData.initialValidityExecutionDays =
        _tryParseInt(initialValidityExecutionDaysCtrl.text);

    contractData.contractObjectDescription = _nullIfEmpty(contractObjectDescriptionCtrl.text);

    contractData.regionalManager = _nullIfEmpty(regionalManagerCtrl.text);
    contractData.managerId = _nullIfEmpty(managerIdCtrl.text);
    contractData.managerPhoneNumber = _nullIfEmpty(managerPhoneNumberCtrl.text);
    contractData.cpfContractManager = _tryParseInt(cpfContractManagerCtrl.text);
    contractData.contractManagerArtNumber = _nullIfEmpty(contractManagerArtNumberCtrl.text);
  }

  String _nullIfEmpty(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? '' : s;
  }

  String _formatCurrency(double? value) {
    if (value == null) return '';
    return 'R\$ ${_formatNumber(value, decimals: 2, decimalComma: true, thousandsDot: true)}';
  }

  String _formatNumber(num? value,
      {int decimals = 0, bool decimalComma = false, bool thousandsDot = false}) {
    if (value == null) return '';
    String s = value.toStringAsFixed(decimals);
    if (decimalComma) s = s.replaceAll('.', ',');
    if (thousandsDot) {
      final parts = s.split(decimalComma ? ',' : '.');
      String intPart = parts[0];
      String fracPart = parts.length > 1 ? parts[1] : '';
      final buf = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        final remain = intPart.length - i - 1;
        buf.write(intPart[i]);
        if (remain > 0 && (remain % 3 == 0)) buf.write('.');
      }
      s = buf.toString();
      if (decimals > 0) {
        s = '$s${decimalComma ? ',' : '.'}$fracPart';
      }
    }
    return s;
  }

  String _dateToDDMMYYYY(DateTime d) {
    final dd = d.day.toString().padLeft(2,'0');
    final mm = d.month.toString().padLeft(2,'0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  double? _parseCurrency(String? text) {
    if (text == null) return null;
    var s = text.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll('R\$', '').replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(s);
  }

  double? _tryParseDouble(String? text) {
    if (text == null) return null;
    final s = text.trim().replaceAll(',', '.');
    return double.tryParse(s);
  }

  int? _tryParseInt(String? text) {
    if (text == null) return null;
    final s = text.trim().replaceAll(RegExp(r'[^0-9-]'), '');
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  String? _normalizeFromList(String? value, List<String> candidates) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final found = candidates.firstWhereOrNull(
          (c) => c.toUpperCase() == v.toUpperCase(),
    );
    return found ?? v;
  }

  // =======================================================================
  // ======= TOTAIS POR CONTRATO (opcional p/ cards individuais) ===========
  // =======================================================================

  double totalMedicoesDoContrato(String contractId) {
    final filtradas = reportsMeasurementStore.all.where((m) {
      final cid = _extractContractId(m);
      return cid == contractId;
    });
    return reportsMeasurementStore.sumMedicoes(filtradas.toList());
  }

  double totalReajustesDoContrato(String contractId) {
    final filtradas = adjustmentsStore.all.where((e) {
      final cid = _extractContractId(e);
      return cid == contractId;
    });
    return adjustmentsStore.sumAdjustments(filtradas.toList());
  }

  double totalRevisoesDoContrato(String contractId) {
    final filtradas = revisionsStore.all.where((e) {
      final cid = _extractContractId(e);
      return cid == contractId;
    });
    return revisionsStore.sumRevisions(filtradas.toList());
  }

  // =======================================================================
  // ======= (NOVO) MÉDIA R$/KM POR SERVIÇO – para a CostPerKmRuler ========
  // =======================================================================

  /// Normaliza o nome do serviço
  String _normService(String? s) => (s ?? '').trim().toUpperCase();

  /// Base para cálculo: usa os contratos filtrados (gráficos) ou todos
  List<ContractData> _base({required bool useFiltered}) =>
      useFiltered ? filteredContracts : allContracts;

  /// Média ponderada (por km) de R$/km para TODOS os serviços na base.
  /// Retorna: { 'PAVIMENTAÇÃO': 123456.78, 'RESTAURAÇÃO': 98765.43, ... }
  Map<String, double> avgCostPerKmByService({bool useFiltered = true}) {
    final base = _base(useFiltered: useFiltered);

    final sumValueByService = <String, double>{};
    final sumKmByService = <String, double>{};

    for (final c in base) {
      final svc = _normService(c.contractServices);
      final val = (c.initialValueContract ?? 0).toDouble();
      final km  = (c.contractExtKm ?? 0).toDouble();

      if (svc.isEmpty) continue;
      if (val <= 0 || km <= 0) continue;

      sumValueByService[svc] = (sumValueByService[svc] ?? 0) + val;
      sumKmByService[svc]    = (sumKmByService[svc] ?? 0) + km;
    }

    final result = <String, double>{};
    for (final s in sumValueByService.keys) {
      final totVal = sumValueByService[s] ?? 0;
      final totKm  = sumKmByService[s] ?? 0;
      if (totKm > 0) result[s] = totVal / totKm;
    }
    return result;
  }

  /// Média ponderada (por km) de R$/km para UM serviço específico.
  /// Ex.: avgCostPerKmForService('PAVIMENTAÇÃO')
  double? avgCostPerKmForService(String service, {bool useFiltered = true}) {
    final base = _base(useFiltered: useFiltered);
    final alvo = _normService(service);

    double totalVal = 0;
    double totalKm  = 0;

    for (final c in base) {
      if (_normService(c.contractServices) != alvo) continue;

      final val = (c.initialValueContract ?? 0).toDouble();
      final km  = (c.contractExtKm ?? 0).toDouble();

      if (val <= 0 || km <= 0) continue;

      totalVal += val;
      totalKm  += km;
    }
    if (totalKm <= 0) return null;
    return totalVal / totalKm;
  }

  /// Conveniência: média do MESMO serviço do contrato atualmente em edição/visualização.
  double? avgCostPerKmForSelectedContractService({bool useFiltered = true}) {
    final svc = _normService(contractData.contractServices);
    if (svc.isEmpty) return null;
    return avgCostPerKmForService(svc, useFiltered: useFiltered);
  }
}
