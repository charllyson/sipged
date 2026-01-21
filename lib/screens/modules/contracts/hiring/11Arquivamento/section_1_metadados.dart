import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ===== Users
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

// ===== Inputs / Layout
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

// ===== Data
import 'package:siged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_data.dart';

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
    with FormValidationMixin {
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

      void _sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      _sync(_numeroCtrl, d.taNumero);
      _sync(_dataCtrl, d.taData);
      _sync(_processoCtrl, d.taProcesso);

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
                      TextInputMask(mask: '99/99/9999'),
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
                  child: CustomAutoComplete<UserData>(
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
