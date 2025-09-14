import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:provider/provider.dart';

import 'package:siged/_widgets/background/background_cleaner.dart';
import 'package:siged/_utils/formats/format_field.dart';

import 'package:siged/_services/pdf/web_pdf_widget.dart';
import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/texts/divider_text.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_store.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_rules.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:siged/_services/pdf/web_pdf_controller.dart';
import 'package:siged/_utils/formats/input_formatters.dart';
import 'package:siged/_blocs/documents/contracts/contracts/contract_storage_bloc.dart';
import 'package:siged/_widgets/footBar/foot_bar.dart';

// ⬇️ seções
import 'package:siged/screens/documents/contract/mainInformation/main_company_section.dart';
import 'package:siged/screens/documents/contract/mainInformation/main_information_page.dart';
import 'package:siged/screens/documents/contract/mainInformation/main_manager_section.dart';

// ⬇️ agora tudo vem do ContractsController unificado
import 'package:siged/_blocs/documents/contracts/contracts/contracts_controller.dart';

// ⬇️ injeções necessárias
import 'package:siged/_blocs/documents/measurement/report/report_measurement_store.dart';
import 'package:siged/_blocs/documents/measurement/adjustment/adjustment_measurement_store.dart';
import 'package:siged/_blocs/documents/measurement/revision/revision_measurement_store.dart';
import 'package:siged/_blocs/documents/contracts/additives/additive_store.dart';
import 'package:siged/_blocs/documents/contracts/apostilles/apostilles_store.dart';

class MainManagerSection extends StatefulWidget {
  final void Function(ContractData)? onSaved;
  final ContractData? contractData;

  const MainManagerSection({super.key, this.contractData, this.onSaved});

  @override
  State<MainManagerSection> createState() => _MainManagerSectionState();
}

class _MainManagerSectionState extends State<MainManagerSection>
    with FormValidationMixin {
  bool _validationRegistered = false;
  ContractsController? _c;

  void _registerValidationOnce(BuildContext ctx) {
    if (_validationRegistered) return;
    final c = ctx.read<ContractsController>();
    _c = c;

    setupValidation(
      [
        c.contractStatusCtrl,
        c.initialValueOfContractCtrl,
        c.contractBiddingProcessNumberCtrl,
        c.contractNumberCtrl,
        c.contractServiceTypeCtrl,
        c.contractRegionOfStateCtrl,
        c.contractTypeCtrl,
        c.contractHighWayCtrl,
        c.summarySubjectContractCtrl,
        c.contractTextKmCtrl,
        c.datapublicacaodoeCtrl,
        c.contractCompanyLeaderCtrl,
        c.contractCompaniesInvolvedCtrl,
        c.cnoNumberCtrl,
        c.contractObjectDescriptionCtrl,
        c.regionalManagerCtrl,
        c.managerIdCtrl,
        c.managerPhoneNumberCtrl,
        c.cpfContractManagerCtrl,
        c.contractManagerArtNumberCtrl,
        c.initialValidityExecutionDaysCtrl,
        c.initialValidityContractDaysCtrl,
      ],
          () {
        final c2 = ctx.read<ContractsController>();
        c2.showErrors = true;
        c2.notifyListeners();
      },
    );

    _validationRegistered = true;
  }

  @override
  void dispose() {
    if (_validationRegistered) {
      final c = _c;
      if (c != null) {
        removeValidation(
          [
            c.contractStatusCtrl,
            c.initialValueOfContractCtrl,
            c.contractBiddingProcessNumberCtrl,
            c.contractNumberCtrl,
            c.contractServiceTypeCtrl,
            c.contractRegionOfStateCtrl,
            c.contractTypeCtrl,
            c.contractHighWayCtrl,
            c.summarySubjectContractCtrl,
            c.contractTextKmCtrl,
            c.datapublicacaodoeCtrl,
            c.contractCompanyLeaderCtrl,
            c.contractCompaniesInvolvedCtrl,
            c.cnoNumberCtrl,
            c.contractObjectDescriptionCtrl,
            c.regionalManagerCtrl,
            c.managerIdCtrl,
            c.managerPhoneNumberCtrl,
            c.cpfContractManagerCtrl,
            c.contractManagerArtNumberCtrl,
            c.initialValidityExecutionDaysCtrl,
            c.initialValidityContractDaysCtrl,
          ],
              () {},
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ContractsController>(
      create: (ctx) => ContractsController(
        store: ctx.read<ContractsStore>(),
        additivesStore: ctx.read<AdditivesStore>(),
        apostillesStore: ctx.read<ApostillesStore>(),
        reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
        adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(),
        revisionsStore: ctx.read<RevisionsMeasurementStore>(),
        contractStorageBloc: ctx.read<ContractStorageBloc>(),
        moduleKey: 'contracts',
        forceEditable: true,
      )..init(ctx, initial: widget.contractData),
      builder: (context, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _registerValidationOnce(context);
        });

        final c = context.watch<ContractsController>();
        const double pdfIconWidth = 98.0;
        const double gap = 12.0;

        Widget pdfPanel() {
          if (c.contractData.id == null) return const SizedBox.shrink();
          return SizedBox(
            width: pdfIconWidth,
            child: Column(
              children: [
                const SizedBox(height: 5),
                WebPdfWidgetGeneric(
                  type: PDFType.contract,
                  contractStorageBloc: c.contractStorageBloc,
                  contractData: c.contractData,
                  onUploadSaveToFirestore: (url) async {
                    if (c.contractData.id != null) {
                      await c.salvarUrlPdfDoContratoEAtualizarUI(
                        context,
                        contractId: c.contractData.id!,
                        url: url,
                        onSaved: (cd) => widget.onSaved?.call(cd),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        }

        final descricaoField = CustomTextField(
          enabled: c.isEditable,
          labelText: 'Descrição do objeto',
          controller: c.contractObjectDescriptionCtrl,
          maxLines: 5,
          maxLength: 2000,
          validator: validateRequired,
        );

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor:
            c.isBtnEnabled ? Colors.blue.shade300 : Colors.grey.shade400,
            onPressed:
            c.isEditable ? () => c.saveInformation(context, onSaved: widget.onSaved) : null,
            icon: c.isSaving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              c.isSaving
                  ? 'Salvando...'
                  : (c.contractData.id == null ? 'Salvar' : 'Atualizar'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const BackgroundClean(),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Form(
                            key: c.formKey,
                            autovalidateMode: c.showErrors
                                ? AutovalidateMode.always
                                : AutovalidateMode.disabled,
                            child: Column(
                              children: [
                                const SizedBox(height: 12),
                                const DividerText(title: 'Informações da empresa'),
                                const SizedBox(height: 12),
                                CompanyInfoSection(controller: c),

                                const SizedBox(height: 12),
                                const DividerText(title: 'Informações gerais do contrato'),
                                const SizedBox(height: 12),

                                // ---------- Campos do contrato ----------
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    // Status do contrato
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: DropDownButtonChange(
                                        validator: validateDropdown,
                                        enabled: c.isEditable,
                                        labelText: 'Status do contrato',
                                        items: ContractRules.statusTypes,
                                        controller: c.contractStatusCtrl,
                                        onChanged: (value) => c.contractData.contractStatus = value,
                                      ),
                                    ),
                                    // Nº do processo
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Nº do processo',
                                        controller: c.contractBiddingProcessNumberCtrl,
                                        inputFormatters: [processoMaskFormatter],
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    // Nº do contrato
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Nº do contrato',
                                        controller: c.contractNumberCtrl,
                                        inputFormatters: [contractMaskFormatter],
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    // Valor contratado
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        enabled: c.isEditable,
                                        labelText: 'Valor contratado',
                                        controller: c.initialValueOfContractCtrl,
                                        inputFormatters: [
                                          CurrencyInputFormatter(
                                            leadingSymbol: 'R\$',
                                            useSymbolPadding: true,
                                            thousandSeparator: ThousandSeparator.Period,
                                          ),
                                        ],
                                        validator: validateRequired,
                                      ),
                                    ),
                                    // Rodovia
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Rodovia',
                                        controller: c.contractHighWayCtrl,
                                        inputFormatters: [highwayMaskFormatter],
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    // Resumo do objeto
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Resumo do objeto',
                                        controller: c.summarySubjectContractCtrl,
                                      ),
                                    ),
                                    // Região
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Região',
                                        controller: c.contractRegionOfStateCtrl,
                                      ),
                                    ),
                                    // Extensão (km)
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Extensão (km)',
                                        controller: c.contractTextKmCtrl,
                                        inputFormatters: [ThreeDecimalTextInputFormatter(decimalDigits: 3)],
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    // Tipo de obra (dropdown)
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: DropDownButtonChange(
                                        validator: validateDropdown,
                                        enabled: c.isEditable,
                                        labelText: 'Tipo de obra',
                                        items: ContractRules.workTypes,
                                        controller: c.contractWorkTypeCtrl,
                                        onChanged: (value) {
                                          c.contractData.workType = value;
                                        },
                                      ),
                                    ),
                                    // Data de publicação DOE
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomDateField(
                                        controller: c.datapublicacaodoeCtrl,
                                        initialValue: c.contractData.publicationDateDoe,
                                        labelText: 'Data de publicação do DOE',
                                        enabled: c.isEditable,
                                        validator: (_) => validateDate(
                                          stringToDate(c.datapublicacaodoeCtrl.text),
                                        ),
                                        onChanged: (date) {
                                          c.contractData.publicationDateDoe = date;
                                          c.notifyListeners();
                                        },
                                      ),
                                    ),
                                    // Validade do contrato (dias)
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Validade do contrato (Dias)',
                                        controller: c.initialValidityContractDaysCtrl,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    // Validade da execução (dias)
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        validator: validateRequired,
                                        enabled: c.isEditable,
                                        labelText: 'Validade da execução (Dias)',
                                        controller: c.initialValidityExecutionDaysCtrl,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          LengthLimitingTextInputFormatter(4),
                                        ],
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    // Tipo de contrato (texto livre)
                                    SizedBox(
                                      width: responsiveInputWidth(
                                        context: context, itemsPerLine: 4, spacing: 12, margin: 12, extraPadding: 24,
                                      ),
                                      child: CustomTextField(
                                        enabled: c.isEditable,
                                        labelText: 'Tipo de contrato',
                                        controller: c.contractTypeCtrl,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // ---------- PDF + Descrição ----------
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: LayoutBuilder(
                                    builder: (context, inner) {
                                      final isSmallInner = inner.maxWidth < 700;
                                      if (isSmallInner) {
                                        return Column(
                                          children: [
                                            if (c.contractData.id != null) Center(child: pdfPanel()),
                                            if (c.contractData.id != null) const SizedBox(height: gap),
                                            SizedBox(
                                              width: responsiveInputWidth(
                                                context: context, itemsPerLine: 1, spacing: 12, margin: 12,
                                              ),
                                              child: descricaoField,
                                            ),
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (c.contractData.id != null) pdfPanel(),
                                            if (c.contractData.id != null) const SizedBox(width: gap),
                                            Expanded(child: descricaoField),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                                ),

                                const SizedBox(height: 12),
                                const DividerText(title: 'Informações do gestor do contrato'),
                                const SizedBox(height: 12),
                                ManagerInfoPage(controller: c),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const FootBar(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
