import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
import 'package:siged/_widgets/input/dropdown_yes_no.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionIdentificacao extends StatefulWidget {
  final DfdController controller;
  const SectionIdentificacao({super.key, required this.controller});

  @override
  State<SectionIdentificacao> createState() => _SectionIdentificacaoState();
}

class _SectionIdentificacaoState extends State<SectionIdentificacao>
    with FormValidationMixin {
  DfdController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  String? get _companyId => controller.companyId;

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('1) Identificação da Demanda'),
        LayoutBuilder(builder: (context, inner) {
          final w4 = inputWidth(context: context, inner: inner, perLine: 4, minItemWidth: 260);

          return Wrap(spacing: 12, runSpacing: 12, children: [
            // ─────────── Contratante ───────────
            SizedBox(
              width: w4,
              child: DropDownButtonChange(
                width: w4,
                labelText: 'Contratante',
                controller: controller.dfdOrgaoDemandanteCtrl, // mostra o nome
                enabled: controller.isEditable,
                validator: validateRequired,
                firestore: FirebaseFirestore.instance,
                collectionPath: 'companies',
                labelField: 'companyName',
                idField: 'companyId',
                autoLoadWhenEmpty: true,
                allowDuplicates: false,
                specialItemLabel: 'Adicionar contratante',
                showSpecialWhenEmpty: true,
                showSpecialAlways: true,
                greyItems: const {},             // retrocompat
                selectedId: controller.companyId, // ← seleção por ID
                onChangedIdLabel: (id, label) => controller.setCompany(id: id, label: label),
              ),
            ),

            // ─────────── Unidade/Setor ───────────
            SizedBox(
              width: w4,
              child: DropDownButtonChange(
                key: ValueKey('units-${controller.companyNonce}-${_companyId ?? "none"}'),
                width: w4,
                tooltipMessage: _companyId == null ? 'Selecione o contratante' : null,
                labelText: 'Unidade/Setor solicitante',
                controller: controller.dfdUnidadeSolicitanteCtrl,
                items: const [],
                enabled: controller.isEditable && _companyId != null,
                validator: validateRequired,
                firestore: FirebaseFirestore.instance,
                collectionPath: _companyId == null ? null : 'companies/${_companyId}/units',
                labelField: 'unitName',
                idField: 'unitId',
                autoLoadWhenEmpty: true,
                allowDuplicates: false,
                selectedId: controller.unitId,
                onChangedIdLabel: (id, label) => controller.setUnit(id: id, label: label),
                buildFirestoreDoc: (id, label) => {
                  'unitId': id,
                  'unitName': label,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                },
                specialItemLabel: 'Adicionar unidade/setor',
                showSpecialWhenEmpty: true,
                showSpecialAlways: true,
              ),
            ),

            // ─────────── Regional/Área ───────────
            SizedBox(
              width: w4,
              child: DropDownButtonChange(
                key: ValueKey('regions-${controller.companyNonce}-${_companyId ?? "none"}'),
                width: w4,
                labelText: 'Regional/Área',
                tooltipMessage: _companyId == null ? 'Selecione o contratante' : null,
                controller: controller.dfdRegionalCtrl, // controller estável
                items: const [],
                enabled: controller.isEditable && _companyId != null,
                validator: validateRequired,
                firestore: FirebaseFirestore.instance,
                collectionPath: _companyId == null ? null : 'companies/${_companyId}/regions',
                labelField: 'regionName',
                idField: 'regionId',
                autoLoadWhenEmpty: true,
                allowDuplicates: false,
                buildFirestoreDoc: (id, label) => {
                  'regionId': id,
                  'regionName': label,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                },
                specialItemLabel: 'Adicionar regional/área',
                showSpecialWhenEmpty: true,
                showSpecialAlways: true,
                onChanged: (v) => controller.dfdRegionalValue = v ?? '',
                selectedId: controller.regionId,
                onChangedIdLabel: (id, label) => controller.setRegion(id: id, label: label),
              ),
            ),

            // ─────────── (NOVO) Status do contrato ───────────
            SizedBox(
              width: w4,
              child: DropDownButtonChange(
                width: w4,
                labelText: 'Status do contrato',
                controller: TextEditingController(text: controller.dfdStatusContratoValue ?? ''),
                items: DfdData.statusTypes,
                enabled: controller.isEditable,
                validator: validateRequired,
                onChanged: (v) => controller.dfdStatusContratoValue = v,
              ),
            ),

            // ─────────── Solicitante ───────────
            SizedBox(
              width: w4,
              child: AutocompleteUserClass(
                label: 'Solicitante (responsável pela demanda)',
                controller: controller.dfdSolicitanteCtrl, // exibe NOME/email
                allUsers: users,
                enabled: controller.isEditable,
                initialUserId: controller.dfdSolicitanteUserId,
                validator: validateRequired,
                onChanged: (userId) => controller.dfdSolicitanteUserId = userId,
              ),
            ),

            // ─────────── (NOVO) Nº do processo ───────────
            SizedBox(
              width: w4,
              child: CustomTextField(
                controller: controller.dfdNumeroProcessoCtrl,
                enabled: controller.isEditable,
                validator: validateRequired,
                labelText: 'Nº do processo',
                // Se quiser aplicar a mesma máscara do módulo de contratos:
                // inputFormatters: [processoMaskFormatter],
                keyboardType: TextInputType.text,
              ),
            ),

            SizedBox(
              width: w4,
              child: CustomTextField(
                controller: controller.dfdCpfSolicitanteCtrl,
                validator: validateRequired,
                enabled: controller.isEditable,
                labelText: 'CPF do solicitante',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  TextInputMask(mask: '999.999.999-99'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: w4,
              child: CustomTextField(
                controller: controller.dfdCargoSolicitanteCtrl,
                enabled: controller.isEditable,
                validator: validateRequired,
                labelText: 'Cargo/Função',
              ),
            ),
            SizedBox(
              width: w4,
              child: CustomTextField(
                controller: controller.dfdEmailSolicitanteCtrl,
                enabled: controller.isEditable,
                validator: validateEmail,
                labelText: 'E-mail institucional',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            SizedBox(
              width: w4,
              child: CustomTextField(
                controller: controller.dfdTelefoneSolicitanteCtrl,
                enabled: controller.isEditable,
                validator: validateRequired,
                labelText: 'Telefone do solicitante',
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                  TextInputMask(mask: '(99) 99999-9999'),
                ],
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: w4,
              child: CustomDateField(
                controller: controller.dfdDataSolicitacaoCtrl,
                enabled: controller.isEditable,
                labelText: 'Data da solicitação',
              ),
            ),

          ]);
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
