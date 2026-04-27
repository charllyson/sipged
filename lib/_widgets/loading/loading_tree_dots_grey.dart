import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

enum LoadingTreeDotsVariant {
  blue,
  white,
}

class LoadingTreeDots extends StatelessWidget {
  final double? size;
  final double strokeWidth;
  final Color? color;
  final bool centered;
  final LoadingTreeDotsVariant variant;

  /// Widget opcional exibido sobre a animação.
  ///
  /// Pode ser um Text simples:
  /// message: Text('Carregando...')
  ///
  /// Ou um Positioned/Align/Padding para controle total:
  /// message: const Positioned(
  ///   top: 8,
  ///   left: 0,
  ///   right: 0,
  ///   child: Text('Carregando...', textAlign: TextAlign.center),
  /// )
  final Widget? message;

  const LoadingTreeDots({
    super.key,
    this.size,
    this.strokeWidth = 4,
    this.color,
    this.centered = true,
    this.variant = LoadingTreeDotsVariant.blue,
    this.message,
  });

  String get _assetPath {
    switch (variant) {
      case LoadingTreeDotsVariant.blue:
        return 'assets/rive/tree-dots-blue-loading.riv';
      case LoadingTreeDotsVariant.white:
        return 'assets/rive/tree-dots-withe-loading.riv';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double resolvedSize = size ?? 100;

    final rive = SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: RiveAnimation.asset(
        _assetPath,
        fit: BoxFit.contain,
      ),
    );

    final content = SizedBox(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          rive,
          ?message,
        ],
      ),
    );

    if (centered) {
      return Center(child: content);
    }

    return content;
  }
}