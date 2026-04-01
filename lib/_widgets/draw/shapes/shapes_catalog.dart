import 'package:sipged/_widgets/draw/shapes/shapes_data.dart';

enum LayerShapeType {
  square,
  trapezoid,
  parallelogram,
  diamond,
  pentagon,
  hexagon,
  octagon,
  decagon,
  roundedSquare,
  triangle,
  star4,
  star5,
  heart,
  arrow,
  circle,
  plus,
  cross,
  line,
  arc,
  semicircle,
  quarterCircle,
  rectangle,
  rightTriangle,
  shield,
}

class ShapesCatalog {
  ShapesCatalog._();

  static const List<ShapeData> options = [
    ShapeData(
      value: LayerShapeType.square,
      label: 'Quadrado',
    ),
    ShapeData(
      value: LayerShapeType.trapezoid,
      label: 'Trapézio',
    ),
    ShapeData(
      value: LayerShapeType.parallelogram,
      label: 'Paralelogramo',
    ),
    ShapeData(
      value: LayerShapeType.diamond,
      label: 'Losango',
    ),
    ShapeData(
      value: LayerShapeType.pentagon,
      label: 'Pentágono',
    ),
    ShapeData(
      value: LayerShapeType.hexagon,
      label: 'Hexágono',
    ),
    ShapeData(
      value: LayerShapeType.octagon,
      label: 'Octógono',
    ),
    ShapeData(
      value: LayerShapeType.decagon,
      label: 'Decágono',
    ),
    ShapeData(
      value: LayerShapeType.roundedSquare,
      label: 'Quadrado arredondado',
    ),
    ShapeData(
      value: LayerShapeType.triangle,
      label: 'Triângulo',
    ),
    ShapeData(
      value: LayerShapeType.star4,
      label: 'Estrela 4 pontas',
    ),
    ShapeData(
      value: LayerShapeType.star5,
      label: 'Estrela 5 pontas',
    ),
    ShapeData(
      value: LayerShapeType.heart,
      label: 'Coração',
    ),
    ShapeData(
      value: LayerShapeType.arrow,
      label: 'Seta',
    ),
    ShapeData(
      value: LayerShapeType.circle,
      label: 'Círculo',
    ),
    ShapeData(
      value: LayerShapeType.plus,
      label: 'Mais',
    ),
    ShapeData(
      value: LayerShapeType.cross,
      label: 'X',
    ),
    ShapeData(
      value: LayerShapeType.line,
      label: 'Linha',
    ),
    ShapeData(
      value: LayerShapeType.arc,
      label: 'Arco',
    ),
    ShapeData(
      value: LayerShapeType.semicircle,
      label: 'Semicírculo',
    ),
    ShapeData(
      value: LayerShapeType.quarterCircle,
      label: '1/4 de círculo',
    ),
    ShapeData(
      value: LayerShapeType.rectangle,
      label: 'Retângulo',
    ),
    ShapeData(
      value: LayerShapeType.rightTriangle,
      label: 'Triângulo reto',
    ),
    ShapeData(
      value: LayerShapeType.shield,
      label: 'Escudo',
    ),
  ];

  static String labelFor(LayerShapeType shape) {
    for (final option in options) {
      if (option.value == shape) return option.label;
    }
    return shape.name;
  }
}