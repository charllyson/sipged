import 'package:flutter/material.dart';
import 'package:sisged/_widgets/archives/pdf/pdf_preview_stub.dart';

import '../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import '../../../_blocs/documents/contracts/contracts/contracts_bloc.dart';
import '../../../_blocs/documents/contracts/validity/validity_bloc.dart';
import '../../../_blocs/documents/measurement/measurement_bloc.dart';
import '../../../_blocs/sectors/financial/payments/payments_adjustment_bloc.dart';
import '../../../_blocs/sectors/financial/payments/payments_reports_bloc.dart';
import '../../../_blocs/sectors/financial/payments/payments_revision_bloc.dart';
import '../../../_datas/documents/contracts/additive/additive_data.dart';
import '../../../_datas/documents/contracts/apostilles/apostilles_data.dart';
import '../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../_datas/documents/contracts/validity/validity_data.dart';
import '../../../_datas/documents/measurement/measurement_data.dart';
import '../../../_datas/sectors/financial/payments/payments_adjustments_data.dart';
import '../../../_datas/sectors/financial/payments/payments_reports_data.dart';
import '../../../_datas/sectors/financial/payments/payments_revisions_data.dart';
enum PDFType {
  contract,
  additives,
  apostilles,
  report,
  validity,
  paymentReport,
  paymentsAdjustment,
  paymentsRevision,
}

class PdfFileIconActionGeneric<T> extends StatefulWidget {
  final PDFType type;
  final ContractsBloc? contractBloc;
  final AdditivesBloc? additivesBloc;
  final ApostillesBloc? apostillesBloc;
  final ReportsBloc? reportsBloc;
  final PaymentsReportBloc? paymentsBloc;
  final PaymentsAdjustmentBloc? paymentsAdjustmentBloc;
  final PaymentsRevisionBloc? paymentsRevisionBloc;
  final ValidityBloc? validityBloc;
  final ContractData contractData;
  final T? specificData;
  final String? documentId;
  final Future<void> Function(String url)? onUploadSaveToFirestore;

  const PdfFileIconActionGeneric({
    super.key,
    required this.type,
    required this.contractData,
    this.documentId,
    this.specificData,
    this.contractBloc,
    this.additivesBloc,
    this.apostillesBloc,
    this.reportsBloc,
    this.validityBloc,
    this.onUploadSaveToFirestore,
    this.paymentsBloc,
    this.paymentsAdjustmentBloc,
    this.paymentsRevisionBloc,
  });

  @override
  State<PdfFileIconActionGeneric<T>> createState() => _PdfFileIconActionGenericState<T>();
}

class _PdfFileIconActionGenericState<T> extends State<PdfFileIconActionGeneric<T>> {
  bool _pdfExists = false;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkPdfExists();
  }

  @override
  void didUpdateWidget(covariant PdfFileIconActionGeneric<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.documentId != oldWidget.documentId) {
      _checkPdfExists();
    }
  }

  Future<void> _checkPdfExists() async {
    final exists = switch (widget.type) {
      PDFType.contract => await widget.contractBloc?.verificarSePdfExiste(widget.contractData),
      PDFType.additives => await widget.additivesBloc?.verificarSePdfDeAditivoExiste(
        contract: widget.contractData,
        additive: widget.specificData as AdditiveData,
      ),
      PDFType.apostilles => await widget.apostillesBloc?.verificarSePdfDeApostilaExiste(
        contract: widget.contractData,
        apostille: widget.specificData as ApostillesData,
      ),
      PDFType.report => await widget.reportsBloc?.verificarSePdfDeMedicaoExiste(
        contract: widget.contractData,
        measurement: widget.specificData as ReportData,
      ),
      PDFType.validity => await widget.validityBloc?.verificarSePdfDeValidadeExiste(
        contract: widget.contractData,
        validade: widget.specificData as ValidityData,
      ),
      PDFType.paymentReport => await widget.paymentsBloc?.verificarSePdfDePaymentExiste(
        contract: widget.contractData,
        payment: widget.specificData as PaymentsReportData,
      ),
      PDFType.paymentsAdjustment => await widget.paymentsAdjustmentBloc?.verificarSePdfDePaymentExiste(
        contract: widget.contractData,
        paymentsAdjustmentsData: widget.specificData as PaymentsAdjustmentsData,
      ),
      PDFType.paymentsRevision => await widget.paymentsRevisionBloc?.verificarSePdfDePaymentExiste(
        contract: widget.contractData,
        paymentsRevisionsData: widget.specificData as PaymentsRevisionsData,
      ),
    };
    if (mounted) setState(() => _pdfExists = exists ?? false);
  }

  Future<void> _handleTap() async {
    if (_pdfExists) {
      try {
        final url = switch (widget.type) {
          PDFType.contract => await widget.contractBloc?.getFirstContractPdfUrl(widget.contractData),
          PDFType.additives => await widget.additivesBloc?.getPdfUrlDoAditivo(
            contract: widget.contractData,
            additive: widget.specificData as AdditiveData,
          ),
          PDFType.apostilles => await widget.apostillesBloc?.getPdfUrlDaApostila(
            contract: widget.contractData,
            apostille: widget.specificData as ApostillesData,
          ),
          PDFType.report => await widget.reportsBloc?.getPdfUrlDaMedicao(
            contract: widget.contractData,
            measurement: widget.specificData as ReportData,
          ),
          PDFType.validity => await widget.validityBloc?.getPdfUrlDaValidade(
            contract: widget.contractData,
            validade: widget.specificData as ValidityData,
          ),
          PDFType.paymentReport => await widget.paymentsBloc?.getPdfUrlDaPayment(
            contract: widget.contractData,
            payment: widget.specificData as PaymentsReportData,
          ),
          PDFType.paymentsAdjustment => await widget.paymentsAdjustmentBloc?.getPdfUrlDaPayment(
            contract: widget.contractData,
            paymentsAdjustmentsData: widget.specificData as PaymentsAdjustmentsData,
          ),
          PDFType.paymentsRevision => await widget.paymentsRevisionBloc?.getPdfUrlDaPayment(
            contract: widget.contractData,
            paymentsRevisionsData: widget.specificData as PaymentsRevisionsData,
          ),
        };

        if (url != null) {
          showDialog(
            context: context,
            builder: (_) => Dialog(child: PdfPreviewWeb(pdfUrl: url)),
          );
        } else {
          _showSnackBar('PDF não encontrado', isError: true);
        }
      } catch (e) {
        _showSnackBar('Erro ao abrir PDF: $e', isError: true);
      }
    } else {
      await _enviarNovoPdf();
    }
  }

  Future<void> _enviarNovoPdf() async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      switch (widget.type) {
        case PDFType.contract:
          await widget.contractBloc?.sendContractPdfWeb(
            contract: widget.contractData,
            onProgress: (p) => setState(() => _uploadProgress = p),
          );
          await _checkPdfExists();
          _showSnackBar('PDF enviado com sucesso');
          break;

        case PDFType.additives:
          await widget.additivesBloc?.selecionarEPDFDeAditivoComProgresso(
            contractId: widget.contractData.id!,
            additiveData: widget.specificData as AdditiveData,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: _handleUploadComplete,
          );
          break;

        case PDFType.apostilles:
          await widget.apostillesBloc?.selecionarEPdfDeApostilaComProgresso(
            contractId: widget.contractData.id!,
            apostilleData: widget.specificData as ApostillesData,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: _handleUploadComplete,
          );
          break;

        case PDFType.report:
          await widget.reportsBloc?.selecionarEPdfDeMedicaoComProgresso(
            contractId: widget.contractData.id!,
            measurementData: widget.specificData as ReportData,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: _handleUploadComplete,
          );
          break;

        case PDFType.validity:
          await widget.validityBloc?.selecionarEPdfDeValidadeComProgresso(
            contractId: widget.contractData.id!,
            validadeData: widget.specificData as ValidityData,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: _handleUploadComplete,
          );
          break;
        case PDFType.paymentReport:
          await widget.paymentsBloc?.selecionarEPdfDePaymentComProgresso(
            contractId: widget.contractData.id!,
            paymentData: widget.specificData as PaymentsReportData,
            onProgress: (p) => setState(() => _uploadProgress = p),
            onComplete: _handleUploadComplete,
          );
          break;
          case PDFType.paymentsAdjustment:
            await widget.paymentsAdjustmentBloc?.selecionarEPdfDePaymentComProgresso(
              contractId: widget.contractData.id!,
              paymentsAdjustmentsData: widget.specificData as PaymentsAdjustmentsData,
              onProgress: (p) => setState(() => _uploadProgress = p),
              onComplete: _handleUploadComplete,
            );
            break;
            case PDFType.paymentsRevision:
              await widget.paymentsRevisionBloc?.selecionarEPdfDePaymentComProgresso(
                contractId: widget.contractData.id!,
                paymentsRevisionsData: widget.specificData as PaymentsRevisionsData,
                onProgress: (p) => setState(() => _uploadProgress = p),
                onComplete: _handleUploadComplete,
              );
              break;
      }
    } catch (e) {
      _showSnackBar('Erro ao enviar PDF: $e', isError: true);
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  void _handleUploadComplete(bool success) async {
    if (success) {
      await _checkPdfExists();
      _showSnackBar('PDF enviado com sucesso');
    } else {
      _showSnackBar('Envio cancelado ou falhou.', isError: true);
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

    bool? success;

    switch (widget.type) {
      case PDFType.contract:
        success = await widget.contractBloc?.deleteContractPdf(widget.contractData);
        break;
      case PDFType.additives:
        success = await widget.additivesBloc?.deletarPdfDoAditivo(
          contractId: widget.contractData.id!,
          additiveData: widget.specificData as AdditiveData,
        );
        break;
      case PDFType.apostilles:
        success = await widget.apostillesBloc?.deletarPdfDaApostila(
          contractId: widget.contractData.id!,
          apostilleData: widget.specificData as ApostillesData,
        );
        break;
      case PDFType.report:
        success = await widget.reportsBloc?.deletarPdfDaMedicao(
          contractId: widget.contractData.id!,
          measurement: widget.specificData as ReportData,
        );
        break;
      case PDFType.validity:
        success = await widget.validityBloc?.deletarPdfDaValidade(
          contractId: widget.contractData.id!,
          validade: widget.specificData as ValidityData,
        );
        break;
      case PDFType.paymentReport:
        success = await widget.paymentsBloc?.deletarPdfDePayment(
          contractId: widget.contractData.id!,
          paymentData: widget.specificData as PaymentsReportData,
        );
        break;
        case PDFType.paymentsAdjustment:
          success = await widget.paymentsAdjustmentBloc?.deletarPdfDePayment(
            contractId: widget.contractData.id!,
            paymentsAdjustmentsData: widget.specificData as PaymentsAdjustmentsData,
          );
          break;
          case PDFType.paymentsRevision:
            success = await widget.paymentsRevisionBloc?.deletarPdfDePayment(
              contractId: widget.contractData.id!,
              paymentsRevisionsData: widget.specificData as PaymentsRevisionsData,
            );
            break;
    }

    if (success == true) {
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

    return Center(
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
                  ),
                ),
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
