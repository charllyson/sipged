// lib/_blocs/panels/overview-dashboard/process_controller.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Data / Store (contratos)
import 'package:siged/_blocs/_process/process_data.dart';
import 'package:siged/_blocs/_process/process_store.dart';
import 'package:siged/_blocs/_process/process_storage_bloc.dart';

// UI auxiliares
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_services/pdf/pdf_preview.dart';
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

// Normalizações (listas válidas)
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';

// Stores adicionais que você pediu para manter neste controller
import 'package:siged/_blocs/process/additives/additive_store.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';
import 'package:siged/_blocs/process/report/report_measurement_store.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_store.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_store.dart';

class ProcessController extends ChangeNotifier {
  ProcessController({
    required this.store,
    required this.processStorageBloc,

    // Mantidos aqui conforme solicitado
    required this.additivesStore,
    required this.apostillesStore,
    required this.reportsMeasurementStore,
    required this.adjustmentsStore,
    required this.revisionsStore,

    this.moduleKey = 'contracts',
    this.forceEditable = true,
  });

  // =======================================================================
  // INJEÇÕES
  // =======================================================================
  final ProcessStore store;
  final ProcessStorageBloc processStorageBloc;

  final AdditivesStore additivesStore;
  final ApostillesStore apostillesStore;
  final ReportsMeasurementStore reportsMeasurementStore;
  final AdjustmentsMeasurementStore adjustmentsStore;
  final RevisionsMeasurementStore revisionsStore;

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

  late ProcessData contractData;

  // ===== Controllers de texto (empresa)
  final TextEditingController companyLeaderCtrl = TextEditingController();
  final TextEditingController companiesInvolvedCtrl = TextEditingController();
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
      notifyListeners();
      return;
    }

    try {
      final files = await processStorageBloc.listarDocsContrato(contractId: id);

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
    notifyListeners();
  }

  Future<void> addContractDoc(BuildContext context) async {
    final id = contractData.id;
    if (id == null) return;

    _busyAttachments = true;
    notifyListeners();

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

      await processStorageBloc.uploadDocContratoWithPicker(
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
      notifyListeners();
    }
  }

  /// Abre PDF num viewer interno; outros formatos seguem externos.
  Future<void> openContractDocAt(BuildContext context, int i) async {
    if (i < 0 || i >= _attachments.length) return;

    selectedContractDocIndex = i;
    notifyListeners();

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
    notifyListeners();
    try {
      final ok = await processStorageBloc.deleteByUrl(att.url);
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
      notifyListeners();
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
    notifyListeners();
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
      notifyListeners();
    }
  }

  // =======================================================================
  // CICLO DE VIDA
  // =======================================================================
  @override
  void dispose() {
    companyLeaderCtrl.dispose();
    companiesInvolvedCtrl.dispose();
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
    super.dispose();
  }

  /// Inicializa o formulário com um contrato (novo ou existente) e carrega anexos.
  Future<void> init(BuildContext context, {ProcessData? initial}) async {
    contractData = _clone(initial ?? ProcessData.empty());
    _fillControllersFromModel();
    await refreshContractDocs();
    notifyListeners();
  }

  // =======================================================================
  // SALVAR / ATUALIZAR
  // =======================================================================
  Future<void> saveInformation(
      BuildContext context, {
        void Function(ProcessData)? onSaved,
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
        void Function(ProcessData)? onSaved,
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

  // =======================================================================
  // HELPERS DE MODELO / CONTROLLERS
  // =======================================================================
  ProcessData _clone(ProcessData src) {
    return ProcessData(
      id: src.id,
      summarySubject: src.summarySubject,
      contractNumber: src.contractNumber,
      mainHighway: src.mainHighway,
      services: src.services,
      ext: src.ext,
      region: src.region,
      companyLeader: src.companyLeader,
      numberProcess: src.numberProcess,
      status: src.status,
      workType: src.workType,
      contractCompaniesInvolved: src.contractCompaniesInvolved,
      urlContractPdf: src.urlContractPdf,
      initialValidityExecution: src.initialValidityExecution,
      initialValidityContract: src.initialValidityContract,
      publicationDate: src.publicationDate,
      initialValueContract: src.initialValueContract,
      permissionContractId: Map<String, Map<String, bool>>.fromEntries(
        src.permissionContractId.entries.map(
              (e) => MapEntry(e.key, Map<String, bool>.from(e.value)),
        ),
      ),
    );
  }

  void _fillControllersFromModel() {
    companyLeaderCtrl.text = (contractData.companyLeader ?? '');
    companiesInvolvedCtrl.text = (contractData.contractCompaniesInvolved ?? '');

    contractStatusCtrl.text = (contractData.status ?? '');
    contractBiddingProcessNumberCtrl.text = (contractData.numberProcess ?? '');
    contractNumberCtrl.text = (contractData.contractNumber ?? '');
    initialValueOfContractCtrl.text = _formatCurrency(contractData.initialValueContract);
    contractHighWayCtrl.text = (contractData.mainHighway ?? '');
    summarySubjectContractCtrl.text = (contractData.summarySubject ?? '');
    contractRegionOfStateCtrl.text = (contractData.region ?? '');
    contractTextKmCtrl.text = _formatNumber(contractData.ext, decimals: 3);
    contractWorkTypeCtrl.text = (contractData.workType ?? '');
    contractServiceTypeCtrl.text = (contractData.services ?? '');

    datapublicacaodoeCtrl.text = contractData.publicationDate != null
        ? _dateToDDMMYYYY(contractData.publicationDate!)
        : '';

    initialValidityContractDaysCtrl.text =
    (contractData.initialValidityContract?.toString() ?? '');
    initialValidityExecutionDaysCtrl.text =
    (contractData.initialValidityExecution?.toString() ?? '');

  }

  void _applyControllersToModel() {
    contractData.companyLeader = _nullIfEmpty(companyLeaderCtrl.text);
    contractData.contractCompaniesInvolved = _nullIfEmpty(companiesInvolvedCtrl.text);

    contractData.status =
        _normalizeFromList(contractStatusCtrl.text, DfdData.statusTypes);
    contractData.numberProcess = _nullIfEmpty(contractBiddingProcessNumberCtrl.text);
    contractData.contractNumber = _nullIfEmpty(contractNumberCtrl.text);
    contractData.initialValueContract = _parseCurrency(initialValueOfContractCtrl.text);
    contractData.mainHighway = _nullIfEmpty(contractHighWayCtrl.text);
    contractData.summarySubject = _nullIfEmpty(summarySubjectContractCtrl.text);
    contractData.region = _nullIfEmpty(contractRegionOfStateCtrl.text);
    contractData.ext = _tryParseDouble(contractTextKmCtrl.text);
    contractData.workType =
        _normalizeFromList(contractWorkTypeCtrl.text, DfdData.workTypes);
    contractData.services = _nullIfEmpty(contractServiceTypeCtrl.text);

    // publicationDateDoe é setado pelo CustomDateField via onChanged

    contractData.initialValidityContract =
        _tryParseInt(initialValidityContractDaysCtrl.text);
    contractData.initialValidityExecution =
        _tryParseInt(initialValidityExecutionDaysCtrl.text);

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
    final upper = v.toUpperCase();
    for (final c in candidates) {
      if (c.toUpperCase() == upper) return c;
    }
    return v;
  }

  // =======================================================================
  // ======= TOTAIS POR CONTRATO (opcional p/ cards individuais no form) ===
  // =======================================================================
  String? _parseContractIdFromPath(String? p) {
    if (p == null || p.isEmpty) return null;
    final m = RegExp(r'/contracts/([^/]+)').firstMatch(p);
    return m != null ? m.group(1) : null;
  }

  String? _extractContractId(dynamic entry) {
    try {
      // 1) campo direto ou variantes
      final dyn = entry as dynamic;
      final direct = (dyn.contractId ?? dyn.idContract ?? dyn.contractRef);
      if (direct is String && direct.trim().isNotEmpty) return direct.trim();

      // 2) caminhos comuns
      final path = (dyn.path ??
          dyn.docPath ??
          dyn.parentPath ??
          dyn.fullPath ??
          dyn.storagePath ??
          dyn.measurementPath)?.toString();
      final fromPath = _parseContractIdFromPath(path);
      if (fromPath != null) return fromPath;

      // 3) fallback: id que contenha o caminho
      final idMaybePath = dyn.id?.toString();
      final fromId = _parseContractIdFromPath(idMaybePath);
      if (fromId != null) return fromId;
    } catch (_) {}
    return null;
  }

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
  // ===== Compat: telas antigas do dashboard que chamam initialize() ======
  // =======================================================================
  bool initialized = true;

  /// Compatibilidade: no controller de formulário não há boot de dashboard.
  Future<void> initialize() async {
    // NO-OP: apenas garante a presença do método.
    initialized = true;
    notifyListeners();
  }

  /// Compatibilidade: recalcular agrega no dashboard; aqui não faz nada.
  Future<void> refreshAndRecalc() async {
    // NO-OP
  }

  /// Compatibilidade: handler de hot reload usado no dashboard.
  Future<void> onHotReload() async {
    // NO-OP
  }
}
