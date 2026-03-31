import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Users
import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';

// ===== Inputs / Layout
import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_widgets/input/auto_complete_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';

// ===== Data
import 'package:sipged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_data.dart';

class SectionMetadadosTA extends StatefulWidget {
  final TermoArquivamentoData data;
  final bool isEditable;
  final void Function(TermoArquivamentoData updated) onChanged;

  const SectionMetadadosTA({
    super.key,
    required this.data,
    required this.isEditable,
    required this.onChanged,
  });

  @override
  State<SectionMetadadosTA> createState() => _SectionMetadadosTAState();
}

class _SectionMetadadosTAState extends State<SectionMetadadosTA>
    with SipGedValidation {
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _dataCtrl;
  late final TextEditingController _processoCtrl;
  late final TextEditingController _responsavelCtrl;

  String? _responsavelUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _numeroCtrl = TextEditingController(text: d.taNumero ?? '');
    _dataCtrl = TextEditingController(text: d.taData ?? '');
    _processoCtrl = TextEditingController(text: d.taProcesso ?? '');

    // texto é só UI; o modelo guarda o ID
    _responsavelCtrl = TextEditingController();
    _responsavelUserId = d.taResponsavelUserId;
  }

  @override
  void didUpdateWidget(covariant SectionMetadadosTA oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_numeroCtrl, d.taNumero);
      sync(_dataCtrl, d.taData);
      sync(_processoCtrl, d.taProcesso);

      _responsavelUserId = d.taResponsavelUserId;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _dataCtrl.dispose();
    _processoCtrl.dispose();
    _responsavelCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      taNumero: _numeroCtrl.text,
      taData: _dataCtrl.text,
      taProcesso: _processoCtrl.text,
      taResponsavelUserId: _responsavelUserId,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = context.select<UserBloc, List<UserData>>((b) => b.state.all);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '1) Metadados'),
        LayoutBuilder(
          builder: (context, constraints) {
            final w4 = inputW4(context, constraints);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _numeroCtrl,
                    labelText: 'Nº do Termo',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _dataCtrl,
                    labelText: 'Data',
                    hintText: 'dd/mm/aaaa',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      SipGedMasks.dateDDMMYYYY,
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _processoCtrl,
                    labelText: 'Nº do processo (SEI/Interno)',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ✅ Responsável (genérico) + validação por ID
                SizedBox(
                  width: w4,
                  child: AutoCompleteChange<UserData>(
                    label: 'Responsável pelo termo',
                    controller: _responsavelCtrl,
                    allList: users,
                    enabled: widget.isEditable,
                    initialId: _responsavelUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    validator: (v) {
                      if (!widget.isEditable) return null;
                      return (_responsavelUserId ?? '').isNotEmpty
                          ? null
                          : 'Campo obrigatório';
                    },
                    onChanged: (id) {
                      _responsavelUserId = id.isEmpty ? null : id;
                      _emitChange();
                    },
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
