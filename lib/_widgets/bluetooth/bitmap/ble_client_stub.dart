import 'dart:typed_data';
import 'ble_client_iface.dart';

class _StubClient implements LabelBleClient {
  @override Future<void> connect() async =>
      throw UnsupportedError('BLE não suportado nesta plataforma.');
  @override Future<void> writeAll(Uint8List data, {int chunk = 180}) async =>
      throw UnsupportedError('BLE não suportado nesta plataforma.');
  @override Future<void> disconnect() async {}
}

LabelBleClient createBleClient() => _StubClient();
