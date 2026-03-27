import 'package:flutter/material.dart';

class DockPanelConfig {
  DockPanelConfig._();

  static const double minDockSideExtent = 140.0;
  static const double maxDockSideExtent = 1100.0;

  static const double minDockTopBottomExtent = 100.0;
  static const double maxDockTopBottomExtent = 700.0;

  static const double splitterThickness = 6.0;
  static const double minDockWeight = 0.35;
  static const double dragUpdateThreshold = 10.0;

  static const double minimizedHeaderExtent = 30.0;

  static const BorderRadius panelRadius = BorderRadius.zero;

  static const double minFloatingWidth = 260.0;
  static const double maxFloatingWidth = 1200.0;

  static const double minFloatingHeight = 180.0;
  static const double maxFloatingHeight = 900.0;

  /// Largura reservada para a barra lateral dos painéis recolhidos.
  static const double sideRailWidth = 44.0;
}