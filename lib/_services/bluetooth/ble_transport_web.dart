import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as fwb;

import 'ble_transport_iface.dart';

class _WebTransport implements LabelBleTransport {
  fwb.BluetoothDevice? _dev;
  fwb.BluetoothCharacteristic? _ch;

  bool _supportsWriteWithResponse = false;
  bool _supportsWriteWithoutResponse = false;

  @override
  bool get isConnected => _dev != null && _ch != null;

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
    await disconnect();

    final opts = fwb.RequestOptionsBuilder.acceptAllDevices(
      optionalServices: _knownServices,
    );

    final dev = await fwb.FlutterWebBluetooth.instance.requestDevice(opts);
    await dev.connect();

    final services = await dev.discoverServices();

    fwb.BluetoothCharacteristic? writableChar;
    bool supportsWriteWithResponse = false;
    bool supportsWriteWithoutResponse = false;

    for (final svc in services) {
      final chars = await svc.getCharacteristics();

      for (final c in chars) {
        final p = c.properties;
        if (p.write || p.writeWithoutResponse) {
          writableChar = c;
          supportsWriteWithResponse = p.write;
          supportsWriteWithoutResponse = p.writeWithoutResponse;
          break;
        }
      }

      if (writableChar != null) break;
    }

    if (writableChar == null) {
      try {
        dev.disconnect();
      } catch (_) {}

      throw StateError('Não encontrei characteristic de escrita neste BLE.');
    }

    _dev = dev;
    _ch = writableChar;
    _supportsWriteWithResponse = supportsWriteWithResponse;
    _supportsWriteWithoutResponse = supportsWriteWithoutResponse;
  }

  @override
  Future<void> writeAll(
      Uint8List data, {
        int chunk = 180,
        int delayMs = 8,
      }) async {
    final ch = _ch;
    if (ch == null) {
      throw StateError('BLE não conectado.');
    }

    // Chrome/Web BLE costuma ficar mais estável perto de 180–200 bytes.
    final step = math.max(1, math.min(chunk, 200));
    final wait = Duration(milliseconds: math.max(0, delayMs));

    for (int i = 0; i < data.length; i += step) {
      final end = math.min(i + step, data.length);
      final slice = Uint8List.sublistView(data, i, end);

      if (_supportsWriteWithResponse) {
        await ch.writeValueWithResponse(slice);
      } else if (_supportsWriteWithoutResponse) {
        await ch.writeValueWithoutResponse(slice);
      } else {
        throw StateError('Characteristic não suporta escrita.');
      }

      if (delayMs > 0) {
        await Future.delayed(wait);
      }
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      _dev?.disconnect();
    } catch (_) {
      // ignora
    } finally {
      _dev = null;
      _ch = null;
      _supportsWriteWithResponse = false;
      _supportsWriteWithoutResponse = false;
    }
  }
}

LabelBleTransport createBleTransport() => _WebTransport();