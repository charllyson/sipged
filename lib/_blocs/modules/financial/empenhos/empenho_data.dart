import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/screens/modules/financial/finance_utils.dart';

class EmpenhoData {
  static const String collectionName = 'empenhos';

  String? id;

  /// Contrato “pai” do empenho (se você usa a tela por contrato)
  String? contractId;

  String numero;

  /// ✅ NOVO (id + label) para DEMANDA/DFD selecionada
  /// - demandContractId: id do contrato do DFD (usado como “id” do item no autocomplete)
  /// - demandLabel: descricaoObjeto
  String? demandContractId;
  String demandLabel;

  /// compat (LEGADO): mantém string antiga para não quebrar consultas/telas antigas
  /// Você pode deixar, mas sempre espelhando demandLabel
  String credor;

  /// ✅ company vinculada ao empenho
  String? companyId;
  String? companyLabel;

  /// Fonte de recurso (id + label)
  String? fundingSourceId;
  String fundingSourceLabel;

  /// compat (LEGADO): antigo "objeto"
  String objeto;

  DateTime date;
  double empenhadoTotal;

  List<AllocationSlice> slices;

  String? pdfUrl;
  List<Attachment>? attachments;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;

  EmpenhoData({
    this.id,
    this.contractId,
    required this.numero,

    this.demandContractId,
    required this.demandLabel,

    // legado
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

  // ---------------- helpers ----------------
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  static Map<String, dynamic> _readSnapData(DocumentSnapshot snap) {
    if (snap is DocumentSnapshot<Map<String, dynamic>>) {
      return snap.data() ?? <String, dynamic>{};
    }
    final raw = snap.data();
    return (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
  }

  static List<AllocationSlice> _toSlices(dynamic v) {
    if (v == null) return <AllocationSlice>[];
    if (v is List) {
      return v.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return AllocationSlice(
          label: (m['label'] ?? '').toString(),
          amount: _toDouble(m['amount']) ?? 0.0,
        );
      }).toList();
    }
    return <AllocationSlice>[];
  }

  static List<Attachment>? _toAttachments(dynamic v, {String? fallbackPdfUrl}) {
    if (v == null) {
      if (fallbackPdfUrl != null && fallbackPdfUrl.isNotEmpty) {
        return [
          Attachment(
            id: 'pdf',
            label: 'PDF do empenho',
            url: fallbackPdfUrl,
            path: '',
            ext: '.pdf',
          ),
        ];
      }
      return null;
    }
    if (v is List) {
      return v.map<Attachment>((e) {
        if (e is Attachment) return e;
        return Attachment.fromMap(Map<String, dynamic>.from(e as Map));
      }).toList();
    }
    return null;
  }

  factory EmpenhoData.fromDocument(DocumentSnapshot snap) {
    final data = _readSnapData(snap);
    final pdfUrl = data['pdfUrl'] as String?;

    // ✅ NOVO: demanda id+label
    final demandId = (data['demandContractId'] ?? data['demandId'])?.toString();
    final demandLabel = (data['demandLabel'] ?? '').toString().trim();

    // LEGADO: credor
    final legacyCredor = (data['credor'] ?? '').toString().trim();

    // resolve a label da demanda: preferir demandLabel; fallback para credor
    final resolvedDemandLabel = demandLabel.isNotEmpty ? demandLabel : legacyCredor;

    // compat: objeto/fonte
    final legacyObjeto = (data['objeto'] ?? '').toString();
    final fsLabel = (data['fundingSourceLabel'] ?? '').toString();
    final resolvedFsLabel = fsLabel.isNotEmpty ? fsLabel : legacyObjeto;

    return EmpenhoData(
      id: (data['id'] as String?) ?? snap.id,
      contractId: data['contractId'] as String?,

      demandContractId: (demandId ?? '').trim().isEmpty ? null : demandId!.trim(),
      demandLabel: resolvedDemandLabel,

      // legado espelhado
      credor: resolvedDemandLabel,

      companyId: data['companyId'] as String?,
      companyLabel: (data['companyLabel'] as String?) ??
          (data['companyName'] as String?), // fallback se existir

      fundingSourceId: data['fundingSourceId'] as String?,
      fundingSourceLabel: resolvedFsLabel,

      objeto: legacyObjeto,

      numero: (data['numero'] ?? '').toString(),
      date: _toDate(data['date']) ?? DateTime.now(),
      empenhadoTotal: _toDouble(data['empenhadoTotal']) ?? 0.0,
      slices: _toSlices(data['slices']),
      pdfUrl: pdfUrl,
      attachments: _toAttachments(data['attachments'], fallbackPdfUrl: pdfUrl),
      createdAt: _toDate(data['createdAt']),
      createdBy: data['createdBy'] as String?,
      updatedAt: _toDate(data['updatedAt']),
      updatedBy: data['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    final resolvedDemandLabel = demandLabel.trim();

    return {
      'id': id,
      'contractId': contractId,

      // ✅ demanda (novo)
      'demandContractId': demandContractId,
      'demandLabel': resolvedDemandLabel,

      // ✅ legado: mantém credor espelhando o label novo
      'credor': resolvedDemandLabel,

      'companyId': companyId,
      'companyLabel': companyLabel,

      'numero': numero,

      'fundingSourceId': fundingSourceId,
      'fundingSourceLabel': fundingSourceLabel,

      // compat: espelha no "objeto" para não quebrar nada antigo
      'objeto': objeto,

      'date': date,
      'empenhadoTotal': empenhadoTotal,
      'slices': slices.map((e) => {'label': e.label, 'amount': e.amount}).toList(),
      'pdfUrl': pdfUrl,
      'attachments': attachments?.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    }..removeWhere((k, v) => v == null);
  }

  EmpenhoData copyWith({
    String? id,
    String? contractId,
    String? numero,

    String? demandContractId,
    String? demandLabel,

    String? credor, // legado (não use mais; ficará espelhado)
    String? companyId,
    String? companyLabel,

    String? fundingSourceId,
    String? fundingSourceLabel,

    String? objeto,
    DateTime? date,
    double? empenhadoTotal,
    List<AllocationSlice>? slices,
    String? pdfUrl,
    List<Attachment>? attachments,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    final nextDemandLabel = (demandLabel ?? this.demandLabel).trim();

    return EmpenhoData(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      numero: numero ?? this.numero,

      demandContractId: demandContractId ?? this.demandContractId,
      demandLabel: nextDemandLabel,

      // legado espelhado
      credor: nextDemandLabel,

      companyId: companyId ?? this.companyId,
      companyLabel: companyLabel ?? this.companyLabel,

      fundingSourceId: fundingSourceId ?? this.fundingSourceId,
      fundingSourceLabel: fundingSourceLabel ?? this.fundingSourceLabel,

      objeto: objeto ?? this.objeto,
      date: date ?? this.date,
      empenhadoTotal: empenhadoTotal ?? this.empenhadoTotal,
      slices: slices ?? this.slices,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}
