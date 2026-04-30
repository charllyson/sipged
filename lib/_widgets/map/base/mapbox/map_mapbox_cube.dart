import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Cubo 3D em Flutter para representar orientação da câmera do Mapbox.
///
/// - Arrastar na horizontal → gira em torno do eixo vertical (bearing)
/// - Arrastar na vertical   → inclina em torno do eixo horizontal (pitch)
/// - Double tap             → reseta para top-down
class MapboxCubeWidget extends StatefulWidget {
  /// deltaBearing / deltaPitch em graus, para aplicar no controller do mapa.
  final void Function(double deltaBearing, double deltaPitch)? onRotate;

  /// Chamado quando o usuário der double-tap (reset de câmera).
  final VoidCallback? onReset;

  const MapboxCubeWidget({
    super.key,
    this.onRotate,
    this.onReset,
  });

  @override
  State<MapboxCubeWidget> createState() => _MapboxCubeWidgetState();
}

class _MapboxCubeWidgetState extends State<MapboxCubeWidget> {
  double _pitch = 20;
  double _bearing = 0;
  Offset? _lastPos;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => _lastPos = details.localPosition,
      onPanUpdate: (details) {
        if (_lastPos == null) return;

        final dx = details.localPosition.dx - _lastPos!.dx;
        final dy = details.localPosition.dy - _lastPos!.dy;
        _lastPos = details.localPosition;

        setState(() {
          _bearing += dx * 0.6;
          _pitch -= dy * 0.6;
          _pitch = _pitch.clamp(-80, 80);
        });

        widget.onRotate?.call(dx * 0.6, -dy * 0.6);
      },
      onPanEnd: (_) => _lastPos = null,
      onDoubleTap: () {
        setState(() {
          _bearing = 0;
          _pitch = 0;
        });
        widget.onReset?.call();
      },
      child: const SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: _CubeContent(),
        ),
      ),
    );
  }
}

class _CubeContent extends StatelessWidget {
  const _CubeContent();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_MapboxCubeWidgetState>();
    if (state == null) return const SizedBox.shrink();
    return state._buildCube();
  }
}

extension on _MapboxCubeWidgetState {
  Widget _buildCube() {
    const double size = 50;
    const double depth = size / 2;

    final faces = <Widget>[
      _face(
        'NORTE',
        Colors.white,
        transform: Matrix4.identity()..translateByDouble(0.0, 0.0, depth, 1.0),
      ),
      _face(
        'SUL',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateY(math.pi)
          ..translateByDouble(0.0, 0.0, depth, 1.0),
      ),
      _face(
        'LESTE',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateY(math.pi / 2)
          ..translateByDouble(0.0, 0.0, depth, 1.0),
      ),
      _face(
        'OESTE',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateY(-math.pi / 2)
          ..translateByDouble(0.0, 0.0, depth, 1.0),
      ),
      _face(
        'TOP',
        Colors.blue,
        colorText: Colors.white,
        transform: Matrix4.identity()
          ..rotateX(-math.pi / 2)
          ..translateByDouble(0.0, 0.0, depth, 1.0),
      ),
      _face(
        'BASE',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateX(math.pi / 2)
          ..translateByDouble(0.0, 0.0, depth, 1.0),
      ),
    ];

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_pitch * math.pi / 180)
        ..rotateY(_bearing * math.pi / 180),
      alignment: Alignment.center,
      child: Stack(children: faces),
    );
  }

  Widget _face(
      String text,
      Color color, {
        Color colorText = Colors.black87,
        required Matrix4 transform,
      }) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color.withValues(alpha: text == 'TOP' ? 0.95 : 0.9),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 3,
              offset: Offset(1, 1),
              color: Colors.black26,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: colorText,
            ),
          ),
        ),
      ),
    );
  }
}