import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Interface mínima para o Storage
abstract class PdfStoragePort {
  Future<String?> getDownloadUrl(String storagePath);
  Future<String> uploadBytes(String storagePath, Uint8List bytes);
  Future<void> delete(String storagePath);
}

/// Implementação padrão usando Firebase Storage diretamente.
/// Se quiser garantir o bucket correto, passe `FirebaseStorage.instanceFor(bucket: 'gs://SEU_BUCKET.appspot.com')`
class FirebasePdfStoragePort implements PdfStoragePort {
  final FirebaseStorage storage;
  FirebasePdfStoragePort({FirebaseStorage? storage})
      : storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String?> getDownloadUrl(String storagePath) async {
    try {
      return await storage.ref(storagePath).getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') return null;
      rethrow;
    }
  }

  @override
  Future<String> uploadBytes(String storagePath, Uint8List bytes) async {
    final ref = storage.ref(storagePath);

    // Logs úteis (remova em prod se quiser)
    // ignore: avoid_print
    print('[Storage] bucket=${storage.app.options.storageBucket} path=${ref.fullPath}');
    // ignore: avoid_print
    print('[Auth] uid=${FirebaseAuth.instance.currentUser?.uid ?? 'NULL'}');

    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    return await task.ref.getDownloadURL();
  }

  @override
  Future<void> delete(String storagePath) async {
    await storage.ref(storagePath).delete();
  }
}

/// Controla o estado do PDF standalone.
class WebPdfStandaloneController extends ChangeNotifier {
  WebPdfStandaloneController({
    required this.storagePort,
    this.storagePath, // use storagePath OU pdfUrl
    this.pdfUrl,
  }) : assert(storagePath != null || pdfUrl != null, 'Forneça storagePath OU pdfUrl');

  final PdfStoragePort storagePort;
  String? storagePath;
  String? pdfUrl;

  bool _exists = false;
  bool get pdfExists => _exists;

  bool _uploading = false;
  bool get isUploading => _uploading;
  double? _progress;
  double? get uploadProgress => _progress;

  Future<void> checkExists() async {
    if (storagePath == null) {
      _exists = pdfUrl != null;
      notifyListeners();
      return;
    }
    final url = await storagePort.getDownloadUrl(storagePath!);
    _exists = url != null;
    pdfUrl = url;
    notifyListeners();
  }

  void update({String? storagePath, String? pdfUrl}) {
    if (storagePath != null) this.storagePath = storagePath;
    if (pdfUrl != null) this.pdfUrl = pdfUrl;
    checkExists();
  }

  Future<void> upload(BuildContext context, Future<Uint8List?> pickBytes()) async {
    if (storagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Defina um storagePath para permitir upload.')),
      );
      return;
    }

    // ✅ Garante Auth antes de tentar gravar (regras com request.auth != null)
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login antes de anexar o PDF.')),
      );
      return;
    }

    final bytes = await pickBytes();
    if (bytes == null || bytes.isEmpty) return;

    _uploading = true;
    _progress = null;
    notifyListeners();

    try {
      final url = await storagePort.uploadBytes(storagePath!, bytes);
      pdfUrl = url;
      _exists = true;
    } catch (e) {
      String msg = 'Falha no upload';
      if (e is FirebaseException) {
        msg = 'Upload falhou [${e.code}] ${e.message ?? ''}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      _uploading = false;
      _progress = null;
      notifyListeners();
    }
  }

  Future<void> deletePdf(BuildContext context) async {
    if (storagePath == null) return;

    // Requer Auth também
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faça login antes de excluir o PDF.')),
      );
      return;
    }

    try {
      await storagePort.delete(storagePath!);
      _exists = false;
      pdfUrl = null;
      notifyListeners();
    } catch (e) {
      String msg = 'Falha ao excluir';
      if (e is FirebaseException) {
        msg = 'Exclusão falhou [${e.code}] ${e.message ?? ''}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }
}

/// Widget “ícone de PDF” standalone (abre, envia, remove).
class WebPdfWidgetStandalone extends StatefulWidget {
  const WebPdfWidgetStandalone({
    super.key,
    required this.controller,
    this.label,
    this.onOpen,      // abre no seu viewer
    this.onPickBytes, // devolve bytes do arquivo escolhido
  });

  final WebPdfStandaloneController controller;
  final String? label;
  final Future<void> Function(String pdfUrl)? onOpen;
  final Future<Uint8List?> Function()? onPickBytes;

  @override
  State<WebPdfWidgetStandalone> createState() => _WebPdfWidgetStandaloneState();
}

class _WebPdfWidgetStandaloneState extends State<WebPdfWidgetStandalone> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.checkExists();
  }

  @override
  void didUpdateWidget(covariant WebPdfWidgetStandalone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final iconPath = c.pdfExists
        ? 'assets/icons/pdf-file-format.png'
        : 'assets/icons/wait-to-up-file.png';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: c.pdfExists ? 'Ver PDF' : 'Enviar PDF',
          child: GestureDetector(
            onTap: () async {
              if (c.pdfExists && c.pdfUrl != null) {
                if (widget.onOpen != null) {
                  await widget.onOpen!(c.pdfUrl!);
                }
              } else {
                final pickBytes = widget.onPickBytes;
                if (pickBytes == null) return;
                await c.upload(context, pickBytes);
              }
            },
            child: Container(
              width: 100,
              height: 145,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Image.asset(iconPath, key: ValueKey(iconPath), width: 80, height: 70),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (c.pdfExists)
          ClipOval(
            child: Material(
              color: Colors.grey.shade200,
              child: IconButton(
                icon: const Icon(Icons.clear, size: 26, color: Colors.red),
                onPressed: () => c.deletePdf(context),
              ),
            ),
          ),
        if (c.isUploading)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 60,
              height: 4,
              child: LinearProgressIndicator(value: c.uploadProgress),
            ),
          ),
        if (widget.label != null) ...[
          const SizedBox(height: 6),
          Text(widget.label!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ],
    );
  }
}
