import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../../_provider/user/user_provider.dart';
import '../../../../../_utils/responsive_utils.dart';
import '../../../../../_widgets/autocomplete/autocomplete_user_class.dart';
import '../../../../../_widgets/input/custom_text_field.dart';
import '../../../../../_widgets/mask_class.dart';
import '../../../../../_widgets/validates/form_validation_mixin.dart';

import './main_information_controller.dart';

class ManagerInfoSection extends StatefulWidget {
  final MainInformationController controller;

  const ManagerInfoSection({
    super.key,
    required this.controller,
  });

  @override
  State<ManagerInfoSection> createState() => _ManagerInfoSectionState();
}

class _ManagerInfoSectionState extends State<ManagerInfoSection>
    with FormValidationMixin {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final users = context.read<UserProvider>().userDataList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha 1: Gerente, Fiscal, CPF, ART
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: AutocompleteUserClass(
                label: 'Gerente Regional',
                controller: c.regionalManagerCtrl,
                allUsers: users,
                enabled: c.isEditable,
                initialUserId: c.contractData.regionalManager,
                validator: validateRequired,
              ),
            ),
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: AutocompleteUserClass(
                label: 'Fiscal da obra',
                controller: c.managerIdCtrl,
                allUsers: users,
                initialUserId: c.contractData.managerId,
                validator: validateRequired,
                enabled: c.isEditable,
              ),
            ),
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: CustomTextField(
                controller: c.cpfContractManagerCtrl,
                validator: validateRequired,
                enabled: c.isEditable,
                labelText: 'CPF do responsável',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  TextInputMask(mask: '999.999.999-99'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
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
                labelText: 'Nº ART',
                controller: c.contractManagerArtNumberCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Linha 2: Telefone + placeholders
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
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
                labelText: 'Telefone',
                controller: c.managerPhoneNumberCtrl,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  TextInputMask(mask: '(99) 99999-9999'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: const SizedBox.shrink(),
            ),
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: const SizedBox.shrink(),
            ),
            SizedBox(
              width: responsiveInputWidth(
                context: context,
                itemsPerLine: 4,
                spacing: 12,
                margin: 12,
                extraPadding: 24,
              ),
              child: const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}
