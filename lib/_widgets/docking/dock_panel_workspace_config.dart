import 'package:flutter/material.dart';

class DockPanelWorkspaceConfig {
  DockPanelWorkspaceConfig._();

  // PAINÉIS LATERAIS (esquerda / direita)
  static const double minDockSideExtent = 140.0;
  static const double maxDockSideExtent = 1100.0;

  // PAINÉIS SUPERIOR / INFERIOR
  static const double minDockTopBottomExtent = 100.0;
  static const double maxDockTopBottomExtent = 700.0;

  static const double splitterThickness = 6.0;
  static const double minDockWeight = 0.35;
  static const double dragUpdateThreshold = 10.0;

  static const BorderRadius panelRadius = BorderRadius.zero;

  // PAINÉIS FLUTUANTES
  static const double minFloatingWidth = 260.0;
  static const double maxFloatingWidth = 1200.0;

  static const double minFloatingHeight = 180.0;
  static const double maxFloatingHeight = 900.0;
}