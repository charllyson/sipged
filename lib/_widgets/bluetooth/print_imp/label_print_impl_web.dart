/*

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_web_bluetooth/flutter_web_bluetooth.dart' as fwb;

import 'package:flutter_web_bluetooth/js_web_bluetooth.dart' as fwb;
import 'package:siged/_widgets/bluetooth/print_imp/tspl_builder.dart';

// ===== TOP-LEVEL EXIGIDO PELO IMPORT CONDICIONAL =====
Widget buildLabelPrintPage({
  String? initialText,
  String? initialQr,
  Size? initialSizeMm,
}) => _LabelPrintWebPage(
  initialText: initialText,
  initialQr: initialQr,
  initialSizeMm: initialSizeMm,
);

class _LabelPrintWebPage extends StatefulWidget {
  final String? initialText;
  final String? initialQr;
  final Size? initialSizeMm;

  const _LabelPrintWebPage({
    this.initialText,
    this.initialQr,
    this.initialSizeMm,
  });

  @override
  State<_LabelPrintWebPage> createState() => _LabelPrintWebPageState();
}

class _LabelPrintWebPageState extends State<_LabelPrintWebPage> {
  fwb.BluetoothDevice? _dev;
  fwb.WebBluetoothRemoteGATTCharacteristic? _ch;
  static const _svcFfe0 = '49535343-fe7d-4ae5-8fa9-9fafd205e455';
  static const _chrFfe1 = '49535343-1e4d-4bd9-ba61-23c647249616';


  final _textoCtrl = TextEditingController();
  final _qrCtrl    = TextEditingController();
  final _larguraMMCtrl = TextEditingController(text: '40');
  final _alturaMMCtrl  = TextEditingController(text: '30');
  final _gapMMCtrl     = TextEditingController(text: '2');

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _textoCtrl.text = widget.initialText ?? 'SIGED • DNIT/DER';
    _qrCtrl.text    = widget.initialQr   ?? 'https://siged.app/';
    if (widget.initialSizeMm != null) {
      _larguraMMCtrl.text = widget.initialSizeMm!.width.toStringAsFixed(0);
      _alturaMMCtrl.text  = widget.initialSizeMm!.height.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    _qrCtrl.dispose();
    _larguraMMCtrl.dispose();
    _alturaMMCtrl.dispose();
    _gapMMCtrl.dispose();
    try {
      final gatt = _dev?.gatt;
      if (gatt != null) {
        gatt.disconnect(); // retorna void na 1.1.0
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final opts = fwb.RequestOptionsBuilder.acceptAllDevices(
        optionalServices: const [_svcFfe0],
      );

      _dev = await fwb.FlutterWebBluetooth.instance.requestDevice(opts);
      final gatt = await _dev!.gatt!.connect();
      final svc = await gatt.getPrimaryService(_svcFfe0);

      // tenta FFE1 direto
      try {
        _ch = await svc.getCharacteristic(_chrFfe1);
      } catch (_) {
        // fallback: primeira com write/writeWithoutResponse
        final list = await svc.getCharacteristics();
        for (final c in list) {
          final p = c.properties; // síncrono
          if (p.write || p.writeWithoutResponse) {
            _ch = c;
            break;
          }
        }
      }

      if (_ch == null) {
        throw Exception('Característica de escrita não encontrada (FFE1).');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conectado à impressora!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao conectar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _print() async {
    final ch = _ch;
    if (ch == null) {
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

    // fatiar (Chrome costuma aceitar ~185 bytes)
    final data = Uint8List.fromList(utf8.encode('$tspl\r\n'));
    const chunk = 180;
    for (int i = 0; i < data.length; i += chunk) {
      final end = math.min(i + chunk, data.length);
      await ch.writeValueWithResponse(data.sublist(i, end));
    }

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
    final connected = _ch != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Impressão de Etiqueta (Web BLE)')),
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
                  onPressed: _busy ? null : _connect,
                  icon: const Icon(Icons.bluetooth),
                  label: Text(_busy ? 'Conectando...' : 'Conectar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: connected && !_busy ? _print : null,
                  icon: const Icon(Icons.print),
                  label: const Text('Imprimir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
*/
