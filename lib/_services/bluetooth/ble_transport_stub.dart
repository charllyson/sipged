import 'dart:typed_data';
import 'ble_transport_iface.dart';

class _Stub implements LabelBleTransport {
  @override
  bool get isConnected => false;

  @override
  String? get deviceLabel => null;

  @override
  Future<void> connect() async {
    throw UnsupportedError('BLE não suportado nesta plataforma.');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> writeAll(Uint8List data, {int chunk = 180, int delayMs = 8}) async {
    throw UnsupportedError('BLE não suportado nesta plataforma.');
  }
}

LabelBleTransport createBleTransport() => _Stub();