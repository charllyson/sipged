import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_class/archives/pdf/web_pdf_viewer.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';

enum TipoArquivoPDF { contrato, aditivo, apostila, medicao }

class PdfFileIconActionGeneric extends StatefulWidget {
  final TipoArquivoPDF tipo;
  final ContractsBloc bloc;
  final ContractData contrato;
  final dynamic dataEspecifica; // AdditiveData, ApostillesData ou MeasurementsData
  final Future<void> Function(String url)? onUploadSaveToFirestore;

  const PdfFileIconActionGeneric({
    super.key,
    required this.tipo,
    required this.bloc,
    required this.contrato,
    this.dataEspecifica,
    this.onUploadSaveToFirestore,
  });

  @override
  State<PdfFileIconActionGeneric> createState() => _PdfFileIconActionGenericState();
}

class _PdfFileIconActionGenericState extends State<PdfFileIconActionGeneric> {
  bool _pdfExists = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkPdfExists();
  }

  @override
  void didUpdateWidget(covariant PdfFileIconActionGeneric oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dataEspecifica?.id != oldWidget.dataEspecifica?.id) {
      _checkPdfExists();
    }
  }

  Future<void> _checkPdfExists() async {
    final exists = switch (widget.tipo) {
      TipoArquivoPDF.contrato => await widget.bloc.verificarSePdfExiste(widget.contrato),
      TipoArquivoPDF.aditivo => await widget.bloc.verificarSePdfDeAditivoExiste(
        contract: widget.contrato,
        additive: widget.dataEspecifica,
      ),
      TipoArquivoPDF.apostila => await widget.bloc.verificarSePdfDeApostilaExiste(
        contract: widget.contrato,
        apostille: widget.dataEspecifica,
      ),
      TipoArquivoPDF.medicao => await widget.bloc.verificarSePdfDeMedicaoExiste(
        contract: widget.contrato,
        measurement: widget.dataEspecifica,
      ),
    };
    if (mounted) setState(() => _pdfExists = exists);
  }

  Future<void> _handleTap() async {
    if (_pdfExists) {
      try {
        final String? url = switch (widget.tipo) {
          TipoArquivoPDF.contrato => await widget.bloc.getFirstPdfUrl(widget.contrato),
          TipoArquivoPDF.aditivo => await widget.bloc.getPdfUrlDoAditivo(
            contract: widget.contrato,
            additive: widget.dataEspecifica,
          ),
          TipoArquivoPDF.apostila => await widget.bloc.getPdfUrlDaApostila(
            contract: widget.contrato,
            apostille: widget.dataEspecifica,
          ),
          TipoArquivoPDF.medicao => await widget.bloc.getPdfUrlDaMedicao(
            contract: widget.contrato,
            measurement: widget.dataEspecifica,
          ),
        };

        if (url != null) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              child: SizedBox(
                child: PdfPreviewWeb(pdfUrl: url),
              ),
            ),
          );
        } else {
          _showSnackBar('PDF não encontrado', isError: true);
        }
      } catch (e) {
        _showSnackBar('Erro ao abrir PDF: $e', isError: true);
      }

      return;
    }

    await _enviarNovoPdf();
  }

  Future<void> _enviarNovoPdf() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      switch (widget.tipo) {
        case TipoArquivoPDF.contrato:
          await widget.bloc.enviarPdfWeb(
            contract: widget.contrato,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
          break;
        case TipoArquivoPDF.aditivo:
          await widget.bloc.selecionarEPDFDeAditivoComProgresso(
            contractId: widget.contrato.id!,
            additiveData: widget.dataEspecifica,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: (_) {},
          );
          break;
        case TipoArquivoPDF.apostila:
          await widget.bloc.selecionarEPdfDeApostilaComProgresso(
            contractId: widget.contrato.id!,
            apostilleData: widget.dataEspecifica,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: (_) {},
          );
          break;
        case TipoArquivoPDF.medicao:
          await widget.bloc.selecionarEPdfDeMedicaoComProgresso(
            contractId: widget.contrato.id!,
            measurementData: widget.dataEspecifica,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: (_) {},
          );
          break;
      }

      await _checkPdfExists();
      _showSnackBar('PDF enviado com sucesso');
    } catch (e) {
      _showSnackBar('Erro ao enviar PDF: $e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir PDF'),
        content: const Text('Tem certeza que deseja excluir este PDF?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar != true) return;

    bool success = false;
    switch (widget.tipo) {
      case TipoArquivoPDF.contrato:
        success = await widget.bloc.deletarPdf(widget.contrato);
        break;
      case TipoArquivoPDF.aditivo:
        success = await widget.bloc.deletarPdfDoAditivo(
          contractId: widget.contrato.id!,
          additiveData: widget.dataEspecifica,
        );
        break;
      case TipoArquivoPDF.apostila:
        success = await widget.bloc.deletarPdfDaApostila(
          contractId: widget.contrato.id!,
          apostilleData: widget.dataEspecifica,
        );
        break;
      case TipoArquivoPDF.medicao:
        success = await widget.bloc.deletarPdfDaMedicao(
          contractId: widget.contrato.id!,
          measurement: widget.dataEspecifica,
        );
        break;
    }

    if (success) {
      _showSnackBar('PDF excluído com sucesso');
      await _checkPdfExists();
    } else {
      _showSnackBar('Erro ao excluir PDF', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = _pdfExists
        ? 'assets/icons/pdf-file-format.png'
        : 'assets/icons/wait-to-up-file.png';

    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Container(
        width: 100,
        height: 145,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: _pdfExists ? 'Ver PDF' : 'Enviar PDF',
                child: GestureDetector(
                  onTap: _handleTap,
                  child: Image.asset(iconPath, width: 80, height: 70),
                ),
              ),
              const SizedBox(height: 8),
              if (_pdfExists)
                ClipOval(
                  child: Material(
                    color: Colors.grey.shade200,
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 26, color: Colors.red),
                    onPressed: _handleDelete,
                  ),
                )),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: 60,
                    height: 4,
                    child: LinearProgressIndicator(value: _uploadProgress),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
