import 'dart:typed_data';

abstract class LabelBleClient {
  Future<void> connect();
  Future<void> writeAll(Uint8List data, {int chunk = 180});
  Future<void> disconnect();
}
