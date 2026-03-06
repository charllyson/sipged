import 'dart:typed_data';

abstract class LabelBleTransport {
  bool get isConnected;
  String? get deviceLabel;

  /// Conecta. No Web abre o chooser. No mobile abre um scanner interno.
  Future<void> connect();

  Future<void> disconnect();

  /// Escreve tudo em fatias (chunk) com delay entre fatias.
  Future<void> writeAll(
      Uint8List data, {
        int chunk = 180,
        int delayMs = 8,
      });
}