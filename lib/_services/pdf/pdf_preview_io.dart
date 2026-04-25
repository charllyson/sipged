// lib/_widgets/files/pdf/pdf_preview_io.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

class PdfPreview extends StatefulWidget {
  final String pdfUrl;                 // <- mantém sua assinatura atual
  final double borderRadius;

  const PdfPreview({
    super.key,
    required this.pdfUrl,
    this.borderRadius = 16,
  });

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

enum _Mode { loading, pdfx, syncfusion, error }

class _PdfPreviewState extends State<PdfPreview> {
  PdfControllerPinch? _pdfx;
  DownloadTask? _downloadTask;
  double _progress = 0;
  _Mode _mode = _Mode.loading;
  String? _err;
  Uint8List? _fallbackBytes;
  File? _tempFile;

  @override
  void initState() {
    super.initState();
    _open();
  }

  bool get _isFirebaseHttp =>
      widget.pdfUrl.startsWith('https://firebasestorage.googleapis.com');
  bool get _isGs => widget.pdfUrl.startsWith('gs://');

  Future<void> _open() async {
    try {
      // 1) Se for URL do Firebase (gs:// ou https firebase), baixa via SDK (privado)
      if (_isGs || _isFirebaseHttp) {
        final ref = FirebaseStorage.instance.refFromURL(widget.pdfUrl);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/preview_${ref.name}_${DateTime.now().microsecondsSinceEpoch}.pdf');

        final task = ref.writeToFile(file); // DownloadTask
        setState(() {
          _downloadTask = task;
          _mode = _Mode.loading;
          _tempFile = file;
        });

        task.snapshotEvents.listen((s) {
          final t = s.totalBytes;
          if (t > 0) {
            setState(() => _progress = (s.bytesTransferred / t) * 100);
          }
        });

        await task;

        // tenta pdfx
        try {
          setState(() {
            _pdfx = PdfControllerPinch(
              document: PdfDocument.openFile(
                  file.path), // Future<PdfDocument>
            );
            _mode = _Mode.pdfx;
          });
        } on Exception catch (e) {
          // fallback: Syncfusion com bytes
          final bytes = await file.readAsBytes();
          setState(() {
            _fallbackBytes = bytes;
            _err = e.toString();
            _mode = _Mode.syncfusion;
          });
        }
        return;
      }

      // 2) Caso geral: faça download HTTP e abra via bytes
      final resp = await http.get(Uri.parse(widget.pdfUrl));
      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}';
      }

      // primeiro tenta pdfx
      try {
        setState(() {
          _pdfx = PdfControllerPinch(
            document: PdfDocument.openData(resp.bodyBytes),
          );
          _mode = _Mode.pdfx;
        });
      } on Exception catch (e) {
        setState(() {
          _fallbackBytes = resp.bodyBytes;
          _err = e.toString();
          _mode = _Mode.syncfusion;
        });
      }
    } catch (e) {
      setState(() {
        _err = e.toString();
        _mode = _Mode.error;
      });
    }
  }

  @override
  void dispose() {
    _downloadTask?.cancel();
    _pdfx?.dispose();
    try {
      _tempFile?.deleteSync();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _Mode.loading:
        return _rounded(
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Carregando PDF... ${_progress.toStringAsFixed(0)}%'),
            ),
          ),
        );
      case _Mode.pdfx:
        return _rounded(PdfViewPinch(
          backgroundDecoration: BoxDecoration(
            color: Colors.white
          ),
            controller: _pdfx!));
      case _Mode.syncfusion:
        return _rounded(
          _fallbackBytes == null
              ? const Center(child: Text('Falha no viewer principal.'))
              : SfPdfViewer.memory(_fallbackBytes!),
        );
      case _Mode.error:
        return _rounded(
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text('Erro ao abrir PDF:\n$_err')),
          ),
        );
    }
  }

  Widget _rounded(Widget child) => ClipRRect(
    borderRadius: BorderRadius.circular(widget.borderRadius),
    child: child,
  );
}
