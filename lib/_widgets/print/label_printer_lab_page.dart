import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/print/preview_panel.dart';
import 'package:sipged/_widgets/print/label_bitmap.dart';

// ✅ Seleção do preview
import 'package:sipged/_widgets/print/label_preview_painter.dart';

import '../../_services/bluetooth/ble_transport.dart';
import '../../_services/bluetooth/ble_transport_iface.dart';

class LabelPrinterLabPage extends StatefulWidget {
  const LabelPrinterLabPage({super.key});

  @override
  State<LabelPrinterLabPage> createState() => _LabelPrinterLabPageState();
}

class _LabelPrinterLabPageState extends State<LabelPrinterLabPage> {
  late final LabelBleTransport _ble;

  bool _busy = false;

  static const int _chunkBytes = 200;
  static const int _delayMs = 100;

  // Label params (mm)
  final _wCtrl = TextEditingController(text: '15');
  final _hCtrl = TextEditingController(text: '30');
  final _gapCtrl = TextEditingController(text: '10');

  // padding interno (mm)
  final _padCtrl = TextEditingController(text: '2');

  // ✅ NOVO: tamanho do texto (8,9,10,11...)
  // 10 = base (scale 1.0)
  final _textSizeCtrl = TextEditingController(text: '20');

  final _textCtrl = TextEditingController(text: 'SIPGED • ');
  final _qrCtrl = TextEditingController(text: 'https://deral.sipged.com.br/');

  // Focus
  final _wFocus = FocusNode();
  final _hFocus = FocusNode();
  final _gapFocus = FocusNode();
  final _padFocus = FocusNode();

  final _textFocus = FocusNode();
  final _textSizeFocus = FocusNode(); // ✅ novo
  final _qrFocus = FocusNode();

  PreviewSection _selectedSection = PreviewSection.none;

  @override
  void initState() {
    super.initState();
    _ble = createBleTransport();

    for (final c in [
      _wCtrl,
      _hCtrl,
      _gapCtrl,
      _padCtrl,
      _textSizeCtrl,
      _textCtrl,
      _qrCtrl,
    ]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }

    void bind(FocusNode n, PreviewSection section) {
      n.addListener(() {
        if (!mounted) return;
        if (n.hasFocus) setState(() => _selectedSection = section);
      });
    }

    bind(_wFocus, PreviewSection.widthRuler);
    bind(_hFocus, PreviewSection.heightRuler);
    bind(_gapFocus, PreviewSection.gap);
    bind(_padFocus, PreviewSection.padding);

    // ✅ tamanho e texto destacam "text"
    bind(_textFocus, PreviewSection.text);
    bind(_textSizeFocus, PreviewSection.text);

    bind(_qrFocus, PreviewSection.qr);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      // ignore: avoid_dynamic_calls
      (_ble as dynamic).attachContext(context);
    } catch (_) {}
  }

  @override
  void dispose() {
    _wCtrl.dispose();
    _hCtrl.dispose();
    _gapCtrl.dispose();
    _padCtrl.dispose();
    _textSizeCtrl.dispose();

    _textCtrl.dispose();
    _qrCtrl.dispose();

    _wFocus.dispose();
    _hFocus.dispose();
    _gapFocus.dispose();
    _padFocus.dispose();

    _textFocus.dispose();
    _textSizeFocus.dispose();
    _qrFocus.dispose();

    super.dispose();
  }

  double get _wMm => double.tryParse(_wCtrl.text.trim().replaceAll(',', '.')) ?? 40;
  double get _hMm => double.tryParse(_hCtrl.text.trim().replaceAll(',', '.')) ?? 30;
  double get _gapMm => double.tryParse(_gapCtrl.text.trim().replaceAll(',', '.')) ?? 0;
  double get _padMm => double.tryParse(_padCtrl.text.trim().replaceAll(',', '.')) ?? 1.5;

  // ✅ tamanho “sistema” (8..30)
  double get _textSizeUi {
    final v = double.tryParse(_textSizeCtrl.text.trim().replaceAll(',', '.')) ?? 10;
    return v.clamp(6.0, 40.0);
  }

  // ✅ converte tamanho “sistema” para escala interna
  double get _textScale => (_textSizeUi / 10.0).clamp(0.4, 4.0);

  Future<void> _run(Future<void> Function() fn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run(() async => _ble.connect());
  Future<void> _disconnect() => _run(() async => _ble.disconnect());

  Future<void> _printEscPosFromCanvas() => _run(() async {
    const dpi = 203;

    final cfg = LabelLayoutConfig(
      padMm: _padMm,
      qrSidePctOfShort: 1.0,
      textMaxLines: 3,
      spaceBetweenMm: 0.6,

      matchPreviewTextSizing: true,
      previewFontMinPx: 12,
      previewFontMaxPx: 16,

      // ✅ aqui entra o tamanho "8/9/10/11..."
      textScale: _textScale,
    );

    final bmp = await renderLabelMonoPackedRowAligned(
      larguraMm: _wMm,
      alturaMm: _hMm,
      texto: _textCtrl.text,
      qrData: _qrCtrl.text,
      dpi: dpi,
      threshold: 140,
      cfg: cfg,
    );

    await _sendEscPosRasterInChunks(
      ble: _ble,
      bmp: bmp,
      chunkHeight: 24,
      feedMm: _gapMm,
      invert: false,
      chunk: _chunkBytes,
      delayMs: _delayMs,
    );
  });

  Future<void> _sendEscPosRasterInChunks({
    required LabelBleTransport ble,
    required MonoBitmap bmp,
    int chunkHeight = 24,
    double feedMm = 2,
    bool invert = false,
    required int chunk,
    required int delayMs,
  }) async {
    final widthPx = bmp.widthPx;
    final height = bmp.heightPx;
    final bytesPerRow = (widthPx + 7) >> 3;

    final dotsPerMm = 203 / 25.4;
    final feedDots = (feedMm * dotsPerMm).round();

    final header = BytesBuilder();
    header.add([0x1B, 0x40]); // init
    header.add([0x1B, 0x61, 0x00]); // align left
    await ble.writeAll(header.toBytes(), chunk: chunk, delayMs: delayMs);

    for (int y = 0; y < height; y += chunkHeight) {
      final h = (y + chunkHeight <= height) ? chunkHeight : height - y;
      final yL = h & 0xFF;
      final yH = (h >> 8) & 0xFF;

      final block = BytesBuilder();
      block.add([
        0x1D, 0x76, 0x30, 0x00,
        bytesPerRow & 0xFF,
        (bytesPerRow >> 8) & 0xFF,
        yL,
        yH,
      ]);

      final start = y * bytesPerRow;
      final end = start + h * bytesPerRow;
      final slice = bmp.bytes.sublist(start, end);

      if (invert) {
        block.add(Uint8List.fromList(slice.map((b) => (~b) & 0xFF).toList()));
      } else {
        block.add(slice);
      }

      await ble.writeAll(block.toBytes(), chunk: chunk, delayMs: delayMs);
    }

    int remaining = feedDots;
    while (remaining > 0) {
      final n = remaining.clamp(1, 255);
      await ble.writeAll(
        Uint8List.fromList([0x1B, 0x4A, n]),
        chunk: chunk,
        delayMs: delayMs,
      );
      remaining -= n;
    }

    await ble.writeAll(Uint8List.fromList([0x0A]), chunk: chunk, delayMs: delayMs);
  }

  static final _numFormatter = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d*)?$')),
    LengthLimitingTextInputFormatter(12),
  ];

  Widget _numField(
      TextEditingController c,
      String label, {
        double w = 160,
        FocusNode? focusNode,
        PreviewSection? selectOnTap,
      }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selectOnTap != null) setState(() => _selectedSection = selectOnTap);
        focusNode?.requestFocus();
      },
      child: CustomTextField(
        controller: c,
        focusNode: focusNode,
        labelText: label,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
        inputFormatters: _numFormatter,
        width: w,
        height: 44,
        fillCollor: Colors.white,
        outlined: true,
        borderRadius: 10,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }

  Widget _txtField(
      TextEditingController c,
      String label, {
        FocusNode? focusNode,
        PreviewSection? selectOnTap,
      }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (selectOnTap != null) setState(() => _selectedSection = selectOnTap);
        focusNode?.requestFocus();
      },
      child: CustomTextField(
        controller: c,
        focusNode: focusNode,
        labelText: label,
        keyboardType: TextInputType.text,
        width: double.infinity,
        height: 48,
        fillCollor: Colors.white,
        outlined: true,
        borderRadius: 10,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  void _handlePreviewTap(PreviewSection section) {
    setState(() => _selectedSection = section);

    switch (section) {
      case PreviewSection.widthRuler:
        _wFocus.requestFocus();
        break;
      case PreviewSection.heightRuler:
        _hFocus.requestFocus();
        break;
      case PreviewSection.gap:
        _gapFocus.requestFocus();
        break;
      case PreviewSection.padding:
        _padFocus.requestFocus();
        break;
      case PreviewSection.qr:
        _qrFocus.requestFocus();
        break;
      case PreviewSection.text:
        _textFocus.requestFocus();
        break;
      case PreviewSection.label:
      case PreviewSection.cycle:
      case PreviewSection.none:
        FocusManager.instance.primaryFocus?.unfocus();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _ble.isConnected;

    final w = MediaQuery.sizeOf(context).width;
    final isNarrow = w < 980;

    final cfg = LabelLayoutConfig(
      padMm: _padMm,
      qrSidePctOfShort: 1.0,
      textMaxLines: 3,
      spaceBetweenMm: 0.6,
      matchPreviewTextSizing: true,
      previewFontMinPx: 12,
      previewFontMaxPx: 16,
      textScale: _textScale, // ✅ vindo do tamanho 8/9/10/11
    );

    final controls = ListView(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _busy ? null : _connect,
              icon: const Icon(Icons.bluetooth),
              label: Text(_busy ? 'Aguarde...' : 'Conectar'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _disconnect,
              icon: const Icon(Icons.link_off),
              label: const Text('Desconectar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Etiqueta (mm)', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _numField(_wCtrl, 'Largura mm', w: 160, focusNode: _wFocus, selectOnTap: PreviewSection.widthRuler),
            _numField(_hCtrl, 'Altura mm', w: 160, focusNode: _hFocus, selectOnTap: PreviewSection.heightRuler),
            _numField(_gapCtrl, 'GAP mm', w: 140, focusNode: _gapFocus, selectOnTap: PreviewSection.gap),
            _numField(_padCtrl, 'Padding mm', w: 150, focusNode: _padFocus, selectOnTap: PreviewSection.padding),
          ],
        ),

        const SizedBox(height: 12),

        // ✅ TEXTO + TAMANHO NA MESMA LINHA
        Row(
          children: [
            Expanded(
              child: _txtField(_textCtrl, 'Texto', focusNode: _textFocus, selectOnTap: PreviewSection.text),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: _numField(
                _textSizeCtrl,
                'Tam.',
                w: 120,
                focusNode: _textSizeFocus,
                selectOnTap: PreviewSection.text,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
        _txtField(_qrCtrl, 'QR Data', focusNode: _qrFocus, selectOnTap: PreviewSection.qr),

        const SizedBox(height: 16),
        const Divider(),
        const Text('Impressão', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: (!_busy && connected) ? _printEscPosFromCanvas : null,
              icon: const Icon(Icons.print),
              label: const Text('Imprimir'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Texto: tamanho ${_textSizeUi.toStringAsFixed(0)} (base 10).\n'
              '• 10 = padrão\n'
              '• 12 = maior\n'
              '• 8 = menor\n',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
      ],
    );

    final preview = PreviewPanel(
      larguraMm: _wMm,
      alturaMm: _hMm,
      gapMm: _gapMm,
      text: _textCtrl.text,
      qrData: _qrCtrl.text,
      cfg: cfg,
      selectedSection: _selectedSection,
      onSectionTap: _handlePreviewTap,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isNarrow
            ? Column(
          children: [
            Expanded(child: controls),
            const SizedBox(height: 12),
            SizedBox(height: 360, child: preview),
          ],
        )
            : Row(
          children: [
            Expanded(flex: 3, child: controls),
            const SizedBox(width: 16),
            Expanded(flex: 3, child: preview),
          ],
        ),
      ),
    );
  }
}