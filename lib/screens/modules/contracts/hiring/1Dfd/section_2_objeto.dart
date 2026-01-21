// lib/screens/modules/contracts/hiring/1Dfd/section_2_objeto.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';

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

class _SectionObjetoState extends State<SectionObjeto> with FormValidationMixin {
  late final TextEditingController _tipoContratacaoCtrl;
  late final TextEditingController _tipoObraCtrl;
  late final TextEditingController _descricaoObjetoCtrl;
  late final TextEditingController _justificativaCtrl;
  late final TextEditingController _rodoviaCtrl;
  late final TextEditingController _extensaoKmCtrl;
  late final TextEditingController _valorDemandaCtrl;

  String? _companyId;
  int _roadsNonce = 0;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _tipoContratacaoCtrl = TextEditingController(text: d.tipoContratacao ?? '');
    _tipoObraCtrl = TextEditingController(text: d.tipoObra ?? '');
    _descricaoObjetoCtrl = TextEditingController(text: d.descricaoObjeto ?? '');
    _justificativaCtrl = TextEditingController(text: d.justificativa ?? '');
    _rodoviaCtrl = TextEditingController(text: d.rodovia ?? '');

    _extensaoKmCtrl = TextEditingController(
      text: d.extensaoKm != null ? _formatKm(d.extensaoKm!) : '',
    );

    _valorDemandaCtrl = TextEditingController(
      text: d.valorDemanda != null ? _formatMoney(d.valorDemanda!) : '',
    );

    _companyId = (d.companyId ?? '').trim().isEmpty ? null : d.companyId!.trim();

    // ✅ garante setup da empresa já no initState
    if ((_companyId ?? '').isNotEmpty) {
      context.read<SetupCubit>().ensureCompanySetupLoaded(_companyId!);
    }
  }

  @override
  void didUpdateWidget(covariant SectionObjeto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    void _sync(TextEditingController c, String? newText) {
      final v = newText ?? '';
      if (c.text != v) c.text = v;
    }

    _sync(_tipoContratacaoCtrl, d.tipoContratacao);
    _sync(_tipoObraCtrl, d.tipoObra);
    _sync(_descricaoObjetoCtrl, d.descricaoObjeto);
    _sync(_justificativaCtrl, d.justificativa);

    // Rodovia é dependente de companyId; se trocou, limpa
    final newCompanyId = (d.companyId ?? '').trim().isEmpty ? null : d.companyId!.trim();
    if (_companyId != newCompanyId) {
      setState(() {
        _companyId = newCompanyId;
        _roadsNonce++;
        _rodoviaCtrl.clear();
      });

      if ((_companyId ?? '').isNotEmpty) {
        context.read<SetupCubit>().ensureCompanySetupLoaded(_companyId!);
      }
      _emitChange(); // grava limpeza da rodovia
    } else {
      _sync(_rodoviaCtrl, d.rodovia);
    }

    // Numéricos: sincroniza sempre com o modelo (evita ficar “preso”)
    _sync(_extensaoKmCtrl, d.extensaoKm != null ? _formatKm(d.extensaoKm!) : '');
    _sync(_valorDemandaCtrl, d.valorDemanda != null ? _formatMoney(d.valorDemanda!) : '');
  }

  @override
  void dispose() {
    _tipoContratacaoCtrl.dispose();
    _tipoObraCtrl.dispose();
    _descricaoObjetoCtrl.dispose();
    _justificativaCtrl.dispose();
    _rodoviaCtrl.dispose();
    _extensaoKmCtrl.dispose();
    _valorDemandaCtrl.dispose();
    super.dispose();
  }

  String _formatKm(double value) => value.toStringAsFixed(2);

  double? _parseKm(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  String _formatMoney(double value) {
    final s = value.toStringAsFixed(2);
    return s.replaceAll('.', ',');
  }

  double? _parseMoney(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final cleaned = s.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned);
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      tipoContratacao: _tipoContratacaoCtrl.text.isEmpty ? null : _tipoContratacaoCtrl.text,
      tipoObra: _tipoObraCtrl.text.isEmpty ? null : _tipoObraCtrl.text,
      descricaoObjeto: _descricaoObjetoCtrl.text,
      justificativa: _justificativaCtrl.text,
      rodovia: _rodoviaCtrl.text,
      extensaoKm: _parseKm(_extensaoKmCtrl.text),
      valorDemanda: _parseMoney(_valorDemandaCtrl.text),

      // ✅ mantém o companyId vindo da seção 1
      companyId: _companyId,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final systemCubit = context.read<SetupCubit>();
    context.watch<SetupCubit>();

    final List<SetupData> roads = systemCubit.getRoadsForCompany(_companyId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '2) Objeto / Escopo'),
        LayoutBuilder(
          builder: (context, inner) {
            final w3 = inputW3(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de contratação',
                    controller: _tipoContratacaoCtrl,
                    items: HiringData.tiposDeContratacao,
                    onChanged: (v) {
                      _tipoContratacaoCtrl.text = v ?? '';
                      _emitChange();
                      setState(() {});
                    },
                    validator: null,
                  ),
                ),
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    enabled: widget.isEditable,
                    labelText: 'Tipo de obra',
                    controller: _tipoObraCtrl,
                    items: HiringData.workTypes,
                    onChanged: (v) {
                      _tipoObraCtrl.text = (v == null || v.isEmpty) ? '' : v;
                      _emitChange();
                      setState(() {});
                    },
                    validator: null,
                  ),
                ),

                // ✅ Rodovia depende estritamente de companyId
                SizedBox(
                  width: w3,
                  child: DropDownButtonChange(
                    key: ValueKey('roads-$_roadsNonce-${_companyId ?? "none"}'),
                    width: w3,
                    labelText: 'Rodovia',
                    tooltipMessage: _companyId == null ? 'Selecione o contratante na identificação' : null,
                    controller: _rodoviaCtrl,
                    items: roads.map((e) => e.label).toList(),
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    specialItemLabel: 'Adicionar rodovia',
                    showSpecialWhenEmpty: true,
                    showSpecialAlways: true,
                    onChanged: (value) {
                      _rodoviaCtrl.text = value ?? '';
                      _emitChange();
                      setState(() {});
                    },
                    onCreateNewItem: (!widget.isEditable || _companyId == null)
                        ? null
                        : (label) async {
                      final created = await systemCubit.createRoad(_companyId!, label);
                      if (created != null) {
                        _rodoviaCtrl.text = created.label;
                        _emitChange();
                        setState(() {});
                      }
                    },
                    onEditItem: (widget.isEditable && _companyId != null)
                        ? (oldLabel, newLabel) async {
                      final list = systemCubit.getRoadsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (r) => r.label == oldLabel,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      final updated = await systemCubit.updateRoadName(_companyId!, target.id, newLabel);
                      if (updated != null && _rodoviaCtrl.text == oldLabel) {
                        setState(() => _rodoviaCtrl.text = updated.label);
                        _emitChange();
                      }
                    }
                        : null,
                    onDeleteItem: (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list = systemCubit.getRoadsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (r) => r.label == label,
                        orElse: () => list.first,
                      );

                      if (target.id.isEmpty) return;

                      await systemCubit.deleteRoad(_companyId!, target.id);

                      if (_rodoviaCtrl.text == label) {
                        setState(() => _rodoviaCtrl.clear());
                        _emitChange();
                      }
                    }
                        : null,
                  ),
                ),

                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _extensaoKmCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Extensão (km)',
                    hintText: 'Ex.: 12,34',
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    validator: null,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _descricaoObjetoCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    labelText: 'Nome da demanda',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _valorDemandaCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Valor da demanda (R\$)',
                    hintText: 'Ex.: 1.234,56',
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]'))],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
                    validator: null,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                SizedBox(
                  width: inputW1(context, inner),
                  child: CustomTextField(
                    controller: _justificativaCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    labelText: 'Justificativa da contratação (problema/objetivo)',
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
