import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/contracts/contract_rules.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

// ⬇️ antes: main_information_controller.dart
// import '.../main_information_controller.dart';
// ⬇️ agora: ContractsController unificado
import 'package:siged/_blocs/process/contracts/contracts_controller.dart';

/// Seção isolada com os campos de "Informações da empresa".
class CompanyInfoSection extends StatefulWidget {
  final ContractsController controller; // ⬅️ trocado

  const CompanyInfoSection({
    super.key,
    required this.controller,
  });

  @override
  State<CompanyInfoSection> createState() => _CompanyInfoSectionState();
}

class _CompanyInfoSectionState extends State<CompanyInfoSection>
    with FormValidationMixin {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Empresa líder
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: DropDownButtonChange(
                validator: validateDropdown,
                enabled: c.isEditable,
                labelText: 'Empresa líder',
                items: ContractRules.companies,
                controller: c.contractCompanyLeaderCtrl,
                onChanged: (value) {
                  c.contractCompanyLeaderCtrl.text = value ?? '';
                  c.contractData.companyLeader = value;
                  c.showErrors = true;
                  c.notifyListeners();
                },
              ),
            ),

            // Consórcio envolvidas
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: CustomTextField(
                validator: validateRequired,
                enabled: c.isEditable,
                labelText: 'Consórcio envolvidas',
                controller: c.contractCompaniesInvolvedCtrl,
              ),
            ),

            // Tipo de Serviço
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: DropDownButtonChange(
                validator: validateDropdown,
                enabled: c.isEditable,
                labelText: 'Tipo de Serviço',
                items: ContractRules.typeOfService,
                controller: c.contractServiceTypeCtrl,
                onChanged: (value) {
                  c.contractServiceTypeCtrl.text = value ?? '';
                  c.contractData.contractServices = value;
                  c.showErrors = true;
                  c.notifyListeners();
                },
              ),
            ),

            // CNO
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: CustomTextField(
                validator: validateRequired,
                enabled: c.isEditable,
                labelText: 'CNO',
                controller: c.cnoNumberCtrl,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
