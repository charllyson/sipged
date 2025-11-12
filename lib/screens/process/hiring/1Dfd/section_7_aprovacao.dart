// lib/screens/process/hiring/1Dfd/dfd_sections/section_7_aprovacao.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/dropdown_yes_no.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

class SectionAprovacao extends StatelessWidget with FormValidationMixin {
  final DfdController controller;
  final List<UserData> users;

  SectionAprovacao({
    super.key,
    required this.controller,
    required this.users,
  });

  @override
  Widget build(BuildContext context) {
    // ===== 1) Usuário atual do Firebase =====
    final fbUser = FirebaseAuth.instance.currentUser;
    final currentUid   = fbUser?.uid ?? '';
    final currentName  = (fbUser?.displayName ?? '').trim();
    final currentEmail = (fbUser?.email ?? '').trim();
    final currentPhoto = (fbUser?.photoURL ?? '').trim();

    // ===== 2) Garante que o usuário atual exista na lista de opções =====
    // Caso não esteja, criamos um UserData mínimo só para exibir na UI.
    final alreadyInList = users.any((u) => (u.id ?? '') == currentUid);
    final List<UserData> usersWithSelf = alreadyInList
        ? users
        : [
      ...users,
      UserData(
        id: currentUid,
        name: currentName.isNotEmpty ? currentName : null,
        email: currentEmail.isNotEmpty ? currentEmail : null,
        urlPhoto: currentPhoto.isNotEmpty ? currentPhoto : null,
      ),
    ];

    // ===== 3) Se ainda não há autoridade definida no controller, fixa no usuário atual =====
    if ((controller.dfdAutoridadeAprovadoraUserId == null ||
        controller.dfdAutoridadeAprovadoraUserId!.isEmpty) &&
        currentUid.isNotEmpty) {
      controller.dfdAutoridadeAprovadoraUserId = currentUid;

      // Tenta achar um label amigável para exibir
      final self = usersWithSelf.firstWhere(
            (u) => (u.id ?? '') == currentUid,
        orElse: () => UserData(
          id: currentUid,
          name: currentName.isNotEmpty ? currentName : null,
          email: currentEmail.isNotEmpty ? currentEmail : null,
          urlPhoto: currentPhoto.isNotEmpty ? currentPhoto : null,
        ),
      );
      controller.dfdAutoridadeAprovadoraCtrl.text =
          self.name ?? self.email ?? currentUid;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('7) Aprovação / Alçada'),
        LayoutBuilder(builder: (context, inner) {
          final w3v = inputWidth(context: context, inner: inner, perLine: 3, minItemWidth: 260);
          final w1v = inputWidth(context: context, inner: inner, perLine: 1, minItemWidth: 400);
          return Wrap(spacing: 12, runSpacing: 12, children: [
            // ===== AUTORIDADE APROVADORA (TRAVADA NO USUÁRIO ATUAL) =====
            SizedBox(
              width: w3v,
              child: AutocompleteUserClass(
                label: 'Autoridade aprovadora',
                controller: controller.dfdAutoridadeAprovadoraCtrl,
                allUsers: users,
                enabled: controller.isEditable,
                initialUserId: controller.dfdAutoridadeAprovadoraUserId,
                validator: validateRequired,
                onChanged: (userId) => controller.dfdAutoridadeAprovadoraUserId = userId,
              ),
            ),

            // CPF da autoridade
            SizedBox(
              width: w3v,
              child: CustomTextField(
                controller: controller.dfdCpfAutoridadeCtrl,
                enabled: controller.isEditable,
                validator: validateRequired,
                labelText: 'CPF da autoridade',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  TextInputMask(mask: '999.999.999-99'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),

            // Data da aprovação
            SizedBox(
              width: w3v,
              child: CustomDateField(
                controller: controller.dfdDataAprovacaoCtrl,
                enabled: controller.isEditable,
                labelText: 'Data da aprovação',
              ),
            ),

            // Parecer/resumo
            SizedBox(
              width: w1v,
              child: CustomTextField(
                controller: controller.dfdParecerResumoCtrl,
                enabled: controller.isEditable,
                labelText: 'Parecer/resumo da aprovação',
                maxLines: 3,
              ),
            ),
          ]);
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
