import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as fwb;
import 'package:flutter_web_bluetooth/js_web_bluetooth.dart' as js;

import 'ble_transport_iface.dart';

class _WebTransport implements LabelBleTransport {
  fwb.BluetoothDevice? _dev;
  js.WebBluetoothRemoteGATTCharacteristic? _ch;

  bool _supportsWriteWithResponse = false;
  bool _supportsWriteWithoutResponse = false;

  @override
  bool get isConnected => _ch != null;

  @override
  String? get deviceLabel {
    final d = _dev;
    if (d == null) return null;
    final n = (d.name ?? '').trim();
    return n.isNotEmpty ? n : d.id;
  }

  // Serviços comuns em impressoras BLE (hints)
  static const List<String> _knownServices = [
    '49535343-fe7d-4ae5-8fa9-9fafd205e455', // Nordic UART / HM-10
    '0000ffe0-0000-1000-8000-00805f9b34fb', // FFE0/FFE1
    '0000ae30-0000-1000-8000-00805f9b34fb', // AE30/AE01
    '0000ff00-0000-1000-8000-00805f9b34fb',
    '000018f0-0000-1000-8000-00805f9b34fb',
  ];

  @override
  Future<void> connect() async {
    _dev = null;
    _ch = null;
    _supportsWriteWithResponse = false;
    _supportsWriteWithoutResponse = false;

    final opts = fwb.RequestOptionsBuilder.acceptAllDevices(
      optionalServices: _knownServices,
    );

    _dev = await fwb.FlutterWebBluetooth.instance.requestDevice(opts);
    final gatt = await _dev!.gatt!.connect();

    final services = await gatt.getPrimaryServices();

    for (final svc in services) {
      final chars = await svc.getCharacteristics();
      for (final c in chars) {
        final p = c.properties; // síncrono
        if (p.write || p.writeWithoutResponse) {
          _ch = c; // js.WebBluetoothRemoteGATTCharacteristic
          _supportsWriteWithResponse = p.write;
          _supportsWriteWithoutResponse = p.writeWithoutResponse;
          break;
        }
      }
      if (_ch != null) break;
    }

    if (_ch == null) {
      throw StateError('Não encontrei characteristic de escrita neste BLE.');
    }
  }

  @override
  Future<void> writeAll(
      Uint8List data, {
        int chunk = 180,
        int delayMs = 8,
      }) async {
    final ch = _ch;
    if (ch == null) throw StateError('BLE não conectado.');

    // Chrome costuma ser estável ~180-200. Vamos limitar.
    final step = math.max(1, math.min(chunk, 200));
    final wait = Duration(milliseconds: math.max(0, delayMs));

    for (int i = 0; i < data.length; i += step) {
      final end = math.min(i + step, data.length);
      final slice = data.sublist(i, end);

      if (_supportsWriteWithResponse) {
        await ch.writeValueWithResponse(slice);
      } else if (_supportsWriteWithoutResponse) {
        await ch.writeValueWithoutResponse(slice);
      } else {
        throw StateError('Characteristic não suporta escrita.');
      }

      if (delayMs > 0) await Future.delayed(wait);
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      final gatt = _dev?.gatt;
      if (gatt != null) gatt.disconnect();
    } catch (_) {}
    _dev = null;
    _ch = null;
  }
}

LabelBleTransport createBleTransport() => _WebTransport();