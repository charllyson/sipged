import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as fwb;
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart' as js;

import 'ble_client_iface.dart';

class _WebClient implements LabelBleClient {
  fwb.BluetoothDevice? _dev;
  js.WebBluetoothRemoteGATTCharacteristic? _ch;

  bool _supportsWriteWithResponse = false;
  bool _supportsWriteWithoutResponse = false;

  static const List<String> _knownServices = [
    '49535343-fe7d-4ae5-8fa9-9fafd205e455',
    '0000ffe0-0000-1000-8000-00805f9b34fb',
    '0000ae30-0000-1000-8000-00805f9b34fb',
    '0000ff00-0000-1000-8000-00805f9b34fb',
    '000018f0-0000-1000-8000-00805f9b34fb',
  ];

  @override
  Future<void> connect() async {
    final opts = fwb.RequestOptionsBuilder.acceptAllDevices(
      optionalServices: _knownServices,
    );

    _dev = await fwb.FlutterWebBluetooth.instance.requestDevice(opts);

    // ignore: invalid_use_of_visible_for_testing_member
    final gatt = await _dev!.gatt!.connect();

    final services = await gatt.getPrimaryServices();
    for (final svc in services) {
      final chars = await svc.getCharacteristics();
      for (final c in chars) {
        final p = c.properties;
        if (p.write || p.writeWithoutResponse) {
          _ch = c;
          _supportsWriteWithResponse = p.write;
          _supportsWriteWithoutResponse = p.writeWithoutResponse;
          break;
        }
      }
      if (_ch != null) break;
    }

    if (_ch == null) {
      throw StateError(
        'Não encontrei característica de escrita neste dispositivo BLE.',
      );
    }
  }

  @override
  Future<void> writeAll(Uint8List data, {int chunk = 180}) async {
    final ch = _ch;
    if (ch == null) throw StateError('BLE não conectado.');

    final step = math.max(1, math.min(chunk, 200));

    for (int i = 0; i < data.length; i += step) {
      final end = math.min(i + step, data.length);
      final slice = data.sublist(i, end);

      if (_supportsWriteWithResponse) {
        await ch.writeValueWithResponse(slice);
      } else if (_supportsWriteWithoutResponse) {
        await ch.writeValueWithoutResponse(slice);
      } else {
        throw StateError('Característica não suporta escrita.');
      }

      await Future.delayed(const Duration(milliseconds: 4));
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      final gatt = _dev?.gatt;
      if (gatt != null) {
        gatt.disconnect();
      }
    } catch (_) {}
  }
}

LabelBleClient createBleClient() => _WebClient();