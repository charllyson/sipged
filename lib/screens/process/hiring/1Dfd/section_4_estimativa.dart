// lib/screens/process/hiring/1Dfd/dfd_sections/section_4_estimativa.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionEstimativa extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionEstimativa({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionEstimativa> createState() => _SectionEstimativaState();
}

class _SectionEstimativaState extends State<SectionEstimativa>
    with FormValidationMixin {
  // controllers
  late final TextEditingController _fonteRecursoCtrl;
  late final TextEditingController _programaTrabalhoCtrl;
  late final TextEditingController _ptresCtrl;
  late final TextEditingController _naturezaDespesaCtrl;
  late final TextEditingController _estimativaValorCtrl;
  late final TextEditingController _metodologiaEstimativaCtrl;

  String? _companyId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _fonteRecursoCtrl        = TextEditingController(text: d.fonteRecurso);
    _programaTrabalhoCtrl    =
        TextEditingController(text: d.programaTrabalho);
    _ptresCtrl               = TextEditingController(text: d.ptres);
    _naturezaDespesaCtrl     =
        TextEditingController(text: d.naturezaDespesa);
    _estimativaValorCtrl     =
        TextEditingController(text: d.estimativaValor);
    _metodologiaEstimativaCtrl =
        TextEditingController(text: d.metodologiaEstimativa);

    _resolveCompanyIdFromData();
  }

  @override
  void didUpdateWidget(covariant SectionEstimativa oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      _fonteRecursoCtrl.text        = d.fonteRecurso;
      _programaTrabalhoCtrl.text    = d.programaTrabalho;
      _ptresCtrl.text               = d.ptres;
      _naturezaDespesaCtrl.text     = d.naturezaDespesa;
      _estimativaValorCtrl.text     = d.estimativaValor;
      _metodologiaEstimativaCtrl.text = d.metodologiaEstimativa;

      if (oldWidget.data.orgaoDemandante != widget.data.orgaoDemandante) {
        _resolveCompanyIdFromData();
      }
    }
  }

  @override
  void dispose() {
    _fonteRecursoCtrl.dispose();
    _programaTrabalhoCtrl.dispose();
    _ptresCtrl.dispose();
    _naturezaDespesaCtrl.dispose();
    _estimativaValorCtrl.dispose();
    _metodologiaEstimativaCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      fonteRecurso:         _fonteRecursoCtrl.text,
      programaTrabalho:     _programaTrabalhoCtrl.text,
      ptres:                _ptresCtrl.text,
      naturezaDespesa:      _naturezaDespesaCtrl.text,
      estimativaValor:      _estimativaValorCtrl.text,
      metodologiaEstimativa:_metodologiaEstimativaCtrl.text,
    );
    widget.onChanged(updated);
  }

  Future<void> _resolveCompanyIdFromData() async {
    final label = widget.data.orgaoDemandante.trim();
    if (label.isEmpty) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .where('companyName', isEqualTo: label)
          .limit(1)
          .get();

      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        setState(() {
          _companyId = snap.docs.first.id;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('4) Estimativa Orçamentária (preliminar)'),
        LayoutBuilder(
          builder: (context, inner) {
            final w3 = inputW3(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Fonte de recurso
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'funding-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Fonte de recurso',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _fonteRecursoCtrl,
                    items: const [],
                    enabled: widget.isEditable && _companyId != null,
                    validator: validateRequired,
                    firestore: FirebaseFirestore.instance,
                    collectionPath: _companyId == null
                        ? null
                        : 'companies/${_companyId}/funding_sources',
                    labelField: 'name',
                    idField: 'id',
                    autoLoadWhenEmpty: true,
                    allowDuplicates: false,
                    buildFirestoreDoc: (id, label) => {
                      'id': id,
                      'name': label,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy':
                      FirebaseAuth.instance.currentUser?.uid,
                    },
                    specialItemLabel: 'Adicionar fonte de recurso',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    selectedId: null,
                    onChangedIdLabel: (id, label) {
                      _fonteRecursoCtrl.text = label;
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // Programa de trabalho / Ação
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'programs-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Programa de trabalho / Ação',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _programaTrabalhoCtrl,
                    items: const [],
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    firestore: FirebaseFirestore.instance,
                    collectionPath: _companyId == null
                        ? null
                        : 'companies/${_companyId}/programs',
                    labelField: 'name',
                    idField: 'id',
                    autoLoadWhenEmpty: true,
                    allowDuplicates: false,
                    buildFirestoreDoc: (id, label) => {
                      'id': id,
                      'name': label,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy':
                      FirebaseAuth.instance.currentUser?.uid,
                    },
                    specialItemLabel: 'Adicionar programa/ação',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    selectedId: null,
                    onChangedIdLabel: (id, label) {
                      _programaTrabalhoCtrl.text = label;
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // PTRES
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _ptresCtrl,
                    enabled: widget.isEditable,
                    labelText: 'PTRES (opcional)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Natureza da despesa (ND)
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'expense-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Natureza da despesa (ND)',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _naturezaDespesaCtrl,
                    items: const [],
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    firestore: FirebaseFirestore.instance,
                    collectionPath: _companyId == null
                        ? null
                        : 'companies/${_companyId}/expense_natures',
                    labelField: 'name',
                    idField: 'id',
                    autoLoadWhenEmpty: true,
                    allowDuplicates: false,
                    buildFirestoreDoc: (id, label) => {
                      'id': id,
                      'name': label,
                      'createdAt': FieldValue.serverTimestamp(),
                      'createdBy':
                      FirebaseAuth.instance.currentUser?.uid,
                    },
                    specialItemLabel: 'Adicionar ND',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    selectedId: null,
                    onChangedIdLabel: (id, label) {
                      _naturezaDespesaCtrl.text = label;
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // Estimativa de valor
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _estimativaValorCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Estimativa de valor (R\$)',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Metodologia da estimativa
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _metodologiaEstimativaCtrl,
                    enabled: widget.isEditable,
                    labelText:
                    'Metodologia da estimativa (ex.: SINAPI, DER, etc.)',
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
