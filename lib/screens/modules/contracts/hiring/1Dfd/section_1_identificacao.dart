// lib/screens/modules/contracts/hiring/1Dfd/section_1_identificacao.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

import 'package:siged/_blocs/system/setup/setup_cubit.dart';

import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionIdentificacao extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;

  const SectionIdentificacao({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
  });

  @override
  State<SectionIdentificacao> createState() => _SectionIdentificacaoState();
}

class _SectionIdentificacaoState extends State<SectionIdentificacao>
    with FormValidationMixin {
  // Controllers (labels)
  late final TextEditingController _orgaoDemandanteCtrl;
  late final TextEditingController _unidadeSolicitanteCtrl;
  late final TextEditingController _solicitanteCtrl;
  late final TextEditingController _cpfSolicitanteCtrl;
  late final TextEditingController _cargoSolicitanteCtrl;
  late final TextEditingController _emailSolicitanteCtrl;
  late final TextEditingController _telefoneSolicitanteCtrl;
  late final TextEditingController _dataSolicitacaoCtrl;
  late final TextEditingController _processoAdministrativoCtrl;

  late final TextEditingController _statusContratoCtrl;
  late final TextEditingController _naturezaIntervencaoCtrl;

  // IDs de Setup (fonte de verdade)
  String? _companyId; // docId do company
  String? _unitId; // docId da unidade

  // IDs “semânticos” do DFD (ids próprios do modelo)
  String? _orgaoDemandanteId; // espelha companyId
  String? _unidadeSolicitanteId; // espelha unitId

  // Demais estados
  String? _naturezaIntervencao;
  String? _solicitanteUserId;
  String? _statusContrato;

  int _companyNonce = 0;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _orgaoDemandanteCtrl = TextEditingController(text: d.orgaoDemandante ?? '');
    _unidadeSolicitanteCtrl =
        TextEditingController(text: d.unidadeSolicitante ?? '');

    _solicitanteCtrl = TextEditingController(text: d.solicitanteNome ?? '');
    _cpfSolicitanteCtrl = TextEditingController(text: d.solicitanteCpf ?? '');
    _cargoSolicitanteCtrl =
        TextEditingController(text: d.solicitanteCargo ?? '');
    _emailSolicitanteCtrl =
        TextEditingController(text: d.solicitanteEmail ?? '');
    _telefoneSolicitanteCtrl =
        TextEditingController(text: d.solicitanteTelefone ?? '');
    _dataSolicitacaoCtrl =
        TextEditingController(text: _formatDate(d.dataSolicitacao));

    _processoAdministrativoCtrl =
        TextEditingController(text: d.processoAdministrativo ?? '');

    _statusContrato = d.statusDemanda;
    _naturezaIntervencao = d.naturezaIntervencao;
    _solicitanteUserId = d.solicitanteUserId;

    _statusContratoCtrl = TextEditingController(text: _statusContrato ?? '');
    _naturezaIntervencaoCtrl =
        TextEditingController(text: _naturezaIntervencao ?? '');

    // ✅ IDs já persistidos no DFD
    _companyId = d.companyId;
    _unitId = d.unitId;

    // ✅ espelha também nos campos “semânticos”
    _orgaoDemandanteId = d.orgaoDemandanteId ?? _companyId;
    _unidadeSolicitanteId = d.unidadeSolicitanteId ?? _unitId;

    final systemCubit = context.read<SetupCubit>();
    systemCubit.loadCompanies();

    if ((_companyId ?? '').isNotEmpty) {
      systemCubit.ensureCompanySetupLoaded(_companyId!);
    }

    // Auto-preencher solicitante se vazio e houver usuário logado (opcional)
    if ((_solicitanteUserId ?? '').isEmpty &&
        (FirebaseAuth.instance.currentUser?.uid ?? '').isNotEmpty) {
      _solicitanteUserId = FirebaseAuth.instance.currentUser!.uid;
    }
  }

  @override
  void didUpdateWidget(covariant SectionIdentificacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    void _sync(TextEditingController c, String? newText) {
      final v = newText ?? '';
      if (c.text != v) c.text = v;
    }

    _sync(_orgaoDemandanteCtrl, d.orgaoDemandante);
    _sync(_unidadeSolicitanteCtrl, d.unidadeSolicitante);
    _sync(_solicitanteCtrl, d.solicitanteNome);
    _sync(_cpfSolicitanteCtrl, d.solicitanteCpf);
    _sync(_cargoSolicitanteCtrl, d.solicitanteCargo);
    _sync(_emailSolicitanteCtrl, d.solicitanteEmail);
    _sync(_telefoneSolicitanteCtrl, d.solicitanteTelefone);
    _sync(_dataSolicitacaoCtrl, _formatDate(d.dataSolicitacao));
    _sync(_processoAdministrativoCtrl, d.processoAdministrativo);

    _statusContrato = d.statusDemanda;
    _naturezaIntervencao = d.naturezaIntervencao;
    _solicitanteUserId = d.solicitanteUserId;

    _sync(_statusContratoCtrl, _statusContrato);
    _sync(_naturezaIntervencaoCtrl, _naturezaIntervencao);

    final oldCompanyId = _companyId;

    _companyId = d.companyId;
    _unitId = d.unitId;

    _orgaoDemandanteId = d.orgaoDemandanteId ?? _companyId;
    _unidadeSolicitanteId = d.unidadeSolicitanteId ?? _unitId;

    if (oldCompanyId != _companyId && (_companyId ?? '').isNotEmpty) {
      context.read<SetupCubit>().ensureCompanySetupLoaded(_companyId!);
      _companyNonce++;
    }
  }

  @override
  void dispose() {
    _orgaoDemandanteCtrl.dispose();
    _unidadeSolicitanteCtrl.dispose();
    _solicitanteCtrl.dispose();
    _cpfSolicitanteCtrl.dispose();
    _cargoSolicitanteCtrl.dispose();
    _emailSolicitanteCtrl.dispose();
    _telefoneSolicitanteCtrl.dispose();
    _dataSolicitacaoCtrl.dispose();
    _processoAdministrativoCtrl.dispose();
    _statusContratoCtrl.dispose();
    _naturezaIntervencaoCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  DateTime? _parseBrDate(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    try {
      final parts = t.split('/');
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
      return DateTime.parse(t);
    } catch (_) {
      return null;
    }
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      // labels
      orgaoDemandante: _orgaoDemandanteCtrl.text,
      unidadeSolicitante: _unidadeSolicitanteCtrl.text,

      // ✅ IDs corretos e persistidos
      companyId: _companyId,
      unitId: _unitId,
      orgaoDemandanteId: _orgaoDemandanteId ?? _companyId,
      unidadeSolicitanteId: _unidadeSolicitanteId ?? _unitId,

      solicitanteNome: _solicitanteCtrl.text,
      solicitanteUserId: _solicitanteUserId,
      solicitanteCpf: _cpfSolicitanteCtrl.text,
      solicitanteCargo: _cargoSolicitanteCtrl.text,
      solicitanteEmail: _emailSolicitanteCtrl.text,
      solicitanteTelefone: _telefoneSolicitanteCtrl.text,

      dataSolicitacao: _parseBrDate(_dataSolicitacaoCtrl.text),
      processoAdministrativo: _processoAdministrativoCtrl.text,

      naturezaIntervencao: _naturezaIntervencao ?? '',
      statusDemanda: _statusContrato,
    );

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    final systemCubit = context.read<SetupCubit>();
    final systemState = context.watch<SetupCubit>().state;

    final companies = systemState.companies;
    final units = systemCubit.getUnitsForCompany(_companyId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '1) Identificação da Demanda'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Contratante
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    width: w4,
                    labelText: 'Contratante',
                    controller: _orgaoDemandanteCtrl,
                    enabled: widget.isEditable,
                    validator: (v) => widget.isEditable
                        ? validateDropdown(v,
                        message: 'Selecione o contratante')
                        : null,
                    items: companies.map((e) => e.label).toList(),
                    specialItemLabel: 'Adicionar contratante',
                    menuMaxHeight: 260,
                    onChanged: (label) async {
                      if (label == null || label.isEmpty) {
                        setState(() {
                          _companyId = null;
                          _unitId = null;
                          _orgaoDemandanteId = null;
                          _unidadeSolicitanteId = null;
                          _unidadeSolicitanteCtrl.clear();
                          _orgaoDemandanteCtrl.clear();
                          _companyNonce++;
                        });
                        _emitChange();
                        return;
                      }

                      final selected = companies.firstWhere(
                            (c) => c.label == label,
                        orElse: () => companies.first,
                      );

                      final selectedCompanyId = selected.id;

                      setState(() {
                        _companyId = selectedCompanyId;
                        _orgaoDemandanteId = selectedCompanyId;
                        _orgaoDemandanteCtrl.text = selected.label;

                        _companyNonce++;
                        _unidadeSolicitanteCtrl.clear();
                        _unitId = null;
                        _unidadeSolicitanteId = null;
                      });

                      await systemCubit
                          .ensureCompanySetupLoaded(selectedCompanyId);
                      _emitChange();
                    },
                    onCreateNewItem: widget.isEditable
                        ? (label) async {
                      final created =
                      await systemCubit.createCompany(label);
                      if (created == null) return;

                      final createdCompanyId = created.id;

                      setState(() {
                        _companyId = createdCompanyId;
                        _orgaoDemandanteId = createdCompanyId;
                        _orgaoDemandanteCtrl.text = created.label;

                        _companyNonce++;
                        _unidadeSolicitanteCtrl.clear();
                        _unitId = null;
                        _unidadeSolicitanteId = null;
                      });

                      await systemCubit
                          .ensureCompanySetupLoaded(createdCompanyId);
                      _emitChange();
                    }
                        : null,
                    onEditItem: widget.isEditable
                        ? (oldLabel, newLabel) async {
                      final list = systemCubit.state.companies;
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (c) => c.label == oldLabel,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      final updated = await systemCubit
                          .updateCompanyName(id, newLabel);
                      if (updated != null && _companyId == id) {
                        setState(() =>
                        _orgaoDemandanteCtrl.text = updated.label);
                        _emitChange();
                      }
                    }
                        : null,
                    onDeleteItem: widget.isEditable
                        ? (ctx, label) async {
                      final list = systemCubit.state.companies;
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (c) => c.label == label,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      await systemCubit.deleteCompany(id);

                      if (_companyId == id) {
                        setState(() {
                          _companyId = null;
                          _unitId = null;
                          _orgaoDemandanteId = null;
                          _unidadeSolicitanteId = null;
                          _orgaoDemandanteCtrl.clear();
                          _unidadeSolicitanteCtrl.clear();
                          _companyNonce++;
                        });
                        _emitChange();
                      }
                    }
                        : null,
                  ),
                ),

                // Unidade/Setor
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    key: ValueKey(
                        'units-$_companyNonce-${_companyId ?? "none"}'),
                    width: w4,
                    tooltipMessage:
                    _companyId == null ? 'Selecione o contratante' : null,
                    labelText: 'Unidade/Setor solicitante',
                    controller: _unidadeSolicitanteCtrl,
                    enabled: widget.isEditable && _companyId != null,
                    validator: null,
                    showSpecialAlways: true,
                    specialItemLabel: 'Adicionar unidade',
                    items: units.map((e) => e.label).toList(),
                    onChanged: (label) async {
                      if (label == null || label.isEmpty) {
                        setState(() {
                          _unitId = null;
                          _unidadeSolicitanteId = null;
                        });
                        _emitChange();
                        return;
                      }

                      final selected = units.firstWhere(
                            (u) => u.label == label,
                        orElse: () => units.first,
                      );

                      final selectedUnitId = selected.id;

                      setState(() {
                        _unitId = selectedUnitId;
                        _unidadeSolicitanteId = selectedUnitId;
                        _unidadeSolicitanteCtrl.text = selected.label;
                      });

                      _emitChange();
                    },
                    onCreateNewItem: (widget.isEditable && _companyId != null)
                        ? (label) async {
                      final created = await systemCubit.createUnit(
                          _companyId!, label);
                      if (created == null) return;

                      final createdUnitId = created.id;

                      setState(() {
                        _unitId = createdUnitId;
                        _unidadeSolicitanteId = createdUnitId;
                        _unidadeSolicitanteCtrl.text = created.label;
                      });

                      _emitChange();
                    }
                        : null,
                    onEditItem: (widget.isEditable && _companyId != null)
                        ? (oldLabel, newLabel) async {
                      final list =
                      systemCubit.getUnitsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (u) => u.label == oldLabel,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      final updated = await systemCubit.updateUnitName(
                          _companyId!, id, newLabel);
                      if (updated != null && _unitId == id) {
                        setState(() => _unidadeSolicitanteCtrl.text =
                            updated.label);
                        _emitChange();
                      }
                    }
                        : null,
                    onDeleteItem: (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list =
                      systemCubit.getUnitsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (u) => u.label == label,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      await systemCubit.deleteUnit(_companyId!, id);

                      if (_unitId == id) {
                        setState(() {
                          _unitId = null;
                          _unidadeSolicitanteId = null;
                          _unidadeSolicitanteCtrl.clear();
                        });
                        _emitChange();
                      }
                    }
                        : null,
                  ),
                ),

                // Status do contrato
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    width: w4,
                    labelText: 'Status do contrato',
                    controller: _statusContratoCtrl,
                    items: HiringData.statusTypes,
                    enabled: widget.isEditable,
                    validator: null,
                    onChanged: (v) {
                      _statusContrato = (v == null || v.isEmpty) ? null : v;
                      _statusContratoCtrl.text = _statusContrato ?? '';
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // ✅ Solicitante (agora genérico)
                SizedBox(
                  width: w4,
                  child: CustomAutoComplete<UserData>(
                    label: 'Solicitante (responsável pela demanda)',
                    controller: _solicitanteCtrl,
                    allList: users,
                    enabled: widget.isEditable,
                    initialId: _solicitanteUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    validator: (value) {
                      if (!widget.isEditable) return null;
                      // o widget valida por ID internamente; basta exigir seleção.
                      return (_solicitanteUserId ?? '').isNotEmpty
                          ? null
                          : 'Selecione o solicitante';
                    },
                    onChanged: (userId) {
                      _solicitanteUserId = userId;
                      _emitChange();
                    },
                  ),
                ),

                // Processo
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _processoAdministrativoCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    labelText: 'Nº do processo (SEI/Interno)',
                    keyboardType: TextInputType.text,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Natureza
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    key: ValueKey('natureza-${_naturezaIntervencao ?? ""}'),
                    enabled: widget.isEditable,
                    labelText: 'Natureza da intervenção',
                    controller: _naturezaIntervencaoCtrl,
                    items: HiringData.typeOfService,
                    validator: (v) => widget.isEditable
                        ? validateDropdown(v,
                        message: 'Informe a natureza da intervenção')
                        : null,
                    onChanged: (v) {
                      _naturezaIntervencao = v ?? '';
                      _naturezaIntervencaoCtrl.text = _naturezaIntervencao ?? '';
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // CPF
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cpfSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'CPF do solicitante',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Cargo
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cargoSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Cargo do solicitante',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Email
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _emailSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'E-mail do solicitante',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Telefone
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _telefoneSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Telefone do solicitante',
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Data Solicitação
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _dataSolicitacaoCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Data da solicitação',
                    onChanged: (_) => _emitChange(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
