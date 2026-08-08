import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_labels.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_rule.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data_simple.dart';

/// Uma camada/grupo achatado, pronto para virar um documento em
/// `geo/catalog/nodes/{id}`: guarda os dados próprios do nó (sem `children`
/// aninhado — a árvore é reconstruída a partir de [parentId]/[order]).
class _FlatEntry {
  final LayerData node;
  final String? parentId;
  final int order;

  const _FlatEntry({
    required this.node,
    required this.parentId,
    required this.order,
  });
}

class LayerRepository {
  LayerRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Schema atual: um documento por camada/grupo em `geo/catalog/nodes/{id}`,
  /// com `parentId` (null = raiz) e `order` (posição entre os irmãos) em vez
  /// de uma árvore aninhada num único documento. Isso evita reescrever a
  /// árvore inteira a cada edição — só os nós que realmente mudaram são
  /// gravados (ver [persistTreeDiff]).
  ///
  /// O documento legado `geo/catalog` (com o campo `items` contendo a árvore
  /// inteira) é deixado intocado após a migração, como cópia de segurança.
  static const String _catalogDocPath = 'geo/catalog';
  static const String _nodesCollectionPath = '$_catalogDocPath/nodes';

  static const int _writeChunkSize = 400;
  static const int _siblingOrderStride = 1000;

  CollectionReference<Map<String, dynamic>> get _nodesRef =>
      _firestore.collection(_nodesCollectionPath);

  DocumentReference<Map<String, dynamic>> _nodeDocRef(String id) =>
      _nodesRef.doc(id);

  String get _currentUid => _auth.currentUser?.uid ?? '';

  Future<List<LayerData>> loadTree() async {
    final snap = await _nodesRef.get();

    if (snap.docs.isEmpty) {
      return const <LayerData>[];
    }

    final byId = <String, LayerData>{};
    final parentById = <String, String?>{};
    final orderById = <String, num>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final parsed = LayerData.fromMap(data);

      // O id do documento é a fonte da verdade (evita divergência caso o
      // campo `id` gravado dentro do documento esteja desatualizado).
      byId[doc.id] = parsed.copyWith(id: doc.id, children: const []);

      final rawParentId = (data['parentId'] as String?)?.trim();
      parentById[doc.id] =
      (rawParentId == null || rawParentId.isEmpty) ? null : rawParentId;

      orderById[doc.id] = (data['order'] as num?) ?? 0;
    }

    final childrenByParent = <String?, List<String>>{};

    for (final id in byId.keys) {
      final parent = parentById[id];

      // parentId "órfão" (aponta para um nó que não existe mais) — trata
      // como raiz em vez de fazer o nó sumir silenciosamente da árvore.
      final effectiveParent =
      (parent != null && byId.containsKey(parent)) ? parent : null;

      childrenByParent.putIfAbsent(effectiveParent, () => <String>[]).add(id);
    }

    for (final list in childrenByParent.values) {
      list.sort((a, b) => orderById[a]!.compareTo(orderById[b]!));
    }

    final building = <String>{};

    LayerData build(String id) {
      final node = byId[id]!;

      // Proteção contra ciclo (não deveria acontecer, mas evita loop
      // infinito caso algum dado legado esteja corrompido).
      if (!building.add(id)) return node;

      final childIds = childrenByParent[id] ?? const <String>[];
      final children = childIds.map(build).toList(growable: false);

      building.remove(id);

      return children.isEmpty ? node : node.copyWith(children: children);
    }

    final rootIds = childrenByParent[null] ?? const <String>[];
    final tree = rootIds.map(build).toList(growable: false);

    // Autocura: garante ownerId e remove camadas-base legadas, no mesmo
    // espírito do que o schema anterior já fazia — só grava de volta o que
    // realmente mudou (via diff), nunca a árvore inteira.
    final sanitizedWithoutLegacy = _sanitizeTree(tree);
    final sanitized = _ensureOwnerForTree(sanitizedWithoutLegacy);

    if (!_isSameTree(tree, sanitized)) {
      await persistTreeDiff(previous: tree, next: sanitized);
    }

    return sanitized;
  }

  /// Grava apenas os nós que mudaram entre [previous] e [next] — criados,
  /// removidos, com dados próprios alterados, ou que mudaram de grupo pai
  /// (`parentId`)/posição entre os irmãos (`order`). Camadas que não foram
  /// tocadas não geram nenhuma escrita.
  Future<void> persistTreeDiff({
    required List<LayerData> previous,
    required List<LayerData> next,
  }) async {
    final normalizedNext = _ensureOwnerForTree(next);

    final prevFlat = _flattenWithParentOrder(previous);
    final nextFlat = _flattenWithParentOrder(normalizedNext);

    final toDelete = <String>[
      for (final id in prevFlat.keys)
        if (!nextFlat.containsKey(id)) id,
    ];

    final toWrite = <String, _FlatEntry>{};

    for (final entry in nextFlat.entries) {
      final id = entry.key;
      final nextEntry = entry.value;
      final prevEntry = prevFlat[id];

      final changed = prevEntry == null ||
          prevEntry.node != nextEntry.node ||
          prevEntry.parentId != nextEntry.parentId ||
          prevEntry.order != nextEntry.order;

      if (changed) toWrite[id] = nextEntry;
    }

    if (toDelete.isEmpty && toWrite.isEmpty) return;

    final uid = _currentUid;

    final deleteOps = toDelete;
    final writeOps = toWrite.entries.toList(growable: false);

    for (int i = 0; i < deleteOps.length; i += _writeChunkSize) {
      final chunk = deleteOps.sublist(
        i,
        math.min(i + _writeChunkSize, deleteOps.length),
      );
      final batch = _firestore.batch();
      for (final id in chunk) {
        batch.delete(_nodeDocRef(id));
      }
      await batch.commit();
    }

    for (int i = 0; i < writeOps.length; i += _writeChunkSize) {
      final chunk = writeOps.sublist(
        i,
        math.min(i + _writeChunkSize, writeOps.length),
      );
      final batch = _firestore.batch();

      for (final entry in chunk) {
        final flat = entry.value;
        final map = flat.node.toMap();

        map['parentId'] = flat.parentId;
        map['order'] = flat.order;
        map['updatedAt'] = FieldValue.serverTimestamp();
        map['updatedBy'] = uid;

        batch.set(_nodeDocRef(entry.key), map);
      }

      await batch.commit();
    }
  }

  Map<String, _FlatEntry> _flattenWithParentOrder(List<LayerData> tree) {
    final result = <String, _FlatEntry>{};

    void walk(List<LayerData> nodes, String? parentId) {
      for (int i = 0; i < nodes.length; i++) {
        final node = nodes[i];

        result[node.id] = _FlatEntry(
          node: node.copyWith(children: const []),
          parentId: parentId,
          order: i * _siblingOrderStride,
        );

        if (node.isGroup && node.children.isNotEmpty) {
          walk(node.children, node.id);
        }
      }
    }

    walk(tree, null);
    return result;
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
        a.tenantId != b.tenantId ||
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
