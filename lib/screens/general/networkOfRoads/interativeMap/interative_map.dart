import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tappable_polyline/flutter_map_tappable_polyline.dart';
import 'package:latlong2/latlong.dart';
import 'package:sisgeo/_blocs/highway/highway_bloc.dart';
import 'package:sisgeo/_datas/highway/highway_data.dart';
import 'package:vector_math/vector_math.dart' as vec;

class InteractiveMapPage extends StatefulWidget {
  const InteractiveMapPage({super.key});

  @override
  State<InteractiveMapPage> createState() => _InteractiveMapPageState();
}

class _InteractiveMapPageState extends State<InteractiveMapPage> {
  List<Polygon> _polygons = [];
  List<TaggedPolyline> _polylines = [];
  final Map<Polygon, Map<String, dynamic>> _polygonProperties = {};
  int? _selectedPolylineIndex;
  int? _selectedPolygonIndex;
  HighwayBloc highwayBloc = HighwayBloc();
  Map<String, dynamic>? _tooltipProperties;
  bool _isLoading = true;
  String _selectedMapStyle =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  List<HighwayStateData> _highwayList = [];

  final MapController mapController = MapController();
  HighwayStateData getHighwayByProperties(Map<String, dynamic> props) {
    return _highwayList.firstWhere(
      (h) => mapEquals(h.properties, props),
      orElse: () => HighwayStateData(properties: props),
    );
  }

  final List<Map<String, String>> _mapStyles = [
    {
      'name': 'Padrão',
      'url': 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'Topo',
      'url':
          'https://cartodb-basemaps-a.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png',
    },
    {
      'name': 'Topográfico',
      'url': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'Claro',
      'url':
          'https://tiles.stadiamaps.com/tiles/alidade_smooth/{z}/{x}/{y}.png',
    },
    {
      'name': 'Satélite',
      'url':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }
  final ScrollController _scrollController = ScrollController();

  @override
  dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGeoJson() async {
    final data = await rootBundle.loadString('assets/roads/all-roads.geojson');
    final geojson = json.decode(data);
    final features = geojson['features'] as List;

    final List<TaggedPolyline> loadedPolylines = [];
    final List<Polygon> loadedPolygons = [];

    for (final feature in features) {
      final geometry = feature['geometry'];
      final type = geometry['type'];
      final coordinates = geometry['coordinates'];
      final properties = Map<String, dynamic>.from(feature['properties'] ?? {});

      if (type == 'Polygon') {
        final rings = List<List>.from(coordinates);
        for (final ring in rings) {
          final points = ring.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          final polygon = Polygon(
            points: points,
            color: Colors.green.withValues(alpha: 255 * 0.3),
            borderColor: Colors.green,
            borderStrokeWidth: 3,
          );
          loadedPolygons.add(polygon);
          _polygonProperties[polygon] = properties;
        }
      } else if (type == 'MultiLineString') {
        final lines = List<List>.from(coordinates);
        for (final line in lines) {
          final points = line.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          final polyline = TaggedPolyline(
            points: points,
            tag: jsonEncode(properties),
            color: Colors.green,
            strokeWidth: 2,
          );
          loadedPolylines.add(polyline);
        }
      }
    }

    /// ⬇️ AQUI: carrega os dados tipados para uso com busca estruturada
    _highwayList = await highwayBloc.loadHighwayStateGeoJson();

    setState(() {
      _polylines = loadedPolylines;
      _polygons = loadedPolygons;
      _isLoading = false;
    });
  }

  void _onLineTap(List<TaggedPolyline> tappedLines, TapUpDetails tapDetails) {
    if (tappedLines.isNotEmpty) {
      final selected = tappedLines.first;

      final index = _polylines.indexWhere(
        (p) => listEquals(p.points, selected.points) && p.tag == selected.tag,
      );

      Map<String, dynamic> props = {};
      if (selected.tag != null) {
        try {
          props = Map<String, dynamic>.from(jsonDecode(selected.tag!));
        } catch (_) {}
      }

      // ⬇️ Aqui você chama a função utilitária e atribui à variável
      final matchedHighway = getHighwayByProperties(props);

      // ⬇️ Agora a variável existe e pode ser usada sem erro
      setState(() {
        _tooltipProperties = matchedHighway.properties;
        _selectedPolylineIndex = index;
        _selectedPolygonIndex = null;
      });
    }
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    final vecs =
        polygon.map((p) => vec.Vector2(p.longitude, p.latitude)).toList();
    final testPoint = vec.Vector2(point.longitude, point.latitude);
    return _pointInPolygon(testPoint, vecs);
  }

  bool _pointInPolygon(vec.Vector2 point, List<vec.Vector2> polygon) {
    bool inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if ((polygon[i].y > point.y) != (polygon[j].y > point.y) &&
          point.x <
              (polygon[j].x - polygon[i].x) *
                      (point.y - polygon[i].y) /
                      (polygon[j].y - polygon[i].y) +
                  polygon[i].x) {
        inside = !inside;
      }
    }
    return inside;
  }

  Widget _buildInfoPanel() {
    if (_tooltipProperties == null) return const SizedBox.shrink();

    // Reconstrói o modelo baseado nas propriedades atuais
    final matchedHighway = getHighwayByProperties(_tooltipProperties!);

    return Positioned(
      bottom: 10,
      left: 10,
      right: 120,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 180),
        child: Card(
          color: Colors.black54,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Scrollbar(
              thumbVisibility: true, // mostra sempre a barra de rolagem
              trackVisibility: true, // opcional: mostra o trilho também
              controller: _scrollController, // importante para controlar manualmente
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    _buildTableColumn('CÓDIGO DA RODOVIA'),
                    _buildTableColumn('SIGLA'),
                    _buildTableColumn('INÍCIO DO TRECHO'),
                    _buildTableColumn('FIM DO TRECHO'),
                    _buildTableColumn('EXTENSÃO EM KM'),
                    _buildTableColumn('SITUAÇÃO FÍSICA'),
                    _buildTableColumn('GERÊNCIA REGIONAL'),
                    _buildTableColumn('TIPO DE REVESTIMENTO'),
                    _buildTableColumn('TRECHO COINCIDENTE'),
                    _buildTableColumn('LATITUDE INICIAL'),
                    _buildTableColumn('LONGITUDE INICIAL'),
                    _buildTableColumn('LATITUDE FINAL'),
                    _buildTableColumn('LONGITUDE FINAL'),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        _buildTableCell(matchedHighway.codigoTrecho ?? 'Não informado'),
                        _buildTableCell(matchedHighway.rodovia ?? 'Não informado'),
                        _buildTableCell(matchedHighway.trechoInicial ?? 'Não informado'),
                        _buildTableCell(matchedHighway.trechoFinal ?? 'Não informado'),
                        _buildTableCell(matchedHighway.extensaoKm.toString()),
                        _buildTableCell(matchedHighway.situacaoFisica ?? 'Não informado'),
                        _buildTableCell(matchedHighway.regional ?? 'Não informado'),
                        _buildTableCell(matchedHighway.tiporevestimento ?? 'Não informado'),
                        _buildTableCell(matchedHighway.trechocoincidente ?? 'Não informado'),
                        _buildTableCell(matchedHighway.latinicial ?? 'Não informado'),
                        _buildTableCell(matchedHighway.longinicial ?? 'Não informado'),
                        _buildTableCell(matchedHighway.latfinal ?? 'Não informado'),
                        _buildTableCell(matchedHighway.longfinal ?? 'Não informado'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _buildTableColumn(String text) {
    return DataColumn(
        label: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)));
  }

  DataCell _buildTableCell(String value) {
    return DataCell(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: SizedBox(
            width: 150,
            child: Text(
                value,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: const TextStyle(color: Colors.white)),
          ),
        ));
  }

  Widget _buildMapStyleButtons() {
    return Positioned(
      bottom: 10,
      right: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            _mapStyles.map((style) {
              final isSelected = _selectedMapStyle == style['url'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.black54 : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedMapStyle = style['url']!;
                    });
                  },
                  child: Text(
                    style['name']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng latlng) {
    for (int i = 0; i < _polygons.length; i++) {
      final polygon = _polygons[i];
      if (_isPointInPolygon(latlng, polygon.points)) {
        final props = _polygonProperties[polygon] ?? {};
        setState(() {
          _tooltipProperties = props;
          _selectedPolylineIndex = null;
          _selectedPolygonIndex = i;
        });
        return;
      }
    }

    // Nenhum polígono clicado
    setState(() {
      _tooltipProperties = null;
      _selectedPolylineIndex = null;
      _selectedPolygonIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*floatingActionButton: FloatingActionButton(
        onPressed: () => mapController.move(LatLng(-9.6071, -36.6701), 9.5),
        child: const Icon(Icons.my_location),
      ),*/
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Carregando all-roads.geojson...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(-9.6071, -36.6701),
                      initialZoom: 9.5,
                      onTap: _handleMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _selectedMapStyle,
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      PolygonLayer(
                        polygons: List.generate(_polygons.length, (i) {
                          final isSelected = i == _selectedPolygonIndex;
                          final polygon = _polygons[i];
                          return Polygon(
                            points: polygon.points,
                            color:
                                isSelected
                                    ? Colors.red.withValues(alpha: 255 * 0.4)
                                    : Colors.green.withValues(alpha: 255 * 0.3),
                            borderColor: isSelected ? Colors.red : Colors.green,
                            borderStrokeWidth: isSelected ? 3 : 2,
                          );
                        }),
                      ),
                      TappablePolylineLayer(
                        polylines: List.generate(_polylines.length, (i) {
                          final isSelected = i == _selectedPolylineIndex;
                          final poly = _polylines[i];
                          return TaggedPolyline(
                            points: poly.points,
                            tag: poly.tag,
                            color: isSelected ? Colors.red : Colors.green,
                            strokeWidth: isSelected ? 4 : 2,
                          );
                        }),
                        onTap: _onLineTap,
                        pointerDistanceTolerance: 15,
                      ),
                    ],
                  ),
                  _buildInfoPanel(),
                  _buildMapStyleButtons(),
                  /* Positioned(
            bottom: 60,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _tooltipPosition != null
                    ? 'Lat: ${_tooltipPosition!.latitude.toStringAsFixed(5)}\nLng: ${_tooltipPosition!.longitude.toStringAsFixed(5)}'
                    : 'Toque em uma linha ou polígono',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),*/
                ],
              ),
    );
  }
}
