/*
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:sipged/_widgets/bluetooth/print_imp/tspl_builder.dart';

// ===== TOP-LEVEL EXIGIDO PELO IMPORT CONDICIONAL =====
Widget buildLabelPrintPage({
  String? initialText,
  String? initialQr,
  Size? initialSizeMm,
}) => _LabelPrintNativePage(
  initialText: initialText,
  initialQr: initialQr,
  initialSizeMm: initialSizeMm,
);

class _LabelPrintNativePage extends StatefulWidget {
  final String? initialText;
  final String? initialQr;
  final Size? initialSizeMm;

  const _LabelPrintNativePage({
    this.initialText,
    this.initialQr,
    this.initialSizeMm,
  });

  @override
  State<_LabelPrintNativePage> createState() => _LabelPrintNativePageState();
}

class _LabelPrintNativePageState extends State<_LabelPrintNativePage> {
  final scanStream = FlutterBluePlus.scanResults;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeChar;

  bool _scanning = false;
  bool _connecting = false;

  final _textoCtrl = TextEditingController();
  final _qrCtrl    = TextEditingController();
  final _larguraMMCtrl = TextEditingController();
  final _alturaMMCtrl  = TextEditingController();
  final _gapMMCtrl     = TextEditingController(text: '2');

  @override
  void initState() {
    super.initState();
    _textoCtrl.text = widget.initialText ?? 'SIGED • DNIT/DER';
    _qrCtrl.text    = widget.initialQr   ?? 'https://siged.app/';
    _larguraMMCtrl.text = (widget.initialSizeMm?.width  ?? 40).toStringAsFixed(0);
    _alturaMMCtrl.text  = (widget.initialSizeMm?.height ?? 30).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    _qrCtrl.dispose();
    _larguraMMCtrl.dispose();
    _alturaMMCtrl.dispose();
    _gapMMCtrl.dispose();
    _stopScanSafely();
    _device?.disconnect();
    super.dispose();
  }

  Future<void> _stopScanSafely() async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
  }

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _connect(BluetoothDevice d) async {
    if (_connecting) return;

    setState(() => _connecting = true);
    _device = d;
    _writeChar = null;

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

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _writeChar == null
                  ? 'Não achei characteristic de escrita.'
                  : 'Conectado à impressora!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao conectar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _sendBytes(List<int> bytes) async {
    final c = _writeChar;
    if (c == null) return;

    const chunk = 200;
    for (var i = 0; i < bytes.length; i += chunk) {
      final part = bytes.sublist(i, math.min(i + chunk, bytes.length));
      await c.write(part, withoutResponse: true);
      await Future.delayed(const Duration(milliseconds: 12));
    }
  }

  Future<void> _print() async {
    if (_device == null || _writeChar == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conecte-se à impressora primeiro.')),
      );
      return;
    }

    final largura = double.tryParse(_larguraMMCtrl.text.trim()) ?? 40;
    final altura  = double.tryParse(_alturaMMCtrl.text.trim())  ?? 30;
    final gap     = double.tryParse(_gapMMCtrl.text.trim())     ?? 2;

    final tspl = buildTspl(
      larguraMm: largura,
      alturaMm: altura,
      gapMm: gap,
      texto: _textoCtrl.text,
      qrData: _qrCtrl.text,
      includeForm: true,
    );

    await _sendBytes(utf8.encode('$tspl\r\n'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Etiqueta enviada!')),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impressão de Etiqueta (BLE Nativo)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _numField(_larguraMMCtrl, 'Largura (mm)')),
                const SizedBox(width: 8),
                Expanded(child: _numField(_alturaMMCtrl, 'Altura (mm)')),
                const SizedBox(width: 8),
                Expanded(child: _numField(_gapMMCtrl, 'Gap (mm)')),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textoCtrl,
              decoration: const InputDecoration(
                labelText: 'Texto da etiqueta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qrCtrl,
              decoration: const InputDecoration(
                labelText: 'Conteúdo do QR Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: const Icon(Icons.search),
                  label: Text(_scanning ? 'Procurando...' : 'Buscar impressoras'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (_writeChar != null && !_connecting) ? _print : null,
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: StreamBuilder<List<ScanResult>>(
                stream: scanStream,
                builder: (context, snap) {
                  final results = snap.data ?? const [];
                  if (results.isEmpty) {
                    return const Center(child: Text('Nenhum dispositivo encontrado.'));
                  }
                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final r = results[i];
                      final dev = r.device;
                      final name = dev.platformName.isNotEmpty
                          ? dev.platformName
                          : dev.remoteId.str;

                      final isThis = _device?.remoteId == dev.remoteId;

                      return ListTile(
                        title: Text(name),
                        subtitle: Text('RSSI: ${r.rssi}'),
                        trailing: ElevatedButton(
                          onPressed: _connecting ? null : () => _connect(dev),
                          child: Text(
                            isThis
                                ? (_writeChar != null ? 'Conectado' : 'Abrindo...')
                                : 'Conectar',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
