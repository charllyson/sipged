import 'package:cloud_firestore/cloud_firestore.dart';

enum FirebaseAdminStatus {
  initial,
  loading,
  success,
  failure,
}

enum FirebaseWhereOp {
  eq,
  lt,
  lte,
  gt,
  gte,
  arrayContains,
  whereIn,
}

class FirebaseAdminTenantPaths {
  const FirebaseAdminTenantPaths._();

  static const String fixedMigrationTenantId = 'SZQmefRUqdtLB14ahcuh';

  static const String legacyContractsRootPath = 'contracts';

  static const String contractsRootRelativePath = 'contracts';

  static const String hiringCollectionId = 'hiring';
  static const String hiringMainDocId = 'main';

  static String tenantRootPath([
    String tenantId = fixedMigrationTenantId,
  ]) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}';
    }

    return 'tenants/$clean';
  }

  static String contractsRootPath([
    String tenantId = fixedMigrationTenantId,
  ]) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/$contractsRootRelativePath';
    }

    return 'tenants/$clean/$contractsRootRelativePath';
  }

  static String contractPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
  }) {
    final cleanTenantId = tenantId.trim();
    final cleanContractId = contractId.trim();

    if (cleanTenantId.isEmpty || cleanContractId.isEmpty) {
      return 'tenants/{tenantId}/contracts/{contractId}';
    }

    return 'tenants/$cleanTenantId/contracts/$cleanContractId';
  }

  static String contractHiringMainPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
  }) {
    return '${contractPath(
      tenantId: tenantId,
      contractId: contractId,
    )}/$hiringCollectionId/$hiringMainDocId';
  }

  static String contractHiringModuleCollectionPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
    required String moduleCollectionId,
  }) {
    final cleanModuleCollectionId = moduleCollectionId.trim();

    if (cleanModuleCollectionId.isEmpty) {
      return '${contractHiringMainPath(
        tenantId: tenantId,
        contractId: contractId,
      )}/{moduleCollectionId}';
    }

    return '${contractHiringMainPath(
      tenantId: tenantId,
      contractId: contractId,
    )}/$cleanModuleCollectionId';
  }

  static String contractHiringModuleMainDocPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
    required String moduleCollectionId,
  }) {
    return '${contractHiringModuleCollectionPath(
      tenantId: tenantId,
      contractId: contractId,
      moduleCollectionId: moduleCollectionId,
    )}/main';
  }

  static String contractHiringModuleSectionMainPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
    required String moduleCollectionId,
    required String sectionCollectionId,
  }) {
    final cleanSectionId = sectionCollectionId.trim();

    if (cleanSectionId.isEmpty) {
      return '${contractHiringModuleMainDocPath(
        tenantId: tenantId,
        contractId: contractId,
        moduleCollectionId: moduleCollectionId,
      )}/{sectionCollectionId}/main';
    }

    return '${contractHiringModuleMainDocPath(
      tenantId: tenantId,
      contractId: contractId,
      moduleCollectionId: moduleCollectionId,
    )}/$cleanSectionId/main';
  }

  /// Mantidos como aliases para evitar quebra em telas antigas.
  /// Preferir os métodos contractHiringModule* nos novos usos.
  static String contractModuleCollectionPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
    required String moduleCollectionId,
  }) {
    return contractHiringModuleCollectionPath(
      tenantId: tenantId,
      contractId: contractId,
      moduleCollectionId: moduleCollectionId,
    );
  }

  static String contractModuleMainDocPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
    required String moduleCollectionId,
  }) {
    return contractHiringModuleMainDocPath(
      tenantId: tenantId,
      contractId: contractId,
      moduleCollectionId: moduleCollectionId,
    );
  }

  static String contractModuleSectionMainPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
    required String moduleCollectionId,
    required String sectionCollectionId,
  }) {
    return contractHiringModuleSectionMainPath(
      tenantId: tenantId,
      contractId: contractId,
      moduleCollectionId: moduleCollectionId,
      sectionCollectionId: sectionCollectionId,
    );
  }
}

class FirebaseAdminContractModulePaths {
  const FirebaseAdminContractModulePaths._();

  static const String publicacaoCollectionId = 'publicacao';
  static const String arquivamentoCollectionId = 'arquivamento';

  static const String mainDocId = 'main';

  static const List<String> publicacaoSourceCollectionIds = <String>[
    'publicacao',
    'publicacaoExtrato',
    'publicacao_extrato',
    'PublicacaoExtrato',
  ];

  static const List<String> arquivamentoSourceCollectionIds = <String>[
    'arquivamento',
    'termoArquivamento',
    'termo_arquivamento',
    'TermoArquivamento',
  ];

  static const List<String> publicacaoSectionCollectionIds = <String>[
    'metadados',
    'partes',
    'veiculo',
    'status',
    'responsavel',
  ];

  static const List<String> arquivamentoSectionCollectionIds = <String>[
    'metadados',
    'motivo',
    'fundamentacao',
    'pecas',
    'decisao',
    'reabertura',
  ];

  static const List<FirebaseContractModuleMigrationData> officialModules =
  <FirebaseContractModuleMigrationData>[
    FirebaseContractModuleMigrationData(
      sourceCollectionIds: publicacaoSourceCollectionIds,
      targetCollectionId: publicacaoCollectionId,
      targetRootDocId: mainDocId,
      targetSectionDocId: mainDocId,
      label: 'Publicação do Extrato',
      sectionCollectionIds: publicacaoSectionCollectionIds,
    ),
    FirebaseContractModuleMigrationData(
      sourceCollectionIds: arquivamentoSourceCollectionIds,
      targetCollectionId: arquivamentoCollectionId,
      targetRootDocId: mainDocId,
      targetSectionDocId: mainDocId,
      label: 'Termo de Arquivamento',
      sectionCollectionIds: arquivamentoSectionCollectionIds,
    ),
  ];
}

class FirebaseContractModuleMigrationData {
  const FirebaseContractModuleMigrationData({
    required this.sourceCollectionIds,
    required this.targetCollectionId,
    required this.label,
    required this.sectionCollectionIds,
    this.targetRootDocId = FirebaseAdminContractModulePaths.mainDocId,
    this.targetSectionDocId = FirebaseAdminContractModulePaths.mainDocId,
  });

  final List<String> sourceCollectionIds;
  final String targetCollectionId;
  final String targetRootDocId;
  final String targetSectionDocId;
  final String label;
  final List<String> sectionCollectionIds;

  String get primarySourceCollectionId {
    if (sourceCollectionIds.isEmpty) return targetCollectionId;
    return sourceCollectionIds.first;
  }
}

class FirebaseWhereFilterData {
  const FirebaseWhereFilterData({
    required this.field,
    required this.op,
    required this.value,
  });

  final String field;
  final FirebaseWhereOp op;
  final dynamic value;

  Query<Map<String, dynamic>> apply(Query<Map<String, dynamic>> query) {
    switch (op) {
      case FirebaseWhereOp.eq:
        return query.where(field, isEqualTo: value);

      case FirebaseWhereOp.lt:
        return query.where(field, isLessThan: value);

      case FirebaseWhereOp.lte:
        return query.where(field, isLessThanOrEqualTo: value);

      case FirebaseWhereOp.gt:
        return query.where(field, isGreaterThan: value);

      case FirebaseWhereOp.gte:
        return query.where(field, isGreaterThanOrEqualTo: value);

      case FirebaseWhereOp.arrayContains:
        return query.where(field, arrayContains: value);

      case FirebaseWhereOp.whereIn:
        final list = value is List ? value : <dynamic>[value];

        return query.where(field, whereIn: list);
    }
  }
}

class FirebaseCopyContractModulesParams {
  const FirebaseCopyContractModulesParams({
    required this.tenantId,
    required this.sourceContractsPath,
    required this.targetContractsPath,
    required this.modules,
    this.merge = true,
    this.skipExisting = true,
    this.addMigrationMetadata = true,
    this.rewriteDocumentPathFields = true,
    this.pageSize = 100,
    this.batchSize = 50,
  });

  final String tenantId;

  /// Origem:
  ///
  /// contracts
  final String sourceContractsPath;

  /// Destino base dos contratos:
  ///
  /// tenants/{tenantId}/contracts
  ///
  /// A gravação real dos módulos será em:
  ///
  /// tenants/{tenantId}/contracts/{contractId}/hiring/main/{module}/main
  final String targetContractsPath;

  final List<FirebaseContractModuleMigrationData> modules;

  final bool merge;
  final bool skipExisting;
  final bool addMigrationMetadata;
  final bool rewriteDocumentPathFields;

  final int pageSize;
  final int batchSize;
}

class FirebaseCopyContractModulesResultData {
  const FirebaseCopyContractModulesResultData({
    required this.tenantId,
    required this.sourceContractsPath,
    required this.targetContractsPath,
    required this.totalContractsScanned,
    required this.totalContractsWithoutModules,
    required this.totalRootDocsScanned,
    required this.totalSectionDocsScanned,
    required this.totalScanned,
    required this.totalCopied,
    required this.totalSkipped,
    required this.totalAlreadyExists,
    required this.totalEmpty,
    required this.moduleTotals,
  });

  final String tenantId;
  final String sourceContractsPath;
  final String targetContractsPath;

  final int totalContractsScanned;
  final int totalContractsWithoutModules;
  final int totalRootDocsScanned;
  final int totalSectionDocsScanned;

  final int totalScanned;
  final int totalCopied;
  final int totalSkipped;
  final int totalAlreadyExists;
  final int totalEmpty;

  final Map<String, dynamic> moduleTotals;

  int get totalProcessed => totalScanned;

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'sourceContractsPath': sourceContractsPath,
      'targetContractsPath': targetContractsPath,
      'totalContractsScanned': totalContractsScanned,
      'totalContractsWithoutModules': totalContractsWithoutModules,
      'totalRootDocsScanned': totalRootDocsScanned,
      'totalSectionDocsScanned': totalSectionDocsScanned,
      'totalScanned': totalScanned,
      'totalCopied': totalCopied,
      'totalSkipped': totalSkipped,
      'totalAlreadyExists': totalAlreadyExists,
      'totalEmpty': totalEmpty,
      'totalProcessed': totalProcessed,
      'moduleTotals': moduleTotals,
    };
  }
}

/// Alias mantido apenas para reduzir quebra em arquivos antigos.
/// O tipo oficial agora é FirebaseCopyContractModulesResultData.
typedef FirebaseCopyHiringStagesResultData
= FirebaseCopyContractModulesResultData;

/// Alias mantido apenas para reduzir quebra em arquivos antigos.
/// O tipo oficial agora é FirebaseCopyContractModulesParams.
typedef FirebaseCopyHiringStagesParams = FirebaseCopyContractModulesParams;

/// Alias mantido apenas para reduzir quebra em arquivos antigos.
/// O tipo oficial agora é FirebaseContractModuleMigrationData.
typedef FirebaseHiringStageMigrationData = FirebaseContractModuleMigrationData;

class FirebaseOperationResultData {
  const FirebaseOperationResultData({
    required this.title,
    required this.total,
    this.details = const <String, dynamic>{},
  });

  final String title;
  final int total;
  final Map<String, dynamic> details;
}

class FirebaseValueParser {
  const FirebaseValueParser._();

  static dynamic parse(
      String raw, {
        bool tryList = false,
      }) {
    final value = raw.trim();

    if (value.isEmpty) return value;

    final lower = value.toLowerCase();

    if (lower == 'true') return true;
    if (lower == 'false') return false;
    if (lower == 'null') return null;

    if (tryList && value.contains(',')) {
      return value
          .split(',')
          .map((item) => parse(item, tryList: false))
          .toList();
    }

    final numeric = num.tryParse(value);

    if (numeric != null) return numeric;

    final date = DateTime.tryParse(value);

    if (date != null) return Timestamp.fromDate(date);

    return value;
  }
}