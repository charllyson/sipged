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

enum FirebaseCollectionGroupTargetDocIdMode {
  originalId,
  parentIdAndOriginalId,
}

enum FirebaseCollectionGroupTargetPlacementMode {
  singleTargetCollection,

  /// Destino:
  ///
  /// tenants/{tenantId}/contracts/{contractId}/{collectionId}/{docId}
  tenantContractSubcollection,
}

class FirebaseAdminTenantPaths {
  const FirebaseAdminTenantPaths._();

  static const String fixedMigrationTenantId = 'SZQmefRUqdtLB14ahcuh';

  static const String contractsRootRelativePath = 'contracts';

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

  static String contractSubcollectionPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
    required String collectionId,
  }) {
    final cleanTenantId = tenantId.trim();
    final cleanContractId = contractId.trim();
    final cleanCollectionId = collectionId.trim();

    if (cleanTenantId.isEmpty ||
        cleanContractId.isEmpty ||
        cleanCollectionId.isEmpty) {
      return 'tenants/{tenantId}/contracts/{contractId}/{collectionId}';
    }

    return 'tenants/$cleanTenantId/contracts/$cleanContractId/$cleanCollectionId';
  }

  static String contractOrdersPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
  }) {
    return contractSubcollectionPath(
      tenantId: tenantId,
      contractId: contractId,
      collectionId: 'orders',
    );
  }

  static String contractReportsMeasurementPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
  }) {
    return contractSubcollectionPath(
      tenantId: tenantId,
      contractId: contractId,
      collectionId: 'reportsMeasurement',
    );
  }

  static String contractAdjustmentsMeasurementPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
  }) {
    return contractSubcollectionPath(
      tenantId: tenantId,
      contractId: contractId,
      collectionId: 'adjustmentsMeasurement',
    );
  }

  static String contractRevisionsMeasurementPath({
    String tenantId = fixedMigrationTenantId,
    required String contractId,
  }) {
    return contractSubcollectionPath(
      tenantId: tenantId,
      contractId: contractId,
      collectionId: 'revisionsMeasurement',
    );
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

class FirebaseCopyCollectionGroupParams {
  const FirebaseCopyCollectionGroupParams({
    required this.collectionId,
    required this.targetPath,
    this.tenantId = FirebaseAdminTenantPaths.fixedMigrationTenantId,
    this.merge = true,
    this.skipExisting = true,
    this.addMigrationMetadata = true,
    this.rewriteDocumentPathFields = true,
    this.pageSize = 100,
    this.batchSize = 50,
    this.targetDocIdMode =
        FirebaseCollectionGroupTargetDocIdMode.parentIdAndOriginalId,
    this.targetPlacementMode =
        FirebaseCollectionGroupTargetPlacementMode.singleTargetCollection,
    this.excludePathPrefixes = const <String>[
      'tenants/',
    ],
  });

  final String collectionId;

  /// Quando targetPlacementMode = tenantContractSubcollection:
  ///
  /// targetPath deve ser:
  ///
  /// tenants/{tenantId}/contracts
  ///
  /// O destino final será:
  ///
  /// tenants/{tenantId}/contracts/{contractId}/{collectionId}/{docId}
  final String targetPath;

  final String tenantId;

  final bool merge;
  final bool skipExisting;
  final bool addMigrationMetadata;
  final bool rewriteDocumentPathFields;

  final int pageSize;
  final int batchSize;

  final FirebaseCollectionGroupTargetDocIdMode targetDocIdMode;
  final FirebaseCollectionGroupTargetPlacementMode targetPlacementMode;

  final List<String> excludePathPrefixes;
}

class FirebaseCopyCollectionGroupResultData {
  const FirebaseCopyCollectionGroupResultData({
    required this.collectionId,
    required this.targetPath,
    required this.totalScanned,
    required this.totalCopied,
    required this.totalSkipped,
    required this.totalAlreadyExists,
    required this.totalEmpty,
    required this.totalExcludedByPath,
    required this.totalMissingContractId,
  });

  final String collectionId;
  final String targetPath;

  final int totalScanned;
  final int totalCopied;
  final int totalSkipped;
  final int totalAlreadyExists;
  final int totalEmpty;
  final int totalExcludedByPath;
  final int totalMissingContractId;

  int get totalProcessed => totalScanned;

  Map<String, dynamic> toMap() {
    return {
      'collectionId': collectionId,
      'targetPath': targetPath,
      'totalScanned': totalScanned,
      'totalCopied': totalCopied,
      'totalSkipped': totalSkipped,
      'totalAlreadyExists': totalAlreadyExists,
      'totalEmpty': totalEmpty,
      'totalExcludedByPath': totalExcludedByPath,
      'totalMissingContractId': totalMissingContractId,
      'totalProcessed': totalProcessed,
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