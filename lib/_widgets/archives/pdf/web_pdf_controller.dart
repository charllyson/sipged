import 'package:flutter/material.dart';

// STORAGE BLOCS
import 'package:siged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/additives/additives_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_storage_bloc.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_storage_bloc.dart';

// DATAS
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_data.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_data.dart';
import 'package:siged/_blocs/documents/contracts/validity/validity_data.dart';
import 'package:siged/_blocs/documents/measurement/report/report_measurement_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payments_adjustments_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_reports_data.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payments_revisions_data.dart';

// troque o import do stub por este:
import 'package:siged/_widgets/archives/pdf/pdf_preview.dart';

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

/// Controller genérico para PDFs.
/// - Centraliza regras por tipo de PDF (contract, additive, etc.)
/// - Exposição de estado (isUploading, progress, pdfExists)
/// - Ações: checkExists, open, send, delete, handleTap
class WebPdfControllerGeneric<T> extends ChangeNotifier {
  WebPdfControllerGeneric({
    required PDFType type,
    required ContractData contract,
    T? specificData,
    String? documentId,
    // storage blocs (opcionais; injete só os que usar nessa tela)
    ContractStorageBloc? contractStorageBloc,
    AdditivesStorageBloc? additivesStorageBloc,
    ApostillesStorageBloc? apostillesStorageBloc,
    ReportMeasurementStorageBloc? reportsStorageBloc,
    ValidityStorageBloc? validityStorageBloc,
    PaymentsReportStorageBloc? paymentsReportStorageBloc,
    PaymentAdjustmentStorageBloc? paymentsAdjustmentStorageBloc,
    PaymentRevisionStorageBloc? paymentsRevisionStorageBloc,
    // callback opcional para salvar URL no Firestore após upload
    Future<void> Function(String url)? onUploadSaveToFirestore,
  })  : _type = type,
        _contract = contract,
        _specific = specificData,
        _documentId = documentId,
        _contractStorageBloc = contractStorageBloc,
        _additivesStorageBloc = additivesStorageBloc,
        _apostillesStorageBloc = apostillesStorageBloc,
        _reportsStorageBloc = reportsStorageBloc,
        _validityStorageBloc = validityStorageBloc,
        _paymentsReportStorageBloc = paymentsReportStorageBloc,
        _paymentsAdjustmentStorageBloc = paymentsAdjustmentStorageBloc,
        _paymentsRevisionStorageBloc = paymentsRevisionStorageBloc,
        _onUploadSaveToFirestore = onUploadSaveToFirestore;

  // ---- Dependências / contexto ----
  final PDFType _type;
  ContractData _contract;
  T? _specific;
  String? _documentId;

  final ContractStorageBloc? _contractStorageBloc;
  final AdditivesStorageBloc? _additivesStorageBloc;
  final ApostillesStorageBloc? _apostillesStorageBloc;
  final ReportMeasurementStorageBloc? _reportsStorageBloc;
  final ValidityStorageBloc? _validityStorageBloc;
  final PaymentsReportStorageBloc? _paymentsReportStorageBloc;
  final PaymentAdjustmentStorageBloc? _paymentsAdjustmentStorageBloc;
  final PaymentRevisionStorageBloc? _paymentsRevisionStorageBloc;

  final Future<void> Function(String url)? _onUploadSaveToFirestore;

  // ---- Estado público (view consome) ----
  bool _pdfExists = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  bool get pdfExists => _pdfExists;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;

  PDFType get type => _type;
  ContractData get contract => _contract;
  T? get specificData => _specific;
  String? get documentId => _documentId;

  // ---- Mutadores de contexto (caso tenha troca de item selecionado) ----
  void updateContext({
    ContractData? contract,
    T? specificData,
    String? documentId,
  }) {
    bool changed = false;
    if (contract != null && !identical(contract, _contract)) {
      _contract = contract;
      changed = true;
    }
    if (documentId != _documentId) {
      _documentId = documentId;
      changed = true;
    }
    if (!identical(specificData, _specific)) {
      _specific = specificData;
      changed = true;
    }
    if (changed) {
      checkExists(); // atualiza existência ao trocar contexto
      notifyListeners();
    }
  }

  // ---- Helpers internos ----
  Never _assertSpecificRequired(String label) {
    throw FlutterError(
      '[$label] requer "specificData" para operar nesse PDFType ($_type). '
          'Certifique-se de passar o objeto correto no controller.',
    );
  }

  S _as<S>() {
    final data = _specific;
    if (data is! S) _assertSpecificRequired(S.toString());
    return data as S;
  }

  void _setUploading(bool v) {
    _isUploading = v;
    notifyListeners();
  }

  void _setProgress(double p) {
    _uploadProgress = p;
    notifyListeners();
  }

  void _setExists(bool v) {
    _pdfExists = v;
    notifyListeners();
  }

  // ---- API pública ----

  /// Verifica se há PDF armazenado para o contexto atual.
  Future<void> checkExists() async {
    try {
      final exists = switch (_type) {
        PDFType.contract =>
        await _contractStorageBloc?.verificarSePdfExiste(_contract),
        PDFType.additives =>
        await _additivesStorageBloc?.verificarSePdfDeAditivoExiste(
          contract: _contract,
          additive: _as<AdditiveData>(),
        ),
        PDFType.apostilles =>
        await _apostillesStorageBloc?.verificarSePdfDeApostilaExiste(
          contract: _contract,
          apostille: _as<ApostillesData>(),
        ),
        PDFType.report =>
        await _reportsStorageBloc?.verificarSePdfDeMedicaoExiste(
          contract: _contract,
          measurement: _as<ReportMeasurementData>(),
        ),
        PDFType.validity =>
        await _validityStorageBloc?.verificarSePdfDeValidadeExiste(
          contract: _contract,
          validade: _as<ValidityData>(),
        ),
        PDFType.paymentReport =>
        await _paymentsReportStorageBloc?.verificarSePdfDePaymentExiste(
          contract: _contract,
          payment: _as<PaymentsReportData>(),
        ),
        PDFType.paymentsAdjustment =>
        await _paymentsAdjustmentStorageBloc?.verificarSePdfDePaymentExiste(
          contract: _contract,
          paymentsAdjustmentsData: _as<PaymentsAdjustmentsData>(),
        ),
        PDFType.paymentsRevision =>
        await _paymentsRevisionStorageBloc?.verificarSePdfDePaymentExiste(
          contract: _contract,
          paymentsRevisionsData: _as<PaymentsRevisionsData>(),
        ),
      };
      _setExists(exists ?? false);
    } catch (_) {
      _setExists(false);
    }
  }

  /// Abre o PDF (se existir) em um Dialog com o Web viewer.
  Future<void> openPdf(BuildContext context) async {
    if (!_pdfExists) return;
    String? url;

    try {
      url = switch (_type) {
        PDFType.contract => await _contractStorageBloc?.getFirstContractPdfUrl(_contract),
        PDFType.additives => await _additivesStorageBloc?.getPdfUrlDoAditivo(
            contract: _contract, additive: _as<AdditiveData>()),
        PDFType.apostilles => await _apostillesStorageBloc?.getPdfUrlDaApostila(
            contract: _contract, apostille: _as<ApostillesData>()),
        PDFType.report => await _reportsStorageBloc?.getPdfUrlDaMedicao(
            contract: _contract, measurement: _as<ReportMeasurementData>()),
        PDFType.validity => await _validityStorageBloc?.getPdfUrlDaValidade(
            contract: _contract, validade: _as<ValidityData>()),
        PDFType.paymentReport => await _paymentsReportStorageBloc?.getPdfUrlDaPayment(
            contract: _contract, payment: _as<PaymentsReportData>()),
        PDFType.paymentsAdjustment => await _paymentsAdjustmentStorageBloc?.getPdfUrlDaPayment(
            contract: _contract, paymentsAdjustmentsData: _as<PaymentsAdjustmentsData>()),
        PDFType.paymentsRevision => await _paymentsRevisionStorageBloc?.getPdfUrlDaPayment(
            contract: _contract, paymentsRevisionsData: _as<PaymentsRevisionsData>()),
      };
    } catch (e) {
      _showSnackBar(context, 'Erro ao obter URL: $e', isError: true);
      return;
    }

    if (url == null) {
      _showSnackBar(context, 'PDF não encontrado', isError: true);
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: PdfPreview(pdfUrl: url!), // ver seção 3 para o !
      ),
    );
  }

  /// Envia novo PDF (abre seletor, faz upload, chama callback para salvar URL).
  Future<void> sendPdf(BuildContext context) async {
    _setUploading(true);
    _setProgress(0);

    try {
      switch (_type) {
        case PDFType.contract:
          await _contractStorageBloc?.sendPdf(
            contract: _contract,
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;

        case PDFType.validity:
          await _validityStorageBloc?.sendPdf(
            contract: _contract,
            validade: _as<ValidityData>(),
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;

        case PDFType.additives:
          await _additivesStorageBloc?.sendPdf(
            contract: _contract,
            additive: _as<AdditiveData>(),
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;

        case PDFType.apostilles:
          await _apostillesStorageBloc?.sendPdf(
            contract: _contract,
            apostille: _as<ApostillesData>(),
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;

        case PDFType.report:
          await _reportsStorageBloc?.sendPdf(
            contract: _contract,
            measurement: _as<ReportMeasurementData>(),
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;

        case PDFType.paymentReport:
          await _paymentsReportStorageBloc?.sendPdf(
            contract: _contract,
            paymentReport: _as<PaymentsReportData>(),
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;

        case PDFType.paymentsAdjustment:
          await _paymentsAdjustmentStorageBloc?.sendPdf(
            contract: _contract,
            paymentsAdjustment: _as<PaymentsAdjustmentsData>(),
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;

        case PDFType.paymentsRevision:
          await _paymentsRevisionStorageBloc?.sendPdf(
            contract: _contract,
            payment: _as<PaymentsRevisionsData>(),
            onProgress: _setProgress,
            onUploaded: _onUploadSaveToFirestore,
          );
          break;
      }

      await checkExists();
      _showSnackBar(context, 'PDF enviado com sucesso');
    } catch (e) {
      _showSnackBar(context, 'Erro ao enviar PDF: $e', isError: true);
    } finally {
      _setUploading(false);
      _setProgress(0);
    }
  }

  /// Exclui o PDF do contexto atual.
  Future<void> deletePdf(BuildContext context) async {
    bool? success;
    try {
      switch (_type) {
        case PDFType.contract:
          success = await _contractStorageBloc?.deletePdf(_contract);
          break;
        case PDFType.additives:
          success = await _additivesStorageBloc?.delete(
            _contract, _as<AdditiveData>(),
          );
          break;
        case PDFType.apostilles:
          success = await _apostillesStorageBloc?.delete(
            _contract, _as<ApostillesData>(),
          );
          break;
        case PDFType.report:
          success = await _reportsStorageBloc?.delete(
            _contract, _as<ReportMeasurementData>(),
          );
          break;
        case PDFType.validity:
          success = await _validityStorageBloc?.delete(
            _contract, _as<ValidityData>(),
          );
          break;
        case PDFType.paymentReport:
          success = await _paymentsReportStorageBloc?.delete(
            _contract, _as<PaymentsReportData>(),
          );
          break;
        case PDFType.paymentsAdjustment:
          success = await _paymentsAdjustmentStorageBloc?.delete(
            _contract, _as<PaymentsAdjustmentsData>(),
          );
          break;
        case PDFType.paymentsRevision:
          success = await _paymentsRevisionStorageBloc?.delete(
            _contract, _as<PaymentsRevisionsData>(),
          );
          break;
      }
    } catch (e) {
      _showSnackBar(context, 'Erro ao excluir: $e', isError: true);
      return;
    }

    if (success == true) {
      await checkExists();
      _showSnackBar(context, 'PDF excluído com sucesso');
    } else {
      _showSnackBar(context, 'Erro ao excluir PDF', isError: true);
    }
  }

  /// Comportamento padrão do clique no ícone:
  /// - Se existir, abre; senão, inicia upload.
  Future<void> handleTap(BuildContext context) async {
    if (_pdfExists) {
      await openPdf(context);
    } else {
      await sendPdf(context);
    }
  }

  // ---- UI helpers ----
  void _showSnackBar(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
