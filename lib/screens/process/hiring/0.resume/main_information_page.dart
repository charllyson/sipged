// lib/_controllers/process/contracts/widgets/manager_info_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_utils/responsive_utils.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/mask_class.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_blocs/process/contracts/contracts_controller.dart';

class ManagerInfoPage extends StatefulWidget {
  final ContractsController controller;

  const ManagerInfoPage({
    super.key,
    required this.controller,
  });

  @override
  State<ManagerInfoPage> createState() => _ManagerInfoPageState();
}

class _ManagerInfoPageState extends State<ManagerInfoPage>
    with FormValidationMixin {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    final users = context.select<UserBloc, List<UserData>>(
          (b) => b.state.all,
    );

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              const SizedBox.shrink(),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }
}
