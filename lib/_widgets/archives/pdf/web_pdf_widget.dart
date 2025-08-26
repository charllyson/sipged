import 'package:flutter/material.dart';
import 'package:sisged/_widgets/archives/pdf/web_pdf_controller.dart';

import 'package:sisged/_blocs/documents/contracts/additives/additives_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/apostilles/apostilles_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/validity/validity_storage_bloc.dart';
import 'package:sisged/_blocs/documents/measurement/report/report_measurement_storage_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_storage_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';
import 'package:sisged/_blocs/sectors/financial/payments/revision/payment_revision_storage_bloc.dart';
import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';

class WebPdfWidgetGeneric<T> extends StatefulWidget {
  const WebPdfWidgetGeneric({
    super.key,
    required this.type,
    required this.contractData,
    this.specificData,
    this.documentId,
    // injete só os blocs necessários para o tipo
    this.contractStorageBloc,
    this.additivesStorageBloc,
    this.apostillesStorageBloc,
    this.reportMeasurementStorageBloc,
    this.validityStorageBloc,
    this.paymentsReportStorageBloc,
    this.paymentsAdjustmentStorageBloc,
    this.paymentsRevisionStorageBloc,
    this.onUploadSaveToFirestore,
  });

  final PDFType type;
  final ContractData contractData;
  final T? specificData;
  final String? documentId;

  final ContractStorageBloc? contractStorageBloc;
  final AdditivesStorageBloc? additivesStorageBloc;
  final ApostillesStorageBloc? apostillesStorageBloc;
  final ReportMeasurementStorageBloc? reportMeasurementStorageBloc;
  final ValidityStorageBloc? validityStorageBloc;
  final PaymentsReportStorageBloc? paymentsReportStorageBloc;
  final PaymentAdjustmentStorageBloc? paymentsAdjustmentStorageBloc;
  final PaymentRevisionStorageBloc? paymentsRevisionStorageBloc;

  final Future<void> Function(String url)? onUploadSaveToFirestore;

  @override
  State<WebPdfWidgetGeneric<T>> createState() => _WebPdfWidgetGenericState<T>();
}

class _WebPdfWidgetGenericState<T> extends State<WebPdfWidgetGeneric<T>> {
  late final WebPdfControllerGeneric<T> controller;

  @override
  void initState() {
    super.initState();
    controller = WebPdfControllerGeneric<T>(
      type: widget.type,
      contract: widget.contractData,
      specificData: widget.specificData,
      documentId: widget.documentId,
      contractStorageBloc: widget.contractStorageBloc,
      additivesStorageBloc: widget.additivesStorageBloc,
      apostillesStorageBloc: widget.apostillesStorageBloc,
      reportsStorageBloc: widget.reportMeasurementStorageBloc,
      validityStorageBloc: widget.validityStorageBloc,
      paymentsReportStorageBloc: widget.paymentsReportStorageBloc,
      paymentsAdjustmentStorageBloc: widget.paymentsAdjustmentStorageBloc,
      paymentsRevisionStorageBloc: widget.paymentsRevisionStorageBloc,
      onUploadSaveToFirestore: widget.onUploadSaveToFirestore,
    );
    controller.checkExists();
  }

  @override
  void didUpdateWidget(covariant WebPdfWidgetGeneric<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.documentId != oldWidget.documentId ||
        widget.contractData != oldWidget.contractData ||
        widget.specificData != oldWidget.specificData) {
      controller.updateContext(
        contract: widget.contractData,
        specificData: widget.specificData,
        documentId: widget.documentId,
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final iconPath = controller.pdfExists
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
                    message: controller.pdfExists ? 'Ver PDF' : 'Enviar PDF',
                    child: GestureDetector(
                      onTap: () => controller.handleTap(context),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Image.asset(
                          iconPath,
                          key: ValueKey(iconPath), // força rebuild quando o path muda
                          width: 80,
                          height: 70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (controller.pdfExists)
                    ClipOval(
                      child: Material(
                        color: Colors.grey.shade200,
                        child: IconButton(
                          icon: const Icon(Icons.clear, size: 26, color: Colors.red),
                          onPressed: () => controller.deletePdf(context),
                        ),
                      ),
                    ),
                  if (controller.isUploading)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SizedBox(
                        width: 60,
                        height: 4,
                        child: LinearProgressIndicator(value: controller.uploadProgress),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
