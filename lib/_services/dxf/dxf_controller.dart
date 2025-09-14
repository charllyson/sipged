// lib/_widgets/archives/dxf/dxf_controller.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:siged/_services/dxf/dxf_render.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import 'dxf_model.dart';
import 'dxf_hit_tester.dart';

class DxfController extends ChangeNotifier {
  // Estado de render
  ui.Image? _image;
  Size? _sizePx;
  Uint8List? _rgba;
  int _w = 0, _h = 0;

  // Modelo e transformações
  DxfModel? _model;
  Matrix4? _modelToImage;
  Matrix4? _imageToModel;

  // UI
  bool _loading = false;
  Object? _error;
  DxfPick? _selected;

  ui.Image? get image => _image;
  Size? get sizePx => _sizePx;
  Uint8List? get rgba => _rgba;
  int get w => _w;
  int get h => _h;

  DxfModel? get model => _model;
  Matrix4? get modelToImage => _modelToImage;
  Matrix4? get imageToModel => _imageToModel;

  bool get isLoading => _loading;
  Object? get error => _error;
  DxfPick? get selectedPick => _selected;

  void clearSelection() {
    _selected = null;
    notifyListeners();
  }

  Future<void> loadBytes(Uint8List bytes, {double hairlinePx = 0.9}) async {
    _loading = true;
    _error = null;
    _image = null;
    _sizePx = null;
    _rgba = null;
    _w = _h = 0;
    _model = null;
    _modelToImage = null;
    _imageToModel = null;
    _selected = null;
    notifyListeners();

    try {
      final rr = await RenderService.renderDxf(
        dxfBytes: bytes,
        hairlinePx: hairlinePx,
      );
      _image = rr.image;
      _sizePx = Size(rr.w.toDouble(), rr.h.toDouble());
      _rgba = rr.rgba;
      _w = rr.w; _h = rr.h;
      _model = rr.model;
      _modelToImage = rr.modelToImage;
      _imageToModel = rr.imageToModel;
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = e;
      _loading = false;
      notifyListeners();
    }
  }

  /// Faz pick no espaço da IMAGEM (px). Converte para MODELO e usa hit-tester.
  DxfPick? pickAtImage(Offset imagePt, {required double tolPx, required double currentScreenScale}) {
    if (_model == null || _imageToModel == null) return null;
    final p = _imageToModel!.transform3(Vector3(imagePt.dx, imagePt.dy, 0));
    final pModel = Offset(p.x, p.y);
    final tolModel = tolPx / (currentScreenScale == 0 ? 1.0 : currentScreenScale);
    final pick = DxfHitTester(_model!).pickFirst(pModel, tolModel: tolModel);
    _selected = pick;
    notifyListeners();
    return pick;
  }

  void clear() {
    _image = null; _sizePx = null; _rgba = null; _w = _h = 0;
    _model = null; _modelToImage = null; _imageToModel = null;
    _selected = null; _error = null; _loading = false;
    notifyListeners();
  }
}
