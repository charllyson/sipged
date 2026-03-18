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
  double _pitch = 20;   // inclinação inicial
  double _bearing = 0;  // rotação inicial
  Offset? _lastPos;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // garante que o drag seja capturado
      onPanStart: (details) => _lastPos = details.localPosition,
      onPanUpdate: (details) {
        if (_lastPos == null) return;

        final dx = details.localPosition.dx - _lastPos!.dx;
        final dy = details.localPosition.dy - _lastPos!.dy;
        _lastPos = details.localPosition;

        setState(() {
          _bearing += dx * 0.6;   // gira em torno do eixo vertical (Y)
          _pitch   -= dy * 0.6;   // inclina no eixo X
          _pitch = _pitch.clamp(-80, 80); // permite inclinar para cima/baixo
        });

        if (widget.onRotate != null) {
          // envia deltas pro controller do Mapbox
          widget.onRotate!(dx * 0.6, -dy * 0.6);
        }
      },
      onPanEnd: (_) => _lastPos = null,
      onDoubleTap: () {
        setState(() {
          _bearing = 0;
          _pitch = 0;
        });
        widget.onReset?.call();
      },
      child: SizedBox(
        width: 80,
        height: 80,
        // 👉 Centraliza o cubo dentro do box
        child: Center(
          child: _buildCube(),
        ),
      ),
    );
  }

  Widget _buildCube() {
    const double size = 50;
    const double depth = size / 2;

    final faces = <Widget>[
      // Frente (NORTE)
      _face(
        'NORTE',
        Colors.white,
        transform: Matrix4.identity()..translate(0.0, 0.0, depth),
      ),
      // Trás (SUL)
      _face(
        'SUL',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateY(math.pi)
          ..translate(0.0, 0.0, depth),
      ),
      // Direita (LESTE)
      _face(
        'LESTE',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateY(math.pi / 2)
          ..translate(0.0, 0.0, depth),
      ),
      // Esquerda (OESTE)
      _face(
        'OESTE',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateY(-math.pi / 2)
          ..translate(0.0, 0.0, depth),
      ),
      // Topo
      _face(
        'TOP',
        Colors.blue,
        colorText: Colors.white,
        transform: Matrix4.identity()
          ..rotateX(-math.pi / 2)
          ..translate(0.0, 0.0, depth),
      ),
      // Base
      _face(
        'BASE',
        Colors.white,
        transform: Matrix4.identity()
          ..rotateX(math.pi / 2)
          ..translate(0.0, 0.0, depth),
      ),
    ];

    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // perspectiva
        ..rotateX(_pitch * math.pi / 180)    // inclinação
        ..rotateY(_bearing * math.pi / 180), // rotação em torno do eixo vertical
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
