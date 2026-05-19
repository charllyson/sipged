// lib/_blocs/system/notification/global/global_banner_data.dart

import 'package:flutter/material.dart';

import 'global_banner_type.dart';

class GlobalBannerData {
  const GlobalBannerData({
    required this.id,
    required this.type,
    required this.message,
    required this.icon,
    this.dismissible = false,
  });

  final String id;
  final GlobalBannerType type;
  final String message;
  final IconData icon;
  final bool dismissible;
}