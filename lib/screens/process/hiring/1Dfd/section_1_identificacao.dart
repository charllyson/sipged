// lib/screens/process/hiring/1Dfd/section_1_identificacao.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/process/hiring/0Stages/hiring_data.dart';
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
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

class SectionIdentificacao extends StatefulWidget {
  final bool isEditable;
  final DfdData data;

  /// Chamado sempre que algum campo é alterado.
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
  // --- Controllers de texto baseados em DfdData ---
  late final TextEditingController _orgaoDemandanteCtrl;      // Contratante
  late final TextEditingController _unidadeSolicitanteCtrl;   // Unidade/Setor
  late final TextEditingController _solicitanteCtrl;          // Nome exibido
  late final TextEditingController _cpfSolicitanteCtrl;
  late final TextEditingController _cargoSolicitanteCtrl;
  late final TextEditingController _emailSolicitanteCtrl;
  late final TextEditingController _telefoneSolicitanteCtrl;
  late final TextEditingController _dataSolicitacaoCtrl;
  late final TextEditingController _numeroProcessoCtrl;       // mapeado em protocoloSei

  // --- Estados auxiliares (não pertencem diretamente ao DfdData) ---
  String? _companyId;
  String? _unitId;
  String? _naturezaIntervencao;
  String? _solicitanteUserId;
  String? _statusContrato; // <<< novo estado local para statusContrato

  int _companyNonce = 0; // força rebuild dos units quando muda contratante

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _orgaoDemandanteCtrl    = TextEditingController(text: d.orgaoDemandante);
    _unidadeSolicitanteCtrl = TextEditingController(text: d.unidadeSolicitante);
    _solicitanteCtrl        = TextEditingController(text: d.solicitanteNome);
    _cpfSolicitanteCtrl     = TextEditingController(text: d.solicitanteCpf);
    _cargoSolicitanteCtrl   = TextEditingController(text: d.solicitanteCargo);
    _emailSolicitanteCtrl   = TextEditingController(text: d.solicitanteEmail);
    _telefoneSolicitanteCtrl= TextEditingController(text: d.solicitanteTelefone);
    _dataSolicitacaoCtrl    = TextEditingController(text: d.dataSolicitacao);
    _numeroProcessoCtrl     = TextEditingController(text: d.processoAdministrativo);

    _naturezaIntervencao = d.naturezaIntervencao;
    _solicitanteUserId   = d.solicitanteUserId;
    _statusContrato      = d.statusDemanda; // inicializa a partir do DfdData
  }

  @override
  void didUpdateWidget(covariant SectionIdentificacao oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      _orgaoDemandanteCtrl.text    = d.orgaoDemandante;
      _unidadeSolicitanteCtrl.text = d.unidadeSolicitante;
      _solicitanteCtrl.text        = d.solicitanteNome;
      _cpfSolicitanteCtrl.text     = d.solicitanteCpf;
      _cargoSolicitanteCtrl.text   = d.solicitanteCargo;
      _emailSolicitanteCtrl.text   = d.solicitanteEmail;
      _telefoneSolicitanteCtrl.text= d.solicitanteTelefone;
      _dataSolicitacaoCtrl.text    = d.dataSolicitacao;
      _numeroProcessoCtrl.text     = d.processoAdministrativo;

      _naturezaIntervencao = d.naturezaIntervencao;
      _solicitanteUserId   = d.solicitanteUserId;
      _statusContrato      = d.statusDemanda;
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
    _numeroProcessoCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      orgaoDemandante:    _orgaoDemandanteCtrl.text,
      unidadeSolicitante: _unidadeSolicitanteCtrl.text,
      solicitanteNome:    _solicitanteCtrl.text,
      solicitanteUserId:  _solicitanteUserId,
      solicitanteCpf:     _cpfSolicitanteCtrl.text,
      solicitanteCargo:   _cargoSolicitanteCtrl.text,
      solicitanteEmail:   _emailSolicitanteCtrl.text,
      solicitanteTelefone:_telefoneSolicitanteCtrl.text,
      dataSolicitacao:    _dataSolicitacaoCtrl.text,
      numeroProcessoContratacao:       _numeroProcessoCtrl.text,
      naturezaIntervencao:_naturezaIntervencao ?? '',
      statusContrato:     _statusContrato, // <<< grava no DfdData
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('1) Identificação da Demanda'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // ─────────── Contratante (orgão demandante) ───────────
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    width: w4,
                    labelText: 'Contratante',
                    controller: _orgaoDemandanteCtrl,
                    enabled: widget.isEditable,
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
                    greyItems: const {},
                    selectedId: _companyId,
                    onChangedIdLabel: (id, label) {
                      _companyId = id;
                      _companyNonce++;
                      _orgaoDemandanteCtrl.text = label;
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // ─────────── Unidade/Setor ───────────
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    key: ValueKey('units-$_companyNonce-${_companyId ?? "none"}'),
                    width: w4,
                    tooltipMessage:
                    _companyId == null ? 'Selecione o contratante' : null,
                    labelText: 'Unidade/Setor solicitante',
                    controller: _unidadeSolicitanteCtrl,
                    items: const [],
                    enabled: widget.isEditable && _companyId != null,
                    validator: validateRequired,
                    firestore: FirebaseFirestore.instance,
                    collectionPath: _companyId == null
                        ? null
                        : 'companies/${_companyId}/units',
                    labelField: 'unitName',
                    idField: 'unitId',
                    autoLoadWhenEmpty: true,
                    allowDuplicates: false,
                    selectedId: _unitId,
                    onChangedIdLabel: (id, label) {
                      _unitId = id;
                      _unidadeSolicitanteCtrl.text = label;
                      _emitChange();
                      setState(() {});
                    },
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

                // ─────────── Status do contrato (ligado a DfdData.statusContrato) ───────────
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    width: w4,
                    labelText: 'Status do contrato',
                    controller: TextEditingController(
                      text: _statusContrato ?? '',
                    ),
                    items: HiringData.statusTypes,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (v) {
                      _statusContrato = v?.isEmpty == true ? null : v;
                      _emitChange();
                      setState(() {});
                    },
                  ),
                ),

                // ─────────── Solicitante (usuário responsável) ───────────
                SizedBox(
                  width: w4,
                  child: AutocompleteUserClass(
                    label: 'Solicitante (responsável pela demanda)',
                    controller: _solicitanteCtrl,
                    allUsers: users,
                    enabled: widget.isEditable,
                    initialUserId: _solicitanteUserId,
                    validator: validateRequired,
                    onChanged: (userId) {
                      _solicitanteUserId = userId;
                      _emitChange();
                    },
                  ),
                ),

                // ─────────── Nº do processo ───────────
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _numeroProcessoCtrl,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    labelText: 'Nº do processo (SEI/Interno)',
                    keyboardType: TextInputType.text,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ─────────── Natureza da intervenção ───────────
                SizedBox(
                  width: w4,
                  child: DropDownButtonChange(
                    key: ValueKey('natureza-${_naturezaIntervencao ?? ""}'),
                    enabled: widget.isEditable,
                    labelText: 'Natureza da intervenção',
                    controller: TextEditingController(
                      text: _naturezaIntervencao ?? '',
                    ),
                    items: HiringData.typeOfService,
                    onChanged: (v) {
                      _naturezaIntervencao = v ?? '';
                      _emitChange();
                      setState(() {});
                    },
                    validator: validateRequired,
                  ),
                ),

                // ─────────── CPF do solicitante ───────────
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cpfSolicitanteCtrl,
                    validator: validateRequired,
                    enabled: widget.isEditable,
                    labelText: 'CPF do solicitante',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      TextInputMask(mask: '999.999.999-99'),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ─────────── Cargo/Função ───────────
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _cargoSolicitanteCtrl,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    labelText: 'Cargo/Função',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ─────────── E-mail institucional ───────────
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _emailSolicitanteCtrl,
                    enabled: widget.isEditable,
                    validator: validateEmail,
                    labelText: 'E-mail institucional',
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ─────────── Telefone ───────────
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _telefoneSolicitanteCtrl,
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    labelText: 'Telefone do solicitante',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      TextInputMask(mask: '(99) 99999-9999'),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ─────────── Data da solicitação ───────────
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
        const SizedBox(height: 16),
      ],
    );
  }
}
