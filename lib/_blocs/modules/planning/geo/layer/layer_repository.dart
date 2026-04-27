import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';

class LayerRepository {
  LayerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _docPath = 'geo/catalog';

  DocumentReference<Map<String, dynamic>> get _docRef =>
      _firestore.doc(_docPath);

  String get _currentUid => _auth.currentUser?.uid ?? '';

  Future<List<LayerData>> loadTree() async {
    final snap = await _docRef.get();

    if (!snap.exists) {
      final initial = _ensureOwnerForTree(LayerData.bootstrapTree());
      await saveTree(initial);
      return initial;
    }

    final data = snap.data() ?? const <String, dynamic>{};
    final rawItems = (data['items'] as List?) ?? const [];

    if (rawItems.isEmpty) {
      final initial = _ensureOwnerForTree(LayerData.bootstrapTree());
      await saveTree(initial);
      return initial;
    }

    final parsed = rawItems
        .whereType<Map>()
        .map((e) => LayerData.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final sanitizedWithoutLegacy = _sanitizeTree(parsed);
    final sanitized = _ensureOwnerForTree(sanitizedWithoutLegacy);

    if (!_isSameTree(parsed, sanitized)) {
      await saveTree(sanitized);
    }

    return sanitized;
  }

  Future<void> saveTree(List<LayerData> tree) async {
    final uid = _currentUid;
    final normalizedTree = _ensureOwnerForTree(tree);

    await _docRef.set(
      {
        'items': normalizedTree.map((e) => e.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': uid,
      },
      SetOptions(merge: true),
    );
  }

  Future<bool> hasData({
    required String collectionPath,
  }) async {
    final path = collectionPath.trim();
    if (path.isEmpty) return false;

    final snap = await _firestore.collection(path).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<void> deleteLayerCollection({
    required String collectionPath,
    int pageSize = 300,
    int batchSize = 300,
  }) async {
    final path = collectionPath.trim();
    if (path.isEmpty) return;

    final collection = _firestore.collection(path);

    while (true) {
      final snap = await collection.limit(pageSize).get();
      if (snap.docs.isEmpty) break;

      for (int i = 0; i < snap.docs.length; i += batchSize) {
        final slice = snap.docs.skip(i).take(batchSize).toList(growable: false);
        final batch = _firestore.batch();

        for (final doc in slice) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    }
  }

  Future<void> deleteLayersData(
      List<LayerData> layers, {
        int pageSize = 300,
        int batchSize = 300,
      }) async {
    final uniquePaths = <String>{};

    for (final layer in layers) {
      if (layer.isGroup) continue;

      final path = (layer.effectiveCollectionPath ?? '').trim();
      if (path.isNotEmpty) {
        uniquePaths.add(path);
      }
    }

    for (final path in uniquePaths) {
      await deleteLayerCollection(
        collectionPath: path,
        pageSize: pageSize,
        batchSize: batchSize,
      );
    }
  }

  List<LayerData> _ensureOwnerForTree(List<LayerData> tree) {
    final uid = _currentUid.trim();

    return tree.map((node) {
      final nextChildren = node.children.isEmpty
          ? node.children
          : _ensureOwnerForTree(node.children);

      final currentOwner = (node.ownerId ?? '').trim();

      return node.copyWith(
        ownerId: currentOwner.isNotEmpty
            ? currentOwner
            : (uid.isNotEmpty ? uid : node.ownerId),
        children: nextChildren,
        sharedUserIds: _sanitizeSharedUserIds(
          node.sharedUserIds,
          ownerId: currentOwner.isNotEmpty ? currentOwner : uid,
        ),
        sharedPermissionsByUserId: _sanitizePermissions(
          node.sharedPermissionsByUserId,
          ownerId: currentOwner.isNotEmpty ? currentOwner : uid,
        ),
      );
    }).toList(growable: false);
  }

  List<String> _sanitizeSharedUserIds(
      List<String> ids, {
        required String ownerId,
      }) {
    final owner = ownerId.trim();

    return ids
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .where((e) => owner.isEmpty || e != owner)
        .toSet()
        .toList(growable: false);
  }

  Map<String, LayerSharePermission> _sanitizePermissions(
      Map<String, LayerSharePermission> map, {
        required String ownerId,
      }) {
    final owner = ownerId.trim();
    final out = <String, LayerSharePermission>{};

    for (final entry in map.entries) {
      final uid = entry.key.trim();
      if (uid.isEmpty) continue;
      if (owner.isNotEmpty && uid == owner) continue;
      out[uid] = entry.value;
    }

    return Map<String, LayerSharePermission>.unmodifiable(out);
  }

  List<LayerData> _sanitizeTree(List<LayerData> nodes) {
    return nodes
        .where((node) => !_isLegacyBaseLayer(node))
        .map((node) {
      if (!node.isGroup || node.children.isEmpty) return node;

      return node.copyWith(
        children: _sanitizeTree(node.children),
      );
    })
        .toList(growable: false);
  }

  bool _isLegacyBaseLayer(LayerData node) {
    return node.id == 'base_normal' || node.id == 'base_satellite';
  }

  bool _isSameTree(List<LayerData> a, List<LayerData> b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (!_isSameNode(a[i], b[i])) return false;
    }

    return true;
  }

  bool _isSameNode(LayerData a, LayerData b) {
    if (a.id != b.id ||
        a.title != b.title ||
        a.iconKey != b.iconKey ||
        a.colorValue != b.colorValue ||
        a.defaultVisible != b.defaultVisible ||
        a.isGroup != b.isGroup ||
        a.collectionPath != b.collectionPath ||
        a.geometryKind != b.geometryKind ||
        a.supportsConnect != b.supportsConnect ||
        a.isTemporary != b.isTemporary ||
        a.isSystem != b.isSystem ||
        a.rendererType != b.rendererType ||
        a.labelRendererType != b.labelRendererType ||
        a.ownerId != b.ownerId ||
        a.children.length != b.children.length ||
        a.symbolLayers.length != b.symbolLayers.length ||
        a.ruleBasedSymbols.length != b.ruleBasedSymbols.length ||
        a.labelLayers.length != b.labelLayers.length ||
        a.ruleBasedLabels.length != b.ruleBasedLabels.length ||
        a.sharedUserIds.length != b.sharedUserIds.length ||
        a.sharedPermissionsByUserId.length != b.sharedPermissionsByUserId.length) {
      return false;
    }

    for (int i = 0; i < a.sharedUserIds.length; i++) {
      if (a.sharedUserIds[i] != b.sharedUserIds[i]) return false;
    }

    for (final entry in a.sharedPermissionsByUserId.entries) {
      if (b.sharedPermissionsByUserId[entry.key] != entry.value) return false;
    }

    for (int i = 0; i < a.symbolLayers.length; i++) {
      if (!_isSameSymbol(a.symbolLayers[i], b.symbolLayers[i])) return false;
    }

    for (int i = 0; i < a.ruleBasedSymbols.length; i++) {
      if (!_isSameRule(a.ruleBasedSymbols[i], b.ruleBasedSymbols[i])) {
        return false;
      }
    }

    for (int i = 0; i < a.labelLayers.length; i++) {
      if (!_isSameLabelStyle(a.labelLayers[i], b.labelLayers[i])) {
        return false;
      }
    }

    for (int i = 0; i < a.ruleBasedLabels.length; i++) {
      if (!_isSameLabelRule(a.ruleBasedLabels[i], b.ruleBasedLabels[i])) {
        return false;
      }
    }

    for (int i = 0; i < a.children.length; i++) {
      if (!_isSameNode(a.children[i], b.children[i])) return false;
    }

    return true;
  }

  bool _isSameSymbol(LayerDataSimple a, LayerDataSimple b) {
    if (a.id != b.id ||
        a.family != b.family ||
        a.type != b.type ||
        a.iconKey != b.iconKey ||
        a.shapeType != b.shapeType ||
        a.width != b.width ||
        a.height != b.height ||
        a.keepAspectRatio != b.keepAspectRatio ||
        a.fillColorValue != b.fillColorValue ||
        a.strokeColorValue != b.strokeColorValue ||
        a.strokeWidth != b.strokeWidth ||
        a.rotationDegrees != b.rotationDegrees ||
        a.enabled != b.enabled ||
        a.strokePattern != b.strokePattern ||
        a.offset != b.offset ||
        a.useCustomDashPattern != b.useCustomDashPattern ||
        a.dashWidth != b.dashWidth ||
        a.dashGap != b.dashGap ||
        a.strokeJoin != b.strokeJoin ||
        a.strokeCap != b.strokeCap ||
        a.title != b.title ||
        a.text != b.text ||
        a.textFontSize != b.textFontSize ||
        a.textColorValue != b.textColorValue ||
        a.textFontWeight != b.textFontWeight ||
        a.textOffsetX != b.textOffsetX ||
        a.textOffsetY != b.textOffsetY) {
      return false;
    }

    if (a.dashArray.length != b.dashArray.length) return false;

    for (int i = 0; i < a.dashArray.length; i++) {
      if (a.dashArray[i] != b.dashArray[i]) return false;
    }

    return true;
  }

  bool _isSameRule(LayerDataRule a, LayerDataRule b) {
    if (a.id != b.id ||
        a.label != b.label ||
        a.enabled != b.enabled ||
        a.field != b.field ||
        a.operatorType != b.operatorType ||
        a.value != b.value ||
        a.minZoom != b.minZoom ||
        a.maxZoom != b.maxZoom ||
        a.symbolLayers.length != b.symbolLayers.length) {
      return false;
    }

    for (int i = 0; i < a.symbolLayers.length; i++) {
      if (!_isSameSymbol(a.symbolLayers[i], b.symbolLayers[i])) return false;
    }

    return true;
  }

  bool _isSameLabelStyle(LayerDataLabel a, LayerDataLabel b) {
    return a.id == b.id &&
        a.title == b.title &&
        a.text == b.text &&
        a.enabled == b.enabled &&
        a.type == b.type &&
        a.fontSize == b.fontSize &&
        a.colorValue == b.colorValue &&
        a.fontWeight == b.fontWeight &&
        a.offsetX == b.offsetX &&
        a.offsetY == b.offsetY &&
        a.iconKey == b.iconKey &&
        a.shapeType == b.shapeType &&
        a.width == b.width &&
        a.height == b.height &&
        a.keepAspectRatio == b.keepAspectRatio &&
        a.fillColorValue == b.fillColorValue &&
        a.strokeColorValue == b.strokeColorValue &&
        a.strokeWidth == b.strokeWidth &&
        a.rotationDegrees == b.rotationDegrees &&
        a.geometryOffset == b.geometryOffset;
  }

  bool _isSameLabelRule(GeoLabelRuleData a, GeoLabelRuleData b) {
    return a.id == b.id &&
        a.label == b.label &&
        a.enabled == b.enabled &&
        a.field == b.field &&
        a.operatorType == b.operatorType &&
        a.value == b.value &&
        a.minZoom == b.minZoom &&
        a.maxZoom == b.maxZoom &&
        _isSameLabelStyle(a.style, b.style);
  }
}