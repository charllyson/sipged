import 'package:flutter/foundation.dart';
import 'package:sipged/_services/bluetooth/ble_client_iface.dart';
import 'package:sipged/_services/bluetooth/ble_transport_iface.dart';

/// ✅ Adapter que implementa LabelBleClient para reaproveitar sendTsplBitmapLabel
class LabelBleClientAdapter implements LabelBleClient {
  LabelBleClientAdapter(this._t, {required this.delayMsDefault});

  final LabelBleTransport _t;
  final int delayMsDefault;

  @override
  Future<void> connect() => _t.connect();

  @override
  Future<void> disconnect() => _t.disconnect();

  @override
  Future<void> writeAll(Uint8List data, {int chunk = 180}) {
    return _t.writeAll(
      data,
      chunk: chunk,
      delayMs: delayMsDefault,
    );
  }
}