// lib/screens/modules/operation/schedule/common/schedule_type.dart

enum ScheduleType {
  rodoviario,
  civil;

  String get singularUnit {
    switch (this) {
      case ScheduleType.rodoviario:
        return 'célula';
      case ScheduleType.civil:
        return 'polígono';
    }
  }

  String get pluralUnit {
    switch (this) {
      case ScheduleType.rodoviario:
        return 'células';
      case ScheduleType.civil:
        return 'polígonos';
    }
  }

  String get titlePrefix {
    switch (this) {
      case ScheduleType.rodoviario:
        return 'Editando estaca:';
      case ScheduleType.civil:
        return 'Editando área:';
    }
  }

  bool get isRodoviario => this == ScheduleType.rodoviario;

  bool get isCivil => this == ScheduleType.civil;
}

/// Destino usado pelo modal de execução.
///
/// No rodoviário:
/// - `estaca` representa a estaca.
/// - `faixaIndex` representa a faixa.
///
/// No civil:
/// - `estaca` pode representar o índice local do polígono.
/// - `faixaIndex` normalmente será 0.
/// - `polygonId` contém o ID real do polígono no Firestore.
class ScheduleApplyTarget {
  const ScheduleApplyTarget({
    required this.estaca,
    required this.faixaIndex,
    this.polygonId,
    this.name,
    this.existingUrls = const <String>[],
    this.existingMetaByUrl = const <String, Map<String, dynamic>>{},
  });

  final int estaca;
  final int faixaIndex;

  final String? polygonId;
  final String? name;

  /// URLs já existentes nesse destino.
  final List<String> existingUrls;

  /// Metadados crus por URL.
  ///
  /// Exemplo:
  /// {
  ///   'https://...jpg': {
  ///     'url': 'https://...jpg',
  ///     'name': 'foto.jpg',
  ///     'takenAtMs': 123456789,
  ///     'lat': -9.6,
  ///     'lng': -35.7,
  ///   }
  /// }
  final Map<String, Map<String, dynamic>> existingMetaByUrl;

  ScheduleApplyTarget copyWith({
    int? estaca,
    int? faixaIndex,
    String? polygonId,
    String? name,
    List<String>? existingUrls,
    Map<String, Map<String, dynamic>>? existingMetaByUrl,
    bool clearPolygonId = false,
    bool clearName = false,
  }) {
    return ScheduleApplyTarget(
      estaca: estaca ?? this.estaca,
      faixaIndex: faixaIndex ?? this.faixaIndex,
      polygonId: clearPolygonId ? null : polygonId ?? this.polygonId,
      name: clearName ? null : name ?? this.name,
      existingUrls: existingUrls ?? this.existingUrls,
      existingMetaByUrl: existingMetaByUrl ?? this.existingMetaByUrl,
    );
  }
}