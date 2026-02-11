import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:siged/_utils/mask/sipged_masks.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_utils/validates/sipged_validation.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_data.dart';

class SectionMetadados extends StatefulWidget {
  final ParecerJuridicoData data;
  final bool isEditable;
  final List<UserData> users;
  final void Function(ParecerJuridicoData updated) onChanged;

  const SectionMetadados({
    super.key,
    required this.data,
    required this.isEditable,
    required this.users,
    required this.onChanged,
  });

  @override
  State<SectionMetadados> createState() => _SectionMetadadosState();
}

class _SectionMetadadosState extends State<SectionMetadados>
    with SipGedValidation {
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _dataCtrl;
  late final TextEditingController _orgaoCtrl;
  late final TextEditingController _pareceristaNomeCtrl;

  String? _pareceristaUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _numeroCtrl = TextEditingController(text: d.numero ?? '');
    _dataCtrl = TextEditingController(text: d.data ?? '');
    _orgaoCtrl = TextEditingController(text: d.orgao ?? '');
    _pareceristaNomeCtrl = TextEditingController(text: d.pareceristaNome ?? '');
    _pareceristaUserId = d.pareceristaUserId;
  }

  @override
  void didUpdateWidget(covariant SectionMetadados oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;

      void sync(TextEditingController c, String? v) {
        final text = v ?? '';
        if (c.text != text) c.text = text;
      }

      sync(_numeroCtrl, d.numero);
      sync(_dataCtrl, d.data);
      sync(_orgaoCtrl, d.orgao);
      sync(_pareceristaNomeCtrl, d.pareceristaNome);
      _pareceristaUserId = d.pareceristaUserId;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _dataCtrl.dispose();
    _orgaoCtrl.dispose();
    _pareceristaNomeCtrl.dispose();
    super.dispose();
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      numero: _numeroCtrl.text,
      data: _dataCtrl.text,
      orgao: _orgaoCtrl.text,
      pareceristaNome: _pareceristaNomeCtrl.text,
      pareceristaUserId: _pareceristaUserId,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final users = widget.users;

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
                    labelText: 'Nº do parecer',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomDateField(
                    controller: _dataCtrl,
                    labelText: 'Data do parecer',
                    enabled: widget.isEditable,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                      SipGedMasks.dateDDMMYYYY,
                    ],
                    onChanged: (_) => _emitChange(),
                  ),
                ),
                SizedBox(
                  width: w4,
                  child: CustomTextField(
                    controller: _orgaoCtrl,
                    labelText: 'Órgão/Unidade jurídica',
                    enabled: widget.isEditable,
                    validator: validateRequired,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // ✅ Parecerista (genérico)
                SizedBox(
                  width: w4,
                  child: CustomAutoComplete<UserData>(
                    label: 'Parecerista',
                    controller: _pareceristaNomeCtrl,
                    allList: users,
                    enabled: widget.isEditable,
                    initialId: _pareceristaUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    validator: (v) {
                      if (!widget.isEditable) return null;
                      return (_pareceristaUserId ?? '').isNotEmpty
                          ? null
                          : 'Campo obrigatório';
                    },
                    onChanged: (id) {
                      _pareceristaUserId = id.isEmpty ? null : id;
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
