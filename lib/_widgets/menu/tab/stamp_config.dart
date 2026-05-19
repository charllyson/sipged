import 'package:flutter/material.dart';

class StampConfig {
  final bool show;
  final bool approved;
  final String? approvedLabel;
  final String? pendingLabel;
  final IconData? approvedIcon;
  final IconData? pendingIcon;
  final Color? approvedColor;
  final Color? pendingColor;
  final double scaleFactor;

  const StampConfig({
    required this.show,
    required this.approved,
    this.approvedLabel,
    this.pendingLabel,
    this.pendingIcon,
    this.approvedIcon,
    this.approvedColor,
    this.pendingColor,
    this.scaleFactor = 1.0,
  });

  static const hidden = StampConfig(
    show: false,
    approved: false,
  );
}
