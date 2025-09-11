import 'package:flutter/material.dart';

/// Qualquer coisa compartilhada entre menus pode vir pra cá.
/// Ex.: enums, typedefs, pequenos helpers.

enum SelectionMode { direct, group }

/// Assinaturas úteis que os menus podem receber
typedef VoidBuild = void Function();
typedef ValueSetterInt = void Function(int delta);

/// Builder para um 3º menu (card lateral)
typedef SideMenuBuilder = Widget Function(VoidCallback close);
