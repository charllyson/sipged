// lib/_widgets/bluetooth/bitmap/ble_client_native.dart
import 'dart:typed_data';
import 'ble_client_iface.dart';

class _NativeClient implements LabelBleClient {
  @override
  Future<void> connect() async {
    throw UnsupportedError(
      'BLE nativo exige seleção de dispositivo. Use a tela LabelPrintPage (nativo) '
          'para conectar e imprimir no mobile.',
    );
  }

  @override
  Future<void> writeAll(Uint8List data, {int chunk = 180}) async {
    throw UnsupportedError(
      'BLE nativo não inicializado. Use a tela LabelPrintPage (nativo).',
    );
  }

  @override
  Future<void> disconnect() async {}
}

LabelBleClient createBleClient() => _NativeClient();