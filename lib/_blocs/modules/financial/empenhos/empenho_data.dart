import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/screens/modules/financial/finance_utils.dart';

class EmpenhoData {
  /// Coleção legada/global.
  static const String collectionName = 'empenhos';

  /// Caminho relativo dentro do tenant.
  ///
  /// Resultado final:
  /// tenants/{tenantId}/financial/empenhos/items
  static const String tenantRelativeCollectionPath = 'financial/empenhos/items';

  static String tenantCollectionPath(String tenantId) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      throw ArgumentError('tenantId não pode estar vazio.');
    }

    return 'tenants/$cleanTenantId/$tenantRelativeCollectionPath';
  }

  final String? id;

  /// Contrato pai do empenho, quando a tela estiver dentro de um contrato.
  final String? contractId;

  final String numero;

  /// Demanda/DFD selecionada.
  ///
  /// Aqui o `demandContractId` representa o contrato onde está o DFD selecionado.
  final String? demandContractId;
  final String demandLabel;

  /// Compatibilidade com modelo antigo.
  ///
  /// Mantido espelhando `demandLabel`.
  final String credor;

  /// Contratante.
  final String? companyId;
  final String? companyLabel;

  /// Fonte de recurso.
  final String? fundingSourceId;
  final String fundingSourceLabel;

  /// Compatibilidade antiga.
  ///
  /// Antes era usado como objeto/fonte.
  final String objeto;

  final DateTime date;
  final double empenhadoTotal;

  final List<AllocationSlice> slices;

  final String? pdfUrl;
  final List<Attachment>? attachments;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const EmpenhoData({
    this.id,
    this.contractId,
    required this.numero,
    this.demandContractId,
    required this.demandLabel,
    required this.credor,
    this.companyId,
    this.companyLabel,
    this.fundingSourceId,
    required this.fundingSourceLabel,
    required this.objeto,
    required this.date,
    required this.empenhadoTotal,
    this.slices = const [],
    this.pdfUrl,
    this.attachments,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  factory EmpenhoData.empty() {
    return EmpenhoData(
      numero: '',
      demandLabel: '',
      credor: '',
      fundingSourceLabel: '',
      objeto: '',
      date: DateTime.now(),
      empenhadoTotal: 0.0,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;

    if (v is num) return v.toDouble();

    if (v is String) {
      final raw = v.trim();
      if (raw.isEmpty) return null;

      final normalized = raw
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');

      return double.tryParse(normalized);
    }

    return null;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);

    if (v is String) {
      return DateTime.tryParse(v);
    }

    return null;
  }

  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }

    final raw = snap.data();

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }

    return <String, dynamic>{};
  }

  static List<AllocationSlice> _toSlices(dynamic v) {
    if (v == null) return <AllocationSlice>[];

    if (v is List) {
      return v
          .map((e) {
        if (e is AllocationSlice) return e;

        if (e is Map) {
          return AllocationSlice.fromMap(Map<String, dynamic>.from(e));
        }

        return const AllocationSlice(label: '', amount: 0.0);
      })
          .where((s) => s.label.trim().isNotEmpty || s.amount > 0)
          .toList();
    }

    return <AllocationSlice>[];
  }

  static List<Attachment>? _toAttachments(
      dynamic v, {
        String? fallbackPdfUrl,
      }) {
    if (v == null) {
      final pdf = (fallbackPdfUrl ?? '').trim();

      if (pdf.isNotEmpty) {
        return [
          Attachment(
            id: 'pdf',
            label: 'PDF do empenho',
            url: pdf,
            path: '',
            ext: '.pdf',
          ),
        ];
      }

      return null;
    }

    if (v is List) {
      final list = v.map<Attachment>((e) {
        if (e is Attachment) return e;

        return Attachment.fromMap(
          Map<String, dynamic>.from(e as Map),
        );
      }).toList();

      return list.isEmpty ? null : list;
    }

    return null;
  }

  factory EmpenhoData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);
    final pdfUrl = data['pdfUrl']?.toString();

    final demandIdRaw = data['demandContractId'] ?? data['demandId'];
    final demandId = demandIdRaw?.toString().trim();

    final demandLabelRaw = (data['demandLabel'] ?? '').toString().trim();
    final legacyCredor = (data['credor'] ?? '').toString().trim();

    final resolvedDemandLabel =
    demandLabelRaw.isNotEmpty ? demandLabelRaw : legacyCredor;

    final legacyObjeto = (data['objeto'] ?? '').toString().trim();
    final fsLabel = (data['fundingSourceLabel'] ?? '').toString().trim();

    final resolvedFundingSourceLabel =
    fsLabel.isNotEmpty ? fsLabel : legacyObjeto;

    final companyLabelRaw =
        data['companyLabel'] ?? data['companyName'] ?? data['contratante'];

    return EmpenhoData(
      id: (data['id'] as String?) ?? snap.id,
      contractId: data['contractId']?.toString(),
      numero: (data['numero'] ?? '').toString(),
      demandContractId: demandId == null || demandId.isEmpty ? null : demandId,
      demandLabel: resolvedDemandLabel,
      credor: resolvedDemandLabel,
      companyId: data['companyId']?.toString(),
      companyLabel: companyLabelRaw?.toString(),
      fundingSourceId: data['fundingSourceId']?.toString(),
      fundingSourceLabel: resolvedFundingSourceLabel,
      objeto: legacyObjeto.isNotEmpty ? legacyObjeto : resolvedFundingSourceLabel,
      date: _toDate(data['date']) ?? DateTime.now(),
      empenhadoTotal: _toDouble(data['empenhadoTotal']) ?? 0.0,
      slices: _toSlices(data['slices']),
      pdfUrl: pdfUrl,
      attachments: _toAttachments(
        data['attachments'],
        fallbackPdfUrl: pdfUrl,
      ),
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy']?.toString(),
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final resolvedDemandLabel = demandLabel.trim();
    final resolvedFundingSourceLabel = fundingSourceLabel.trim();

    final map = <String, dynamic>{
      'id': id,
      'contractId': contractId,
      'numero': numero.trim(),
      'demandContractId': demandContractId,
      'demandLabel': resolvedDemandLabel,
      'credor': resolvedDemandLabel,
      'companyId': companyId,
      'companyLabel': companyLabel,
      'fundingSourceId': fundingSourceId,
      'fundingSourceLabel': resolvedFundingSourceLabel,
      'objeto': objeto.trim().isNotEmpty
          ? objeto.trim()
          : resolvedFundingSourceLabel,
      'date': Timestamp.fromDate(date),
      'empenhadoTotal': empenhadoTotal,
      'slices': slices.map((e) => e.toMap()).toList(),
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'createdBy': createdBy,
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      'updatedBy': updatedBy,
    };

    map.removeWhere((_, v) => v == null);

    return map;
  }

  EmpenhoData copyWith({
    String? id,
    bool clearId = false,
    String? contractId,
    bool clearContractId = false,
    String? numero,
    String? demandContractId,
    bool clearDemandContractId = false,
    String? demandLabel,
    String? credor,
    String? companyId,
    bool clearCompanyId = false,
    String? companyLabel,
    bool clearCompanyLabel = false,
    String? fundingSourceId,
    bool clearFundingSourceId = false,
    String? fundingSourceLabel,
    String? objeto,
    DateTime? date,
    double? empenhadoTotal,
    List<AllocationSlice>? slices,
    String? pdfUrl,
    bool clearPdfUrl = false,
    List<Attachment>? attachments,
    bool clearAttachments = false,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    final nextDemandLabel = (demandLabel ?? this.demandLabel).trim();
    final nextFundingSourceLabel =
    (fundingSourceLabel ?? this.fundingSourceLabel).trim();

    return EmpenhoData(
      id: clearId ? null : (id ?? this.id),
      contractId: clearContractId ? null : (contractId ?? this.contractId),
      numero: numero ?? this.numero,
      demandContractId: clearDemandContractId
          ? null
          : (demandContractId ?? this.demandContractId),
      demandLabel: nextDemandLabel,
      credor: nextDemandLabel,
      companyId: clearCompanyId ? null : (companyId ?? this.companyId),
      companyLabel:
      clearCompanyLabel ? null : (companyLabel ?? this.companyLabel),
      fundingSourceId: clearFundingSourceId
          ? null
          : (fundingSourceId ?? this.fundingSourceId),
      fundingSourceLabel: nextFundingSourceLabel,
      objeto: objeto ?? this.objeto,
      date: date ?? this.date,
      empenhadoTotal: empenhadoTotal ?? this.empenhadoTotal,
      slices: slices ?? this.slices,
      pdfUrl: clearPdfUrl ? null : (pdfUrl ?? this.pdfUrl),
      attachments: clearAttachments ? null : (attachments ?? this.attachments),
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}