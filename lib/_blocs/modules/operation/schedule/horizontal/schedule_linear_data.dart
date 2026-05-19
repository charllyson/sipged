import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint, Timestamp;
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'schedule_linear_cell_data.dart';
import 'schedule_linear_lane_data.dart';
import 'schedule_linear_services_data.dart';

class ScheduleLinearData extends Equatable {
  /// Identificador global do cronograma, se existir.
  final String? id;

  /// Contrato vinculado ao cronograma.
  final String? contractId;

  /// Tenant vinculado ao cronograma.
  final String? tenantId;

  /// Nome ou título do cronograma.
  final String? title;

  /// Tipo da geometria importada ou desenhada.
  ///
  /// Exemplo:
  /// - LineString
  /// - MultiLineString
  final String? geometryType;

  /// Geometria principal em múltiplos segmentos.
  final List<List<LatLng>>? multiLine;

  /// Geometria simples, quando o cronograma usa apenas uma linha.
  final List<LatLng>? points;

  /// Faixas/lanes do cronograma.
  final List<ScheduleLinearLaneData> lanes;

  /// Serviços disponíveis no cronograma.
  final List<ScheduleLinearServicesData> services;

  /// Células executadas ou planejadas.
  ///
  /// Cada célula representa uma estaca.
  /// No cronograma rodoviário, cada estaca corresponde a 20 metros.
  final List<ScheduleLinearCellData> cells;

  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  /// Campo livre para metadados globais do cronograma.
  ///
  /// Use com moderação. O ideal é criar campos explícitos quando
  /// o dado passar a fazer parte da regra de negócio.
  final Map<String, dynamic> metadata;

  const ScheduleLinearData({
    this.id,
    this.contractId,
    this.tenantId,
    this.title,
    this.geometryType,
    this.multiLine,
    this.points,
    this.lanes = const <ScheduleLinearLaneData>[],
    this.services = const <ScheduleLinearServicesData>[
      ScheduleLinearServicesData.emptyGeral,
    ],
    this.cells = const <ScheduleLinearCellData>[],
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.metadata = const <String, dynamic>{},
  });

  factory ScheduleLinearData.empty({
    String? id,
    String? contractId,
    String? tenantId,
    String? title,
  }) {
    return ScheduleLinearData(
      id: id,
      contractId: contractId,
      tenantId: tenantId,
      title: title,
      services: const <ScheduleLinearServicesData>[
        ScheduleLinearServicesData.emptyGeral,
      ],
    );
  }

  factory ScheduleLinearData.fromMap(
      Map<String, dynamic> map, {
        String? id,
      }) {
    final services = _parseServices(map['services']);
    final hasGeral = services.any((item) => item.isGeral);

    return ScheduleLinearData(
      id: id ?? _asString(map['id']),
      contractId: _asString(map['contractId']),
      tenantId: _asString(map['tenantId']),
      title: _asString(map['title']),
      geometryType: _asString(map['geometryType']),
      multiLine: _parseMulti(map['multiLine']),
      points: _parsePoints(map['points']),
      lanes: _parseLanes(map['lanes']),
      services: hasGeral
          ? services
          : <ScheduleLinearServicesData>[
        ScheduleLinearServicesData.emptyGeral,
        ...services,
      ],
      cells: _parseCells(map['cells']),
      createdAt: _asDateTime(map['createdAt']),
      createdBy: _asString(map['createdBy']),
      updatedAt: _asDateTime(map['updatedAt']),
      updatedBy: _asString(map['updatedBy']),
      metadata: _asDynamicMap(map['metadata']),
    );
  }

  List<List<LatLng>> getSegments() {
    if (multiLine != null && multiLine!.isNotEmpty) {
      return multiLine!
          .where((segment) => segment.length >= 2)
          .map((segment) => List<LatLng>.from(segment))
          .toList(growable: false);
    }

    if (points != null && points!.length >= 2) {
      return <List<LatLng>>[
        List<LatLng>.from(points!),
      ];
    }

    return const <List<LatLng>>[];
  }

  List<LatLng> get axis {
    return getSegments().expand((segment) => segment).toList(growable: false);
  }

  bool get hasGeometry {
    return getSegments().isNotEmpty;
  }

  int get totalEstacas {
    if (cells.isEmpty) return 0;

    final maxNumero = cells
        .map((cell) => cell.numero)
        .fold<int>(0, (previous, current) {
      return current > previous ? current : previous;
    });

    return maxNumero;
  }

  int get totalMeters {
    return totalEstacas * ScheduleLinearCellData.metersPerStake;
  }

  List<ScheduleLinearServicesData> get executableServices {
    return services.where((service) => !service.isGeral).toList(growable: false);
  }

  ScheduleLinearServicesData? serviceByKey(String serviceKey) {
    final cleanKey = serviceKey.trim();

    for (final service in services) {
      if (service.key == cleanKey) {
        return service;
      }
    }

    return null;
  }

  ScheduleLinearLaneData? laneByIndex(int faixaIndex) {
    for (final lane in lanes) {
      if (lane.faixaIndex == faixaIndex) {
        return lane;
      }
    }

    return null;
  }

  List<ScheduleLinearCellData> cellsByService(String serviceKey) {
    final cleanKey = serviceKey.trim();

    if (cleanKey.isEmpty || cleanKey == ScheduleLinearServicesData.geralKey) {
      return cells;
    }

    return cells
        .where((cell) => cell.serviceKey == cleanKey)
        .toList(growable: false);
  }

  List<ScheduleLinearCellData> cellsByLane(int faixaIndex) {
    return cells
        .where((cell) => cell.faixaIndex == faixaIndex)
        .toList(growable: false);
  }

  List<ScheduleLinearCellData> cellsByLaneAndService({
    required int faixaIndex,
    required String serviceKey,
  }) {
    final cleanKey = serviceKey.trim();

    return cells
        .where(
          (cell) =>
      cell.faixaIndex == faixaIndex &&
          (cleanKey == ScheduleLinearServicesData.geralKey ||
              cell.serviceKey == cleanKey),
    )
        .toList(growable: false);
  }

  ScheduleLinearCellData? cellAt({
    required int numero,
    required int faixaIndex,
    required String serviceKey,
  }) {
    final cleanKey = serviceKey.trim();

    for (final cell in cells) {
      if (cell.numero == numero &&
          cell.faixaIndex == faixaIndex &&
          cell.serviceKey == cleanKey) {
        return cell;
      }
    }

    return null;
  }

  Map<String, ScheduleLinearCellData> get cellsByKey {
    return <String, ScheduleLinearCellData>{
      for (final cell in cells) cell.cellKey: cell,
    };
  }

  Map<String, dynamic> toMap({
    bool includeChildren = true,
  }) {
    return <String, dynamic>{
      if (id != null) 'id': id,
      if (contractId != null) 'contractId': contractId,
      if (tenantId != null) 'tenantId': tenantId,
      if (title != null) 'title': title,
      if (geometryType != null) 'geometryType': geometryType,
      if (multiLine != null) 'multiLine': _toMultiList(multiLine),
      if (points != null) 'points': _toPoints(points),
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'updatedBy': updatedBy,
      if (metadata.isNotEmpty) 'metadata': metadata,
      if (includeChildren) ...<String, dynamic>{
        'lanes': lanes.map((lane) => lane.toMap()).toList(growable: false),
        'services': services
            .map((service) => service.toMap())
            .toList(growable: false),
        'cells': cells.map((cell) => cell.toMap()).toList(growable: false),
      },
    };
  }

  ScheduleLinearData copyWith({
    String? id,
    String? contractId,
    String? tenantId,
    String? title,
    String? geometryType,
    List<List<LatLng>>? multiLine,
    List<LatLng>? points,
    List<ScheduleLinearLaneData>? lanes,
    List<ScheduleLinearServicesData>? services,
    List<ScheduleLinearCellData>? cells,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    Map<String, dynamic>? metadata,
  }) {
    return ScheduleLinearData(
      id: id ?? this.id,
      contractId: contractId ?? this.contractId,
      tenantId: tenantId ?? this.tenantId,
      title: title ?? this.title,
      geometryType: geometryType ?? this.geometryType,
      multiLine: multiLine ?? this.multiLine,
      points: points ?? this.points,
      lanes: lanes ?? this.lanes,
      services: services ?? this.services,
      cells: cells ?? this.cells,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      metadata: metadata ?? this.metadata,
    );
  }

  static List<ScheduleLinearLaneData> _parseLanes(dynamic value) {
    if (value is! List) return const <ScheduleLinearLaneData>[];

    return value
        .whereType<Object>()
        .map((item) {
      if (item is Map) {
        return ScheduleLinearLaneData.fromMap(
          Map<String, dynamic>.from(item),
        );
      }

      return null;
    })
        .whereType<ScheduleLinearLaneData>()
        .toList(growable: false);
  }

  static List<ScheduleLinearServicesData> _parseServices(dynamic value) {
    if (value is! List) {
      return const <ScheduleLinearServicesData>[
        ScheduleLinearServicesData.emptyGeral,
      ];
    }

    final items = value
        .whereType<Object>()
        .map((item) {
      if (item is Map) {
        return ScheduleLinearServicesData.fromMap(
          Map<String, dynamic>.from(item),
        );
      }

      return null;
    })
        .whereType<ScheduleLinearServicesData>()
        .toList(growable: false);

    if (items.isEmpty) {
      return const <ScheduleLinearServicesData>[
        ScheduleLinearServicesData.emptyGeral,
      ];
    }

    return items;
  }

  static List<ScheduleLinearCellData> _parseCells(dynamic value) {
    if (value is! List) return const <ScheduleLinearCellData>[];

    return value
        .whereType<Object>()
        .map((item) {
      if (item is Map) {
        return ScheduleLinearCellData.fromMap(
          Map<String, dynamic>.from(item),
        );
      }

      return null;
    })
        .whereType<ScheduleLinearCellData>()
        .toList(growable: false);
  }

  static List<List<LatLng>>? _parseMulti(dynamic geometry) {
    if (geometry is! List) return null;

    final out = <List<LatLng>>[];

    for (final segment in geometry) {
      if (segment is Map) {
        final points = segment['points'];
        final parsed = _parsePoints(points);

        if (parsed != null && parsed.length >= 2) {
          out.add(parsed);
        }

        continue;
      }

      if (segment is! List) continue;

      final line = <LatLng>[];

      for (final pointRaw in segment) {
        final point = _parseLatLngPoint(pointRaw);

        if (point != null) {
          line.add(point);
        }
      }

      if (line.length >= 2) {
        out.add(line);
      }
    }

    return out.isEmpty ? null : out;
  }

  static List<LatLng>? _parsePoints(dynamic value) {
    if (value is! List) return null;

    final out = <LatLng>[];

    for (final pointRaw in value) {
      final point = _parseLatLngPoint(pointRaw);

      if (point != null) {
        out.add(point);
      }
    }

    return out.length < 2 ? null : out;
  }

  static LatLng? _parseLatLngPoint(dynamic pointRaw) {
    if (pointRaw is GeoPoint) {
      return LatLng(pointRaw.latitude, pointRaw.longitude);
    }

    if (pointRaw is List && pointRaw.length >= 2) {
      final lon = _asDouble(pointRaw[0]);
      final lat = _asDouble(pointRaw[1]);

      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    if (pointRaw is Map) {
      final rawLat = pointRaw['lat'] ?? pointRaw['latitude'];
      final rawLon =
          pointRaw['lng'] ?? pointRaw['longitude'] ?? pointRaw['lon'];

      final lat = _asDouble(rawLat);
      final lon = _asDouble(rawLon);

      if (lat != null && lon != null) {
        return LatLng(lat, lon);
      }
    }

    return null;
  }

  static List<List<dynamic>>? _toMultiList(List<List<LatLng>>? multiLine) {
    if (multiLine == null) return null;

    final validSegments = multiLine
        .where((segment) => segment.length >= 2)
        .toList(growable: false);

    if (validSegments.isEmpty) return null;

    return validSegments
        .map(
          (segment) => segment
          .map(
            (point) => <double>[
          point.longitude,
          point.latitude,
        ],
      )
          .toList(growable: false),
    )
        .toList(growable: false);
  }

  static List<dynamic>? _toPoints(List<LatLng>? points) {
    if (points == null || points.length < 2) return null;

    return points
        .map(
          (point) => <String, double>{
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
    )
        .toList(growable: false);
  }

  static Map<String, dynamic> _asDynamicMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const <String, dynamic>{};
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.');

      if (cleaned.isEmpty) return null;

      return double.tryParse(cleaned);
    }

    return null;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) return null;

      final asInt = int.tryParse(cleaned);

      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt);
      }

      return DateTime.tryParse(cleaned);
    }

    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    contractId,
    tenantId,
    title,
    geometryType,
    multiLine,
    points,
    lanes,
    services,
    cells,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    metadata,
  ];
}