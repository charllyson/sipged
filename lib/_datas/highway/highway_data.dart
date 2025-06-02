class HighwayStateData {
  final String? rodovia;
  final String? codigoTrecho;
  final String? regional;
  final String? trechoInicial;
  final String? trechoFinal;
  final String? situacaoFisica;
  final double? extensaoKm;

  final Map<String, dynamic>? properties;
  final Map<String, dynamic>? geometry;
  final int? fid;
  final String? trechocoincidente;
  final String? rodoviacoincidente;
  final String? federalsuperposta;
  final String? latinicial;
  final String? longinicial;
  final String? latfinal;
  final String? longfinal;
  final String? jurisdicao;
  final String? numanterior;
  final double? kminicio;
  final double? kmfim;
  final String? tiporevestimento;
  final String? tmd;
  final String? layer;
  final String? path;

  HighwayStateData({
    this.rodovia,
    this.codigoTrecho,
    this.regional,
    this.trechoInicial,
    this.trechoFinal,
    this.situacaoFisica,
    this.extensaoKm,
    this.properties,
    this.geometry,
    this.fid,
    this.trechocoincidente,
    this.rodoviacoincidente,
    this.federalsuperposta,
    this.latinicial,
    this.longinicial,
    this.latfinal,
    this.longfinal,
    this.jurisdicao,
    this.numanterior,
    this.kminicio,
    this.kmfim,
    this.tiporevestimento,
    this.tmd,
    this.layer,
    this.path,
  });

  factory HighwayStateData.fromFeature(Map<String, dynamic> feature) {
    final props = feature['properties'] ?? {};
    final geometry = feature['geometry'];

    return HighwayStateData(
      rodovia: props['RODOVIA'],
      codigoTrecho: props['COD TRECHO'],
      regional: props['REGIONAL'],
      trechoInicial: props['TRECHO INICIAL'],
      trechoFinal: props['TRECHO FIN'],
      situacaoFisica: props['SIT.\nFIS.'],
      //fid: props['fid'],
      trechocoincidente: props['TRECHO COINCIDENTE'],
      rodoviacoincidente: props['CONC'],
      federalsuperposta: props['FEDERAL SUPERPOSTA'],
      latinicial: props['LAT INICIA'],
      longinicial: props['LONG INICIAL'],
      latfinal: props['LAT FINAL'],
      longfinal: props['LONG FINAL'],
      jurisdicao: props['JURISDIÇA'],
      numanterior: props['NUM\nANT.'],
      tiporevestimento: props['TIPO\nREV.'],
      tmd: props['TMD'],
      layer: props['layer'],
      path: props['path'],
      kminicio: double.tryParse((props['INICIO\n(km'] ?? '').toString().replaceAll(',', '.')),
      kmfim: double.tryParse((props['FIM\n(km)'] ?? '').toString().replaceAll(',', '.')),
      extensaoKm: _parseKm(props['EXT. \n(km)']),
      properties: Map<String, dynamic>.from(props),
      geometry: Map<String, dynamic>.from(geometry),
    );
  }

  static double? _parseKm(dynamic value) {
    try {
      final raw = double.parse(value.toString().replaceAll(',', '.'));
      return double.parse(raw.toStringAsFixed(3));
    } catch (_) {
      return null;
    }
  }

}
