import 'package:flutter/material.dart';

class DockPanelDataItem {
  final String id;
  final String title;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  /// Identifica mudança de conteúdo do painel sem depender da identidade do Widget.
  final Object? contentToken;

  const DockPanelDataItem({
    required this.id,
    required this.title,
    required this.child,
    this.icon,
    this.contentPadding = const EdgeInsets.all(8),
    this.contentToken,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DockPanelDataItem &&
            other.id == id &&
            other.title == title &&
            other.icon == icon &&
            other.contentPadding == contentPadding &&
            other.contentToken == contentToken);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    icon,
    contentPadding,
    contentToken,
  );
}
