// lib/_widgets/toolBox/tool_controllers.dart
import 'dart:convert';
import 'dart:ui' show Offset, Path, Size;

import 'package:flutter/material.dart';
import 'package:sipged/_services/files/dxf/dxf_enums.dart';
import 'package:sipged/_widgets/toolBox/menu_drawer_polygon_feature.dart';
import 'package:sipged/_widgets/toolBox/menu_text_enums.dart';
import 'package:sipged/_widgets/toolBox/tool_dock.dart';

/// Controller do dock/menus (como solicitado)
class ToolBoxController {
  ToolDockState? _state;
  void attach(ToolDockState s) => _state = s;
  void detach() => _state = null;

  void openCustomPanel({
    required String slotId,
    required Widget Function(VoidCallback close) builder,
    double minWidth = 220,
    double maxHeight = 420,
  }) {
    _state?.openCustomPanel(
      slotId: slotId,
      minWidth: minWidth,
      maxHeight: maxHeight,
      builder: builder,
    );
  }

  void closeAnyMenu() => _state?.closeAnyMenu();

  void openSideSubmenu({
    required String slotId,
    required Widget Function(VoidCallback close) builder,
    bool openToLeft = true,
    double dy = 0,
    double gap = 8,
    double maxHeight = 320,
  }) {
    _state?.openSideSubmenu(
      slotId: slotId,
      builder: builder,
      openToLeft: openToLeft,
      dy: dy,
      gap: gap,
      maxHeight: maxHeight,
    );
  }

  void closeSideSubmenu() => _state?.closeSideSubmenu();
}

/// ===========================================================
/// CONTROLLER: contém TODO o estado + lógica de POLÍGONOS/TEXTO
/// ===========================================================
class ScheduleCivilController extends ChangeNotifier {
  // --------- PROPRIEDADES DE EXIBIÇÃO (widget informa) ----------
  Size? pagePixelSize; // necessário p/ export normalizado e limitação de clique
  set setPagePixelSize(Size? s) {
    pagePixelSize = s;
    notifyListeners();
  }

  // --------- MODO / SNAP -----------
  ToolMode mode = ToolMode.draw; // draw | select | text
  bool snapEnabled = true;
  int snapRadius = 16;
  int snapMinGradient = 8;

  // --------- POLÍGONOS -----------
  final List<Offset> current = [];
  final List<MenuDrawerPolygonFeature> features = [];
  int? selectedIndex;

  bool get canFinishPolygon => current.length >= 3;
  bool get hasSelection => selectedIndex != null;

  // --------- TEXTOS -----------
  final List<TextItem> texts = [];
  int? selectedText;
  TextTool textTool = TextTool.point;
  double textDefaultWidth = 240;
  double textDefaultHeight = 80;

  // estilo default (o widget pode sobrepor visualmente)
  TextStyle get defaultTextStyle => const TextStyle(
    color: Color(0xFF000000),
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  // ---------- Helpers geométricos ----------
  Path _polygonPath(List<Offset> pts) {
    final p = Path();
    if (pts.isNotEmpty) p.addPolygon(pts, true);
    return p;
  }

  int? pickPolygonAt(Offset pagePoint) {
    for (int i = features.length - 1; i >= 0; i--) {
      final feat = features[i];
      if (feat.points.length < 3) continue;
      if (_polygonPath(feat.points).contains(pagePoint)) return i;
    }
    return null;
  }

  Offset centroidOf(List<Offset> poly) {
    if (poly.length < 3) return poly.first;
    final pts = List<Offset>.from(poly);
    if (pts.first != pts.last) pts.add(pts.first);
    double area = 0.0, cx = 0.0, cy = 0.0;
    for (int i = 0; i < pts.length - 1; i++) {
      final x0 = pts[i].dx, y0 = pts[i].dy;
      final x1 = pts[i + 1].dx, y1 = pts[i + 1].dy;
      final a = x0 * y1 - x1 * y0;
      area += a;
      cx += (x0 + x1) * a;
      cy += (y0 + y1) * a;
    }
    area *= 0.5;
    if (area.abs() < 1e-9) {
      final avgX = poly.fold<double>(0.0, (s, p) => s + p.dx) / poly.length;
      final avgY = poly.fold<double>(0.0, (s, p) => s + p.dy) / poly.length;
      return Offset(avgX, avgY);
    }
    return Offset(cx / (6.0 * area), cy / (6.0 * area));
  }

  // ---------- Ações de modo ----------
  void activateDraw() {
    mode = ToolMode.draw;
    selectedIndex = null;
    notifyListeners();
  }

  void activateSelect() {
    mode = ToolMode.select;
    notifyListeners();
  }

  void activateText(TextTool tool) {
    mode = ToolMode.text;
    textTool = tool;
    selectedIndex = null;
    notifyListeners();
  }

  void toggleSnap() {
    snapEnabled = !snapEnabled;
    notifyListeners();
  }

  void changeSnapRadius(int delta) {
    snapRadius = (snapRadius + delta).clamp(1, 64);
    notifyListeners();
  }

  void changeSnapThreshold(int delta) {
    snapMinGradient = (snapMinGradient + delta).clamp(1, 64);
    notifyListeners();
  }

  // ---------- Lógica principal de TAP (polígonos/seleção/texto) ----------
  Future<void> handleTap({
    required Offset pagePoint,
    required Future<String?> Function(String suggestion) onAskName,
  }) async {
    if (pagePixelSize == null) return;

    // Fora da página → limpa seleção em select
    if (pagePoint.dx < 0 ||
        pagePoint.dy < 0 ||
        pagePoint.dx > pagePixelSize!.width ||
        pagePoint.dy > pagePixelSize!.height) {
      if (mode == ToolMode.select && selectedIndex != null) {
        selectedIndex = null;
        notifyListeners();
      }
      return;
    }

    // TEXTO: inline começa no widget
    if (mode == ToolMode.text) return;

    // DRAW sem corrente: permitir selecionar polígono
    if (mode == ToolMode.draw && current.isEmpty) {
      final hit = pickPolygonAt(pagePoint);
      if (hit != null) {
        selectedIndex = hit;
        mode = ToolMode.select;
        notifyListeners();
        return;
      }
    }

    // SELECT: selecionar polígono
    if (mode == ToolMode.select) {
      selectedIndex = pickPolygonAt(pagePoint);
      notifyListeners();
      return;
    }

    // DRAW: adicionar ponto / fechar
    if (current.isNotEmpty && (pagePoint - current.first).distance <= 10) {
      await finishPolygon(onAskName: onAskName);
      return;
    }

    current.add(pagePoint);
    notifyListeners();
  }

  Future<void> finishPolygon({
    required Future<String?> Function(String suggestion) onAskName,
  }) async {
    if (current.length < 3) return;
    final closed = List<Offset>.from(current);
    if (closed.first != closed.last) closed.add(closed.first);
    final centroid = centroidOf(closed);
    final defaultName = 'Área ${features.length + 1}';
    final name = await onAskName(defaultName) ?? defaultName;

    features.add(
      MenuDrawerPolygonFeature(
        points: List<Offset>.from(current),
        name: name,
        centroid: centroid,
      ),
    );
    current.clear();
    selectedIndex = features.length - 1;
    mode = ToolMode.select;
    notifyListeners();
  }

  void undo() {
    if (current.isNotEmpty) {
      current.removeLast();
    } else if (features.isNotEmpty) {
      features.removeLast();
      if (selectedIndex != null && selectedIndex! >= features.length) {
        selectedIndex = null;
      }
    } else if (texts.isNotEmpty) {
      texts.removeLast();
      if (selectedText != null && selectedText! >= texts.length) {
        selectedText = null;
      }
    }
    notifyListeners();
  }

  void clearAll() {
    current.clear();
    features.clear();
    texts.clear();
    selectedIndex = null;
    selectedText = null;
    notifyListeners();
  }

  Future<void> renameSelected({
    required Future<String?> Function(String suggestion) onAskName,
    String? newName,
  }) async {
    if (!hasSelection) return;
    final i = selectedIndex!;
    final old = features[i];
    final name = newName ?? (await onAskName(old.name)) ?? old.name;
    features[i] = old.copyWith(name: name);
    notifyListeners();
  }

  void deleteSelected() {
    if (!hasSelection) return;
    features.removeAt(selectedIndex!);
    selectedIndex = null;
    notifyListeners();
  }

  // ---------- Export ----------
  String exportGeoJSON({
    required SourceKind sourceKind, // mantido para compatibilidade, mas ignorado
    required int pageNumber,        // mantido para compatibilidade, mas ignorado
    bool normalized = true,
  }) {
    if (pagePixelSize == null) return '{}';
    final w = pagePixelSize!.width;
    final h = pagePixelSize!.height;

    Map<String, dynamic> toFeature(MenuDrawerPolygonFeature f, int idx) {
      final ring = f.points.map((p) {
        final x = normalized ? (p.dx / w) : p.dx;
        final y = normalized ? (p.dy / h) : p.dy;
        return [x, y];
      }).toList();

      if (ring.isNotEmpty &&
          (ring.first[0] != ring.last[0] || ring.first[1] != ring.last[1])) {
        ring.add([ring.first[0], ring.first[1]]);
      }

      return {
        "type": "Feature",
        "editor": {
          "name": f.name,
          "index": idx,
          "page": 1, // somente DXF → 1
          "width_px": w,
          "height_px": h,
          "normalized": normalized,
          "source": "dxf",
          "selected": selectedIndex == idx,
        },
        "geometry": {"type": "Polygon", "coordinates": [ring]},
      };
    }

    final fc = {
      "type": "FeatureCollection",
      "features": [
        for (int i = 0; i < features.length; i++) toFeature(features[i], i),
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(fc);
  }

}
