// lib/_blocs/system/adm/firebase_admin_data.dart

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

enum FirebaseLegacyCompanyTargetKind {
  tenant,
  partner,
  unit,
  road,
  region,
  fundingSource,
  program,
  expenseNature,
}

class FirebaseAdminTenantPaths {
  const FirebaseAdminTenantPaths._();

  static const String financialEmpenhosRelativePath =
      'financial/empenhos/items';

  static String financialEmpenhosPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/$financialEmpenhosRelativePath';
    }

    return 'tenants/$clean/$financialEmpenhosRelativePath';
  }
}

class FirebaseAdminSetupTenantPaths {
  const FirebaseAdminSetupTenantPaths._();

  static const String legacyCompanyDocPath = 'system/company';

  static const String legacyCompaniesBodies = 'companiesBodies';
  static const String legacyUnits = 'units';
  static const String legacyRoads = 'roads';
  static const String legacyRegions = 'regions';
  static const String legacyFundingSources = 'funding_sources';
  static const String legacyPrograms = 'programs';
  static const String legacyExpenseNatures = 'expense_natures';

  static const List<String> legacyCompanySubcollections = <String>[
    legacyCompaniesBodies,
    legacyUnits,
    legacyRoads,
    legacyRegions,
    legacyFundingSources,
    legacyPrograms,
    legacyExpenseNatures,
  ];

  static String tenantDocPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}';
    }

    return 'tenants/$clean';
  }

  static String partnersPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/partners';
    }

    return 'tenants/$clean/partners';
  }

  static String unitsPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/administrative/catalog/units';
    }

    return 'tenants/$clean/administrative/catalog/units';
  }

  static String regionsPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/administrative/catalog/regions';
    }

    return 'tenants/$clean/administrative/catalog/regions';
  }

  static String roadsAcronymPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/assets/roads/acronym';
    }

    return 'tenants/$clean/assets/roads/acronym';
  }

  static String fundingSourcesPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/financial/catalog/funding_sources';
    }

    return 'tenants/$clean/financial/catalog/funding_sources';
  }

  static String programsPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/financial/catalog/programs';
    }

    return 'tenants/$clean/financial/catalog/programs';
  }

  static String expenseNaturesPath(String tenantId) {
    final clean = tenantId.trim();

    if (clean.isEmpty) {
      return 'tenants/{tenantId}/financial/catalog/expense_natures';
    }

    return 'tenants/$clean/financial/catalog/expense_natures';
  }

  static List<FirebaseLegacyCompanySubcollectionRule> migrationRules(
      String tenantId,
      ) {
    return <FirebaseLegacyCompanySubcollectionRule>[
      FirebaseLegacyCompanySubcollectionRule(
        sourceSubcollection: legacyCompaniesBodies,
        targetCollectionPath: partnersPath(tenantId),
        targetKind: FirebaseLegacyCompanyTargetKind.partner,
      ),
      FirebaseLegacyCompanySubcollectionRule(
        sourceSubcollection: legacyUnits,
        targetCollectionPath: unitsPath(tenantId),
        targetKind: FirebaseLegacyCompanyTargetKind.unit,
      ),
      FirebaseLegacyCompanySubcollectionRule(
        sourceSubcollection: legacyRoads,
        targetCollectionPath: roadsAcronymPath(tenantId),
        targetKind: FirebaseLegacyCompanyTargetKind.road,
      ),
      FirebaseLegacyCompanySubcollectionRule(
        sourceSubcollection: legacyRegions,
        targetCollectionPath: regionsPath(tenantId),
        targetKind: FirebaseLegacyCompanyTargetKind.region,
      ),
      FirebaseLegacyCompanySubcollectionRule(
        sourceSubcollection: legacyFundingSources,
        targetCollectionPath: fundingSourcesPath(tenantId),
        targetKind: FirebaseLegacyCompanyTargetKind.fundingSource,
      ),
      FirebaseLegacyCompanySubcollectionRule(
        sourceSubcollection: legacyPrograms,
        targetCollectionPath: programsPath(tenantId),
        targetKind: FirebaseLegacyCompanyTargetKind.program,
      ),
      FirebaseLegacyCompanySubcollectionRule(
        sourceSubcollection: legacyExpenseNatures,
        targetCollectionPath: expenseNaturesPath(tenantId),
        targetKind: FirebaseLegacyCompanyTargetKind.expenseNature,
      ),
    ];
  }
}

class FirebaseLegacyCompanySubcollectionRule {
  const FirebaseLegacyCompanySubcollectionRule({
    required this.sourceSubcollection,
    required this.targetCollectionPath,
    required this.targetKind,
  });

  final String sourceSubcollection;
  final String targetCollectionPath;
  final FirebaseLegacyCompanyTargetKind targetKind;

  Map<String, dynamic> toMap() {
    return {
      'sourceSubcollection': sourceSubcollection,
      'targetCollectionPath': targetCollectionPath,
      'targetKind': targetKind.name,
    };
  }
}

class FirebaseLegacyCompanyMigrationResultData {
  const FirebaseLegacyCompanyMigrationResultData({
    required this.tenantId,
    required this.sourceDocPath,
    required this.targetDocPath,
    required this.documentCopied,
    required this.documentSkipped,
    required this.targetAlreadyExists,
    required this.totalSubcollectionsProcessed,
    required this.totalSubcollectionDocsCopied,
    required this.totalSubcollectionDocsSkipped,
    required this.rules,
  });

  final String tenantId;
  final String sourceDocPath;
  final String targetDocPath;

  final bool documentCopied;
  final bool documentSkipped;
  final bool targetAlreadyExists;

  final int totalSubcollectionsProcessed;
  final int totalSubcollectionDocsCopied;
  final int totalSubcollectionDocsSkipped;

  final List<FirebaseLegacyCompanySubcollectionRule> rules;

  int get totalEverythingCopied {
    return (documentCopied ? 1 : 0) + totalSubcollectionDocsCopied;
  }

  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'sourceDocPath': sourceDocPath,
      'targetDocPath': targetDocPath,
      'documentCopied': documentCopied,
      'documentSkipped': documentSkipped,
      'targetAlreadyExists': targetAlreadyExists,
      'totalSubcollectionsProcessed': totalSubcollectionsProcessed,
      'totalSubcollectionDocsCopied': totalSubcollectionDocsCopied,
      'totalSubcollectionDocsSkipped': totalSubcollectionDocsSkipped,
      'totalEverythingCopied': totalEverythingCopied,
      'rules': rules.map((rule) => rule.toMap()).toList(),
    };
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

class FirebaseDeleteCollectionParams {
  const FirebaseDeleteCollectionParams({
    required this.path,
  });

  final String path;
}

class FirebaseCleanupSubcollectionsParams {
  const FirebaseCleanupSubcollectionsParams({
    required this.collectionPath,
    required this.subcollections,
  });

  final String collectionPath;
  final List<String> subcollections;
}

class FirebaseSelectiveDeleteByIdsParams {
  const FirebaseSelectiveDeleteByIdsParams({
    required this.parentCollectionPath,
    required this.subcollection,
    required this.docIds,
  });

  final String parentCollectionPath;
  final String subcollection;
  final List<String> docIds;
}

class FirebaseSelectiveDeleteByFilterParams {
  const FirebaseSelectiveDeleteByFilterParams({
    required this.parentCollectionPath,
    required this.subcollection,
    required this.filters,
    required this.useParents,
  });

  final String parentCollectionPath;
  final String subcollection;
  final List<FirebaseWhereFilterData> filters;
  final bool useParents;
}

class FirebaseCopyDocumentParams {
  const FirebaseCopyDocumentParams({
    required this.sourceDocPath,
    required this.targetDocPath,
    this.merge = true,
    this.addMigrationMetadata = true,
    this.skipExisting = false,
    this.subcollectionsToCopy = const <String>[],
    this.copySubcollectionsWhenTargetExists = true,
    this.rewriteDocumentPathFields = true,
  });

  final String sourceDocPath;
  final String targetDocPath;

  final bool merge;
  final bool addMigrationMetadata;
  final bool skipExisting;

  final List<String> subcollectionsToCopy;
  final bool copySubcollectionsWhenTargetExists;
  final bool rewriteDocumentPathFields;
}

class FirebaseCopyDocumentResultData {
  const FirebaseCopyDocumentResultData({
    required this.sourceDocPath,
    required this.targetDocPath,
    required this.documentCopied,
    required this.documentSkipped,
    required this.targetAlreadyExists,
    required this.totalSubcollectionsCopied,
    required this.totalSubcollectionDocsCopied,
    required this.totalSubcollectionDocsSkipped,
    this.subcollectionsToCopy = const <String>[],
  });

  final String sourceDocPath;
  final String targetDocPath;

  final bool documentCopied;
  final bool documentSkipped;
  final bool targetAlreadyExists;

  final int totalSubcollectionsCopied;
  final int totalSubcollectionDocsCopied;
  final int totalSubcollectionDocsSkipped;

  final List<String> subcollectionsToCopy;

  int get totalEverythingCopied {
    return (documentCopied ? 1 : 0) + totalSubcollectionDocsCopied;
  }

  Map<String, dynamic> toMap() {
    return {
      'sourceDocPath': sourceDocPath,
      'targetDocPath': targetDocPath,
      'documentCopied': documentCopied,
      'documentSkipped': documentSkipped,
      'targetAlreadyExists': targetAlreadyExists,
      'subcollectionsToCopy': subcollectionsToCopy,
      'totalSubcollectionsCopied': totalSubcollectionsCopied,
      'totalSubcollectionDocsCopied': totalSubcollectionDocsCopied,
      'totalSubcollectionDocsSkipped': totalSubcollectionDocsSkipped,
      'totalEverythingCopied': totalEverythingCopied,
    };
  }
}

class FirebaseCopyCollectionParams {
  const FirebaseCopyCollectionParams({
    required this.sourcePath,
    required this.targetPath,
    this.docIds = const <String>[],
    this.selectedFieldsByDocId = const <String, Set<String>>{},
    this.copyAllDocuments = false,
    this.merge = true,
    this.addMigrationMetadata = true,
    this.skipExisting = true,
    this.pageSize = 50,
    this.batchSize = 25,
    this.subcollectionsToCopy = const <String>[],
    this.copySubcollectionsWhenParentExists = true,
    this.rewriteDocumentPathFields = true,
  });

  final String sourcePath;
  final String targetPath;

  final List<String> docIds;
  final Map<String, Set<String>> selectedFieldsByDocId;

  final bool copyAllDocuments;
  final bool merge;
  final bool addMigrationMetadata;
  final bool skipExisting;

  final int pageSize;
  final int batchSize;

  final List<String> subcollectionsToCopy;
  final bool copySubcollectionsWhenParentExists;
  final bool rewriteDocumentPathFields;

  bool get hasSpecificDocIds => docIds.isNotEmpty;

  bool get shouldCopySubcollections {
    return subcollectionsToCopy.where((e) => e.trim().isNotEmpty).isNotEmpty;
  }

  FirebaseCopyCollectionParams copyWith({
    String? sourcePath,
    String? targetPath,
    List<String>? docIds,
    Map<String, Set<String>>? selectedFieldsByDocId,
    bool? copyAllDocuments,
    bool? merge,
    bool? addMigrationMetadata,
    bool? skipExisting,
    int? pageSize,
    int? batchSize,
    List<String>? subcollectionsToCopy,
    bool? copySubcollectionsWhenParentExists,
    bool? rewriteDocumentPathFields,
  }) {
    return FirebaseCopyCollectionParams(
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      docIds: docIds ?? this.docIds,
      selectedFieldsByDocId:
      selectedFieldsByDocId ?? this.selectedFieldsByDocId,
      copyAllDocuments: copyAllDocuments ?? this.copyAllDocuments,
      merge: merge ?? this.merge,
      addMigrationMetadata:
      addMigrationMetadata ?? this.addMigrationMetadata,
      skipExisting: skipExisting ?? this.skipExisting,
      pageSize: pageSize ?? this.pageSize,
      batchSize: batchSize ?? this.batchSize,
      subcollectionsToCopy:
      subcollectionsToCopy ?? this.subcollectionsToCopy,
      copySubcollectionsWhenParentExists:
      copySubcollectionsWhenParentExists ??
          this.copySubcollectionsWhenParentExists,
      rewriteDocumentPathFields:
      rewriteDocumentPathFields ?? this.rewriteDocumentPathFields,
    );
  }
}

class FirebaseCopyCollectionResultData {
  const FirebaseCopyCollectionResultData({
    required this.sourcePath,
    required this.targetPath,
    this.totalSelected = 0,
    this.totalScanned = 0,
    required this.totalCopied,
    required this.totalSkipped,
    this.totalAlreadyExists = 0,
    this.totalEmpty = 0,
    this.copyAllDocuments = false,
    this.totalSubcollectionsCopied = 0,
    this.totalSubcollectionDocsCopied = 0,
    this.totalSubcollectionDocsSkipped = 0,
    this.subcollectionsToCopy = const <String>[],
  });

  final String sourcePath;
  final String targetPath;

  final int totalSelected;
  final int totalScanned;

  final int totalCopied;
  final int totalSkipped;

  final int totalAlreadyExists;
  final int totalEmpty;

  final bool copyAllDocuments;

  final int totalSubcollectionsCopied;
  final int totalSubcollectionDocsCopied;
  final int totalSubcollectionDocsSkipped;

  final List<String> subcollectionsToCopy;

  int get totalProcessed {
    if (totalScanned > 0) return totalScanned;
    if (totalSelected > 0) return totalSelected;

    return totalCopied + totalSkipped;
  }

  int get totalEverythingCopied {
    return totalCopied + totalSubcollectionDocsCopied;
  }

  Map<String, dynamic> toMap() {
    return {
      'sourcePath': sourcePath,
      'targetPath': targetPath,
      'totalSelected': totalSelected,
      'totalScanned': totalScanned,
      'totalProcessed': totalProcessed,
      'totalCopied': totalCopied,
      'totalSkipped': totalSkipped,
      'totalAlreadyExists': totalAlreadyExists,
      'totalEmpty': totalEmpty,
      'copyAllDocuments': copyAllDocuments,
      'subcollectionsToCopy': subcollectionsToCopy,
      'totalSubcollectionsCopied': totalSubcollectionsCopied,
      'totalSubcollectionDocsCopied': totalSubcollectionDocsCopied,
      'totalSubcollectionDocsSkipped': totalSubcollectionDocsSkipped,
      'totalEverythingCopied': totalEverythingCopied,
    };
  }
}

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