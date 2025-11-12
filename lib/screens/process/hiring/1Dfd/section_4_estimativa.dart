// lib/screens/process/hiring/1Dfd/dfd_sections/section_4_estimativa.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/dropdown_yes_no.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

class SectionEstimativa extends StatelessWidget with FormValidationMixin {
  final DfdController controller;
  SectionEstimativa({super.key, required this.controller});

  String? get _companyId => controller.companyId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('4) Estimativa Orçamentária (preliminar)'),
        LayoutBuilder(builder: (context, inner) {
          final w3 = inputWidth(context: context, inner: inner, perLine: 3, minItemWidth: 240);
          return Wrap(spacing: 12, runSpacing: 12, children: [
            // Fonte de recurso
            SizedBox(
              width: w3,
              child: DropDownButtonChange(
                key: ValueKey('funding-${controller.companyNonce}-${_companyId ?? "none"}'),
                width: w3,
                labelText: 'Fonte de recurso',
                tooltipMessage: _companyId == null ? 'Selecione o contratante' : null,
                controller: controller.dfdFonteRecursoCtrl,
                items: const [],
                enabled: controller.isEditable && _companyId != null,
                validator: validateRequired,
                firestore: FirebaseFirestore.instance,
                collectionPath: _companyId == null ? null : 'companies/${_companyId}/funding_sources',
                labelField: 'name',
                idField: 'id',
                autoLoadWhenEmpty: true,
                allowDuplicates: false,
                buildFirestoreDoc: (id, label) => {
                  'id': id,
                  'name': label,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                },
                specialItemLabel: 'Adicionar fonte de recurso',
                showSpecialWhenEmpty: true,
                showSpecialAlways: true,

                // ✅ pré-seleção pelo ID + callback para atualizar controller
                selectedId: controller.fundingSourceId,
                onChangedIdLabel: (id, label) => controller.setFundingSource(
                  id: id,
                  label: label,
                ),
              ),
            ),

            // Programa de trabalho / Ação
            SizedBox(
              width: w3,
              child: DropDownButtonChange(
                key: ValueKey('programs-${controller.companyNonce}-${_companyId ?? "none"}'),
                width: w3,
                labelText: 'Programa de trabalho / Ação',
                tooltipMessage: _companyId == null ? 'Selecione o contratante' : null,
                controller: controller.dfdProgramaTrabalhoCtrl,
                items: const [],
                enabled: controller.isEditable && _companyId != null,
                validator: null,
                firestore: FirebaseFirestore.instance,
                collectionPath: _companyId == null ? null : 'companies/${_companyId}/programs',
                labelField: 'name',
                idField: 'id',
                autoLoadWhenEmpty: true,
                allowDuplicates: false,
                buildFirestoreDoc: (id, label) => {
                  'id': id,
                  'name': label,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                },
                specialItemLabel: 'Adicionar programa/ação',
                showSpecialWhenEmpty: true,
                showSpecialAlways: true,

                // ✅ pré-seleção pelo ID + callback
                selectedId: controller.programId,
                onChangedIdLabel: (id, label) => controller.setProgram(
                  id: id,
                  label: label,
                ),
              ),
            ),

            SizedBox(
              width: w3,
              child: CustomTextField(
                controller: controller.dfdPtresCtrl,
                enabled: controller.isEditable,
                labelText: 'PTRES (opcional)',
              ),
            ),

            // Natureza da despesa (ND)
            SizedBox(
              width: w3,
              child: DropDownButtonChange(
                key: ValueKey('expense-${controller.companyNonce}-${_companyId ?? "none"}'),
                width: w3,
                labelText: 'Natureza da despesa (ND)',
                tooltipMessage: _companyId == null ? 'Selecione o contratante' : null,
                controller: controller.dfdNaturezaDespesaCtrl,
                items: const [],
                enabled: controller.isEditable && _companyId != null,
                validator: null,
                firestore: FirebaseFirestore.instance,
                collectionPath: _companyId == null ? null : 'companies/${_companyId}/expense_natures',
                labelField: 'name',
                idField: 'id',
                autoLoadWhenEmpty: true,
                allowDuplicates: false,
                buildFirestoreDoc: (id, label) => {
                  'id': id,
                  'name': label,
                  'createdAt': FieldValue.serverTimestamp(),
                  'createdBy': FirebaseAuth.instance.currentUser?.uid,
                },
                specialItemLabel: 'Adicionar ND',
                showSpecialWhenEmpty: true,
                showSpecialAlways: true,

                // ✅ pré-seleção pelo ID + callback
                selectedId: controller.expenseNatureId,
                onChangedIdLabel: (id, label) => controller.setExpenseNature(
                  id: id,
                  label: label,
                ),
              ),
            ),

            SizedBox(
              width: w3,
              child: CustomTextField(
                controller: controller.dfdEstimativaValorCtrl,
                enabled: controller.isEditable,
                labelText: 'Estimativa de valor (R\$)',
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(
              width: w3,
              child: CustomTextField(
                controller: controller.dfdMetodologiaEstimativaCtrl,
                enabled: controller.isEditable,
                labelText: 'Metodologia da estimativa (ex.: SINAPI, DER, etc.)',
              ),
            ),
          ]);
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
