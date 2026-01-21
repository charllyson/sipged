// lib/_blocs/ifc/ifc_viewer_data.dart
class IfcViewerConfig {
  /// ID estável dessa instância (p/ mensagens postMessage)
  final String viewId;

  /// Cor de fundo do viewer (hex)
  final String backgroundColorHex;

  /// Se quiser já carregar um IFC remoto no início (opcional)
  final String? initialIfcUrl;

  const IfcViewerConfig({
    required this.viewId,
    this.backgroundColorHex = '#111111',
    this.initialIfcUrl,
  });

  Map<String, dynamic> toJson() => {
    'viewId': viewId,
    'backgroundColorHex': backgroundColorHex,
    'initialIfcUrl': initialIfcUrl,
  };
}
