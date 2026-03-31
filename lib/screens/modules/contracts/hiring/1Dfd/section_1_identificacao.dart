import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/0Stages/hiring_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';

import 'package:sipged/_utils/formats/sipged_format_numbers.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';

import 'package:sipged/_widgets/input/auto_complete_change.dart';
import 'package:sipged/_widgets/input/date_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

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
    with SipGedValidation {
  late final TextEditingController _orgaoDemandanteCtrl;
  late final TextEditingController _unidadeSolicitanteCtrl;

  late final TextEditingController _solicitanteCtrl;
  late final TextEditingController _cpfSolicitanteCtrl;
  late final TextEditingController _cargoSolicitanteCtrl;
  late final TextEditingController _emailSolicitanteCtrl;
  late final TextEditingController _telefoneSolicitanteCtrl;

  late final TextEditingController _processoAdministrativoCtrl;

  late final TextEditingController _statusContratoCtrl;
  late final TextEditingController _naturezaIntervencaoCtrl;

  String? _companyId;
  String? _unitId;

  String? _orgaoDemandanteId;
  String? _unidadeSolicitanteId;

  String? _naturezaIntervencao;
  String? _solicitanteUserId;
  String? _statusContrato;

  DateTime? _dataSolicitacao;

  int _companyNonce = 0;
  bool _syncing = false;

  static const String _cpfMask = '999.999.999-99';
  static const String _phoneMask = '(99) 99999-9999';

  @override
  void initState() {
    super.initState();

    final d = widget.data;

    _orgaoDemandanteCtrl = TextEditingController(text: d.orgaoDemandante ?? '');
    _unidadeSolicitanteCtrl =
        TextEditingController(text: d.unidadeSolicitante ?? '');

    _solicitanteCtrl = TextEditingController(text: d.solicitanteNome ?? '');

    // CPF do banco: puro -> controller: formatado
    final cpfDigitsInit = (d.solicitanteCpf ?? '').replaceAll(RegExp(r'\D'), '');
    final cpfTextInit = cpfDigitsInit.length == 11
        ? SipGedFormatNumbers.formatCPF(cpfDigitsInit)
        : (d.solicitanteCpf ?? '');
    _cpfSolicitanteCtrl = TextEditingController(text: cpfTextInit);

    _cargoSolicitanteCtrl =
        TextEditingController(text: d.solicitanteCargo ?? '');
    _emailSolicitanteCtrl =
        TextEditingController(text: d.solicitanteEmail ?? '');

    // ✅ TELEFONE: banco (puro ou formatado) -> controller: sempre mascarado
    final phoneDigitsInit =
    (d.solicitanteTelefone ?? '').replaceAll(RegExp(r'\D'), '');
    final phoneTextInit = phoneDigitsInit.isEmpty
        ? ''
        : _applyMask(_phoneMask, phoneDigitsInit);
    _telefoneSolicitanteCtrl = TextEditingController(text: phoneTextInit);

    _processoAdministrativoCtrl =
        TextEditingController(text: d.processoAdministrativo ?? '');

    _statusContrato = d.statusDemanda;
    _naturezaIntervencao = d.naturezaIntervencao;
    _solicitanteUserId = d.solicitanteUserId;
    _dataSolicitacao = d.dataSolicitacao;

    _statusContratoCtrl = TextEditingController(text: _statusContrato ?? '');
    _naturezaIntervencaoCtrl =
        TextEditingController(text: _naturezaIntervencao ?? '');

    _companyId = _normalizeId(d.companyId);
    _unitId = _normalizeId(d.unitId);

    _orgaoDemandanteId = _normalizeId(d.orgaoDemandanteId) ?? _companyId;
    _unidadeSolicitanteId = _normalizeId(d.unidadeSolicitanteId) ?? _unitId;

    final setup = context.read<SetupCubit>();
    setup.loadCompanies();
    if ((_companyId ?? '').isNotEmpty) {
      setup.ensureCompanySetupLoaded(_companyId!);
    }
  }

  @override
  void didUpdateWidget(covariant SectionIdentificacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data == widget.data) return;

    final d = widget.data;

    _syncControllerText(_orgaoDemandanteCtrl, d.orgaoDemandante ?? '');
    _syncControllerText(_unidadeSolicitanteCtrl, d.unidadeSolicitante ?? '');
    _syncControllerText(_solicitanteCtrl, d.solicitanteNome ?? '');

    // ✅ CPF: sincroniza por dígitos + preserva cursor (igual processo)
    final incomingCpfDigits =
    (d.solicitanteCpf ?? '').replaceAll(RegExp(r'\D'), '');
    _syncMaskedController(_cpfSolicitanteCtrl, incomingCpfDigits, _cpfMask);

    _syncControllerText(_cargoSolicitanteCtrl, d.solicitanteCargo ?? '');
    _syncControllerText(_emailSolicitanteCtrl, d.solicitanteEmail ?? '');

    // ✅ TELEFONE: sincroniza por dígitos + preserva cursor (igual processo)
    final incomingPhoneDigits =
    (d.solicitanteTelefone ?? '').replaceAll(RegExp(r'\D'), '');
    _syncMaskedController(
      _telefoneSolicitanteCtrl,
      incomingPhoneDigits,
      _phoneMask,
    );

    _syncControllerText(
      _processoAdministrativoCtrl,
      d.processoAdministrativo ?? '',
    );

    _statusContrato = d.statusDemanda;
    _naturezaIntervencao = d.naturezaIntervencao;
    _solicitanteUserId = d.solicitanteUserId;
    _dataSolicitacao = d.dataSolicitacao;

    _syncControllerText(_statusContratoCtrl, _statusContrato ?? '');
    _syncControllerText(_naturezaIntervencaoCtrl, _naturezaIntervencao ?? '');

    final oldCompanyId = _companyId;

    _companyId = _normalizeId(d.companyId);
    _unitId = _normalizeId(d.unitId);

    _orgaoDemandanteId = _normalizeId(d.orgaoDemandanteId) ?? _companyId;
    _unidadeSolicitanteId = _normalizeId(d.unidadeSolicitanteId) ?? _unitId;

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
    _processoAdministrativoCtrl.dispose();
    _statusContratoCtrl.dispose();
    _naturezaIntervencaoCtrl.dispose();
    super.dispose();
  }

  String? _normalizeId(String? v) {
    final s = (v ?? '').trim();
    return s.isEmpty ? null : s;
  }

  void _syncControllerText(TextEditingController c, String v) {
    if (c.text == v) return;

    final oldSel = c.selection;
    _syncing = true;
    c.text = v;

    final newLen = c.text.length;
    int base = oldSel.baseOffset;
    int extent = oldSel.extentOffset;

    if (base < 0 || extent < 0) {
      c.selection = TextSelection.collapsed(offset: newLen);
    } else {
      base = base.clamp(0, newLen);
      extent = extent.clamp(0, newLen);
      c.selection = TextSelection(baseOffset: base, extentOffset: extent);
    }

    _syncing = false;
  }

  // ======= Máscara (CPF/Telefone): sync por dígitos + preserva cursor =======

  static bool _isPlaceholder(String ch) => ch == '9' || ch == '#';

  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static int _countDigitsBefore(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    int count = 0;
    for (int i = 0; i < safeCursor; i++) {
      final cu = text.codeUnitAt(i);
      if (cu >= 48 && cu <= 57) count++;
    }
    return count;
  }

  static String _applyMask(String mask, String digits) {
    final buf = StringBuffer();
    var di = 0;

    for (int i = 0; i < mask.length && di < digits.length; i++) {
      final m = mask[i];
      if (_isPlaceholder(m)) {
        buf.write(digits[di++]);
      } else {
        buf.write(m);
      }
    }
    return buf.toString();
  }

  static int _cursorPosForDigitsCount(String formatted, int digitsCount) {
    if (digitsCount <= 0) return 0;

    int seen = 0;
    for (int i = 0; i < formatted.length; i++) {
      final cu = formatted.codeUnitAt(i);
      if (cu >= 48 && cu <= 57) {
        seen++;
        if (seen == digitsCount) return i + 1;
      }
    }
    return formatted.length;
  }

  void _syncMaskedController(
      TextEditingController c,
      String incomingDigits,
      String mask,
      ) {
    final currentDigits = _onlyDigits(c.text);
    if (currentDigits == incomingDigits) return;

    final oldText = c.text;
    final oldCursor = c.selection.extentOffset;

    final digitsBefore = _countDigitsBefore(oldText, oldCursor);

    final formatted = _applyMask(mask, incomingDigits);
    final newCursor = _cursorPosForDigitsCount(formatted, digitsBefore);

    _syncing = true;
    c.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursor.clamp(0, formatted.length),
      ),
      composing: TextRange.empty,
    );
    _syncing = false;
  }

  void _emitChange() {
    // ✅ salva PURO (só dígitos)
    final cpfDigits = _cpfSolicitanteCtrl.text.replaceAll(RegExp(r'\D'), '');
    final phoneDigits =
    _telefoneSolicitanteCtrl.text.replaceAll(RegExp(r'\D'), '');

    final updated = widget.data.copyWith(
      orgaoDemandante: _orgaoDemandanteCtrl.text,
      unidadeSolicitante: _unidadeSolicitanteCtrl.text,

      companyId: _companyId,
      unitId: _unitId,
      orgaoDemandanteId: _orgaoDemandanteId ?? _companyId,
      unidadeSolicitanteId: _unidadeSolicitanteId ?? _unitId,

      solicitanteNome: _solicitanteCtrl.text,
      solicitanteUserId: _solicitanteUserId,
      solicitanteCpf: cpfDigits,
      solicitanteCargo: _cargoSolicitanteCtrl.text,
      solicitanteEmail: _emailSolicitanteCtrl.text,

      // ✅ telefone salvo puro
      solicitanteTelefone: phoneDigits,

      dataSolicitacao: _dataSolicitacao,
      processoAdministrativo: _processoAdministrativoCtrl.text,

      naturezaIntervencao: _naturezaIntervencao ?? '',
      statusDemanda: _statusContrato,
    );

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    final setupCubit = context.read<SetupCubit>();
    final setupState = context.watch<SetupCubit>().state;

    final companies = setupState.companies;
    final List<SetupData> units = setupCubit.getUnitsForCompany(_companyId);

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
                SizedBox(
                  width: w4,
                  child: DropDownChange(
                    width: w4,
                    labelText: 'Contratante',
                    controller: _orgaoDemandanteCtrl,
                    enabled: widget.isEditable,
                    validator: (v) => widget.isEditable
                        ? validateDropdown(v, message: 'Selecione o contratante')
                        : null,
                    items: companies.map((e) => e.label).toList(),
                    specialItemLabel: 'Adicionar contratante',
                    menuMaxHeight: 260,
                    onChanged: (label) async {
                      if (!widget.isEditable) return;

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

                      await setupCubit.ensureCompanySetupLoaded(selectedCompanyId);
                      _emitChange();
                    },
                    onCreateNewItem: widget.isEditable
                        ? (label) async {
                      final created = await setupCubit.createCompany(label);
                      if (!mounted || created == null) return;

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

                      await setupCubit.ensureCompanySetupLoaded(createdCompanyId);
                      _emitChange();
                    }
                        : null,
                    onEditItem: widget.isEditable
                        ? (oldLabel, newLabel) async {
                      final list = setupCubit.state.companies;
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (c) => c.label == oldLabel,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      final updated = await setupCubit.updateCompanyName(
                        id,
                        newLabel,
                      );
                      if (!mounted) return;

                      if (updated != null && _companyId == id) {
                        setState(() => _orgaoDemandanteCtrl.text = updated.label);
                        _emitChange();
                      }
                    }
                        : null,
                    onDeleteItem: widget.isEditable
                        ? (ctx, label) async {
                      final list = setupCubit.state.companies;
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (c) => c.label == label,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      await setupCubit.deleteCompany(id);
                      if (!mounted) return;

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

                SizedBox(
                  width: w4,
                  child: DropDownChange(
                    key: ValueKey('units-$_companyNonce-${_companyId ?? "none"}'),
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
                      if (!widget.isEditable) return;

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
                      final created =
                      await setupCubit.createUnit(_companyId!, label);
                      if (!mounted || created == null) return;

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
                      final list = setupCubit.getUnitsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (u) => u.label == oldLabel,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      final updated = await setupCubit.updateUnitName(
                        _companyId!,
                        id,
                        newLabel,
                      );
                      if (!mounted) return;

                      if (updated != null && _unitId == id) {
                        setState(() => _unidadeSolicitanteCtrl.text = updated.label);
                        _emitChange();
                      }
                    }
                        : null,
                    onDeleteItem: (widget.isEditable && _companyId != null)
                        ? (ctx, label) async {
                      final list = setupCubit.getUnitsForCompany(_companyId);
                      if (list.isEmpty) return;

                      final target = list.firstWhere(
                            (u) => u.label == label,
                        orElse: () => list.first,
                      );

                      final id = target.id;
                      if (id.isEmpty) return;

                      await setupCubit.deleteUnit(_companyId!, id);
                      if (!mounted) return;

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

                SizedBox(
                  width: w4,
                  child: DropDownChange(
                    width: w4,
                    labelText: 'Status do contrato',
                    controller: _statusContratoCtrl,
                    items: HiringData.statusTypes,
                    enabled: widget.isEditable,
                    validator: null,
                    onChanged: (v) {
                      if (!widget.isEditable) return;
                      setState(() {
                        _statusContrato = (v == null || v.isEmpty) ? null : v;
                        _statusContratoCtrl.text = _statusContrato ?? '';
                      });
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: AutoCompleteChange<UserData>(
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
                      return (_solicitanteUserId ?? '').isNotEmpty
                          ? null
                          : 'Selecione o solicitante';
                    },
                    onChanged: (userId) {
                      if (!widget.isEditable) return;
                      _solicitanteUserId = userId;
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _processoAdministrativoCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    labelText: 'Nº do processo (SEI/Interno)',
                    keyboardType: TextInputType.text,
                    onChanged: (_) {
                      if (_syncing) return;
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: DropDownChange(
                    key: ValueKey('natureza-${_naturezaIntervencao ?? ""}'),
                    enabled: widget.isEditable,
                    labelText: 'Natureza da intervenção',
                    controller: _naturezaIntervencaoCtrl,
                    items: HiringData.typeOfService,
                    validator: (v) => widget.isEditable
                        ? validateDropdown(
                      v,
                      message: 'Informe a natureza da intervenção',
                    )
                        : null,
                    onChanged: (v) {
                      if (!widget.isEditable) return;
                      setState(() {
                        _naturezaIntervencao = v ?? '';
                        _naturezaIntervencaoCtrl.text = _naturezaIntervencao ?? '';
                      });
                      _emitChange();
                    },
                  ),
                ),

                // ✅ CPF: máscara + backspace em separador remove dígito (igual processo)
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cpfSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'CPF do solicitante',
                    hintText: '000.000.000-00',
                    keyboardType: TextInputType.number,
                    inputFormatters: const [
                      SipGedMasks.cpf,
                    ],
                    onChanged: (_) {
                      if (_syncing) return;
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cargoSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Cargo do solicitante',
                    onChanged: (_) {
                      if (_syncing) return;
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _emailSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'E-mail do solicitante',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      if (_syncing) return;
                      _emitChange();
                    },
                  ),
                ),

                // ✅ TELEFONE: máscara + backspace em separador remove dígito (igual processo)
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _telefoneSolicitanteCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Telefone do solicitante',
                    hintText: '(00) 00000-0000',
                    keyboardType: TextInputType.phone,
                    inputFormatters: const [
                      SipGedMasks.phoneBR, // ✅ precisa existir no seu sipged_masks.dart
                    ],
                    onChanged: (_) {
                      if (_syncing) return;
                      _emitChange();
                    },
                  ),
                ),

                SizedBox(
                  width: w4,
                  child: DateFieldChange(
                    enabled: widget.isEditable,
                    labelText: 'Data da solicitação',
                    initialValue: _dataSolicitacao,
                    onChanged: (dt) {
                      if (!widget.isEditable) return;
                      setState(() => _dataSolicitacao = dt);
                      _emitChange();
                    },
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
