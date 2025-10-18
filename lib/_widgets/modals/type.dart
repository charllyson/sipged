// lib/_widgets/modals/type.dart
import 'package:siged/_widgets/carousel/carousel_metadata.dart' as pm;

enum ScheduleType {
  rodoviario,
  civil;

  String get singularUnit {
    switch (this) {
      case ScheduleType.rodoviario: return 'célula';
      case ScheduleType.civil:      return 'polígono';
    }
  }

  String get pluralUnit {
    switch (this) {
      case ScheduleType.rodoviario: return 'células';
      case ScheduleType.civil:      return 'polígonos';
    }
  }

  String get titlePrefix {
    switch (this) {
      case ScheduleType.rodoviario: return 'Editando estaca:';
      case ScheduleType.civil:      return 'Editando área:';
    }
  }
}

/// Destino(s) de aplicação no salvar.
/// Unitário: 1 item. Lote: vários itens.
class ScheduleApplyTarget {
  final int estaca;
  final int faixaIndex;

  /// Fotos já existentes nesse destino (serão preservadas)
  final List<String> existingUrls;

  /// Metadados (opcional) por URL – usados só para exibir no carrossel
  final Map<String, pm.CarouselMetadata> existingMetaByUrl;

  const ScheduleApplyTarget({
    required this.estaca,
    required this.faixaIndex,
    this.existingUrls = const [],
    this.existingMetaByUrl = const {},
  });
}
