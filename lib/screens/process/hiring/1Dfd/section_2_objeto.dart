// lib/screens/process/hiring/1Dfd/dfd_sections/section_2_objeto.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';

import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionObjeto extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionObjeto({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionObjeto> createState() => _SectionObjetoState();
}

class _SectionObjetoState extends State<SectionObjeto>
    with FormValidationMixin {
  // controllers
  late final TextEditingController _descricaoObjetoCtrl;
  late final TextEditingController _justificativaCtrl;
  late final TextEditingController _rodoviaCtrl;
  late final TextEditingController _extensaoKmCtrl;

  /// 🆕 Valor da demanda
  late final TextEditingController _valorDemandaCtrl;

  // estados auxiliares
  String? _tipoContratacao;
  String? _tipoObra;
  String? _companyId; // obtido a partir de orgaoDemandante

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _descricaoObjetoCtrl = TextEditingController(text: d.descricaoObjeto);
    _justificativaCtrl   = TextEditingController(text: d.justificativa);
    _rodoviaCtrl         = TextEditingController(text: d.rodovia);
    _extensaoKmCtrl      = TextEditingController(
      text: d.extensaoKm != null ? _formatKm(d.extensaoKm!) : '',
    );

    _valorDemandaCtrl    = TextEditingController(
      text: d.valorDemanda != null ? _formatMoney(d.valorDemanda!) : '',
    );

    _tipoContratacao = d.tipoContratacao;
    _tipoObra        = d.tipoObra;

    _resolveCompanyIdFromData();
  }

  @override
  void didUpdateWidget(covariant SectionObjeto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      // Atualiza texto apenas quando o DfdData muda externamente
      _descricaoObjetoCtrl.text = d.descricaoObjeto;
      _justificativaCtrl.text   = d.justificativa;
      _rodoviaCtrl.text         = d.rodovia;
      _extensaoKmCtrl.text =
      d.extensaoKm != null ? _formatKm(d.extensaoKm!) : '';
      _valorDemandaCtrl.text =
      d.valorDemanda != null ? _formatMoney(d.valorDemanda!) : '';

      _tipoContratacao = d.tipoContratacao;
      _tipoObra        = d.tipoObra;

      // se trocou contratante, tenta resolver novo companyId
      if (oldWidget.data.orgaoDemandante != widget.data.orgaoDemandante) {
        _resolveCompanyIdFromData();
      }
    }
  }

  @override
  void dispose() {
    _descricaoObjetoCtrl.dispose();
    _justificativaCtrl.dispose();
    _rodoviaCtrl.dispose();
    _extensaoKmCtrl.dispose();
    _valorDemandaCtrl.dispose();
    super.dispose();
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
    } catch (_) {
      // silencia erros de lookup
    }
  }

  String _formatKm(double value) {
    // simples: usa ponto, você pode depois adaptar para vírgula/localização
    return value.toStringAsFixed(2);
  }

  double? _parseKm(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  String? _validateKm(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Obrigatório';
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    final d = double.tryParse(cleaned);
    if (d == null) return 'Valor inválido';
    if (d < 0) return 'Não pode ser negativo';
    return null;
  }

  // ===== Helpers para valor da demanda =====

  String _formatMoney(double value) {
    // formato simples: 1234.56 -> "1234,56"
    final s = value.toStringAsFixed(2);
    return s.replaceAll('.', ',');
  }

  double? _parseMoney(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  String? _validateMoney(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Obrigatório';
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    final d = double.tryParse(cleaned);
    if (d == null) return 'Valor inválido';
    if (d < 0) return 'Não pode ser negativo';
    return null;
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      tipoContratacao: widget.data.tipoContratacao != _tipoContratacao
          ? _tipoContratacao ?? ''
          : _tipoContratacao ?? widget.data.tipoContratacao,
      tipoObra:        _tipoObra,
      descricaoObjeto: _descricaoObjetoCtrl.text,
      justificativa:   _justificativaCtrl.text,
      rodovia:         _rodoviaCtrl.text,
      extensaoKm:      _parseKm(_extensaoKmCtrl.text),
      // 🆕 valorDemanda
      valorDemanda:    _parseMoney(_valorDemandaCtrl.text),
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('2) Objeto / Escopo'),
        LayoutBuilder(
          builder: (context, inner) {
            final w3 = inputW3(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Tipo de contratação
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de contratação',
                    // aqui pode ser controller "descartável" porque não digitamos texto manualmente,
                    // só escolhemos item da lista
                    controller: TextEditingController(
                      text: _tipoContratacao ?? '',
                    ),
                    items: HiringData.tiposDeContratacao,
                    onChanged: (v) {
                      _tipoContratacao = v ?? '';
                      _emitChange();
                      setState(() {});
                    },
                    validator: validateRequired,
                  ),
                ),

                // Tipo de obra
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de obra',
                    controller: TextEditingController(
                      text: _tipoObra ?? '',
                    ),
                    items: HiringData.workTypes,
                    onChanged: (v) {
                      _tipoObra = v?.isEmpty == true ? null : v;
                      _emitChange();
                      setState(() {});
                    },
                    validator: validateRequired,
                  ),
                ),

                // Rodovia (por contratante)
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey(
                      'roads-${widget.data.orgaoDemandante}-${_companyId ?? "none"}',
                    ),
                    width: w3,
                    labelText: 'Rodovia',
                    tooltipMessage: _companyId == null
                        ? 'Selecione o contratante na identificação'
                        : null,
                    controller: _rodoviaCtrl,
                    items: const [],
                    enabled: widget.isEditable && _companyId != null,
                    validator: validateRequired,
                    firestore: FirebaseFirestore.instance,
                    collectionPath: _companyId == null
                        ? null
                        : 'companies/${_companyId}/roads',
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
                    specialItemLabel: 'Adicionar rodovia',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    selectedId: null, // não persistimos ID no DfdData
                    onChangedIdLabel: (id, label) {
                      _rodoviaCtrl.text = label;
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // Extensão (km)
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _extensaoKmCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Extensão (km)',
                    hintText: 'Ex.: 12,34',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9\.,]'),
                      ),
                    ],
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    validator: _validateKm,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Nome da demanda (usa descricaoObjeto)
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _descricaoObjetoCtrl,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    labelText: 'Nome da demanda',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // 🆕 Valor da demanda
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _valorDemandaCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Valor da demanda (R\$)',
                    hintText: 'Ex.: 1.234,56',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9\.,]'),
                      ),
                    ],
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    validator: _validateMoney,
                    onChanged: (_) {
                      // importante: NÃO fazer _valorDemandaCtrl.text = ...
                      // aqui — só emite mudança para o DfdData
                      _emitChange();
                    },
                  ),
                ),

                // Justificativa
                SizedBox(
                  width: inputW1(context, inner),
                  child: CustomTextField(
                    controller: _justificativaCtrl,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    labelText:
                    'Justificativa da contratação (problema/objetivo)',
                    maxLines: 4,
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
