import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SigMineData {
  final String processo;
  final String? fase;
  final String? substancia;
  final String? titular;

  // 🔎 Campos extras para o painel
  final String? uso;
  final double? areaHa;
  final String? uf;
  final String? ultimoEvento; // texto completo do último evento
  final String? dataUltEvento; // data isolada, se vier separada
  final String? situacao;

  /// Polígono bruto (sem estilo; a cor será definida na camada de UI)
  final Polygon polygon;

  /// Ponto para ancorar tooltip/label
  final LatLng labelPoint;

  SigMineData({
    required this.processo,
    required this.polygon,
    required this.labelPoint,
    this.fase,
    this.substancia,
    this.titular,
    this.uso,
    this.areaHa,
    this.uf,
    this.ultimoEvento,
    this.dataUltEvento,
    this.situacao,
  });
}
