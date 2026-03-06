// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_transport_iface.dart';

class _NativeTransport implements LabelBleTransport {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;

  @override
  bool get isConnected => _device != null && _writeChar != null;

  @override
  String? get deviceLabel {
    final d = _device;
    if (d == null) return null;
    final n = d.platformName.trim();
    return n.isNotEmpty ? n : d.remoteId.str;
  }

  /// Abre um dialog que faz scan e retorna o device escolhido.
  Future<BluetoothDevice?> _pickDevice(BuildContext context) async {
    final results = <ScanResult>[];
    final sub = FlutterBluePlus.scanResults.listen((list) {
      results
        ..clear()
        ..addAll(list);
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));

      if (!context.mounted) return null;

      return showDialog<BluetoothDevice>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Selecionar impressora BLE'),
            content: SizedBox(
              width: 520,
              height: 420,
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                builder: (context, snap) {
                  final list = snap.data ?? const [];
                  if (list.isEmpty) {
                    return const Center(child: Text('Nenhum dispositivo encontrado...'));
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final r = list[i];
                      final dev = r.device;
                      final name = dev.platformName.isNotEmpty
                          ? dev.platformName
                          : dev.remoteId.str;
                      return ListTile(
                        title: Text(name),
                        subtitle: Text('RSSI: ${r.rssi}'),
                        onTap: () => Navigator.of(ctx).pop(dev),
                      );
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );
    } finally {
      try { await FlutterBluePlus.stopScan(); } catch (_) {}
      await sub.cancel();
    }
  }

  /// Esse connect exige contexto para abrir dialog. Então aqui a gente espera
  /// que quem chama configure via setContext (na página). Para não mudar sua base,
  /// deixei um fallback com erro claro.
  BuildContext? _ctx;

  void attachContext(BuildContext context) => _ctx = context;

  @override
  Future<void> connect() async {
    final ctx = _ctx;
    if (ctx == null) {
      throw StateError('NativeTransport sem context. Chame attachContext(context) antes.');
    }

    _device = null;
    _writeChar = null;

    final d = await _pickDevice(ctx);
    if (d == null) throw StateError('Seleção cancelada.');

    _device = d;

    try {
      try { await d.disconnect(); } catch (_) {}
      await d.connect(autoConnect: false);
      try { await d.requestMtu(247); } catch (_) {}

      final services = await d.discoverServices();
      BluetoothCharacteristic? found;
      for (final s in services) {
        for (final c in s.characteristics) {
          final canWrite = c.properties.write || c.properties.writeWithoutResponse;
          if (canWrite) { found = c; break; }
        }
        if (found != null) break;
      }

      _writeChar = found;

      if (_writeChar == null) {
        throw StateError('Não achei characteristic de escrita no device.');
      }
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  @override
  Future<void> writeAll(
      Uint8List data, {
        int chunk = 180,
        int delayMs = 8,
      }) async {
    final c = _writeChar;
    if (c == null) throw StateError('BLE não conectado.');

    // no mobile: 200~240 costuma ser ok se MTU permitir. Vamos respeitar chunk.
    final step = math.max(1, math.min(chunk, 240));
    final wait = Duration(milliseconds: math.max(0, delayMs));

    final useWithoutResponse = c.properties.writeWithoutResponse && !c.properties.write;
    // se tiver write normal, prefiro withResponse quando debugando confiabilidade
    final withoutResponse = useWithoutResponse;

    for (int i = 0; i < data.length; i += step) {
      final end = math.min(i + step, data.length);
      final part = data.sublist(i, end);
      await c.write(part, withoutResponse: withoutResponse);
      if (delayMs > 0) await Future.delayed(wait);
    }
  }

  @override
  Future<void> disconnect() async {
    try { await _device?.disconnect(); } catch (_) {}
    _device = null;
    _writeChar = null;
  }
}

LabelBleTransport createBleTransport() => _NativeTransport();