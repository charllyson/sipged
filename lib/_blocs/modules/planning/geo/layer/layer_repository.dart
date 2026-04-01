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

  Future<List<LayerData>> loadTree() async {
    final snap = await _docRef.get();

    if (!snap.exists) {
      final initial = LayerData.bootstrapTree();
      await saveTree(initial);
      return initial;
    }

    final data = snap.data() ?? const <String, dynamic>{};
    final rawItems = (data['items'] as List?) ?? const [];

    if (rawItems.isEmpty) {
      final initial = LayerData.bootstrapTree();
      await saveTree(initial);
      return initial;
    }

    final parsed = rawItems
        .whereType<Map>()
        .map((e) => LayerData.fromMap(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final sanitized = _sanitizeTree(parsed);

    if (!_isSameTree(parsed, sanitized)) {
      await saveTree(sanitized);
    }

    return sanitized;
  }

  Future<void> saveTree(List<LayerData> tree) async {
    final uid = _auth.currentUser?.uid ?? '';

    await _docRef.set(
      {
        'items': tree.map((e) => e.toMap()).toList(),
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
        a.children.length != b.children.length ||
        a.symbolLayers.length != b.symbolLayers.length ||
        a.ruleBasedSymbols.length != b.ruleBasedSymbols.length ||
        a.labelLayers.length != b.labelLayers.length ||
        a.ruleBasedLabels.length != b.ruleBasedLabels.length) {
      return false;
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