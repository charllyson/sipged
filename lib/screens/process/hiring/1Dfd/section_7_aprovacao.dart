import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_widgets/input/custom_auto_complete.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';

class SectionAprovacao extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final List<UserData> users;
  final void Function(DfdData updated) onChanged;

  const SectionAprovacao({
    super.key,
    required this.isEditable,
    required this.data,
    required this.users,
    required this.onChanged,
  });

  @override
  State<SectionAprovacao> createState() => _SectionAprovacaoState();
}

class _SectionAprovacaoState extends State<SectionAprovacao>
    with FormValidationMixin {
  late final TextEditingController _autoridadeCtrl;
  late final TextEditingController _cpfAutoridadeCtrl;
  late final TextEditingController _dataAprovacaoCtrl;
  late final TextEditingController _parecerResumoCtrl;

  late List<UserData> _usersWithSelf;
  String? _autoridadeUserId;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    _autoridadeCtrl = TextEditingController(text: d.autoridadeAprovadora ?? '');
    _cpfAutoridadeCtrl = TextEditingController(text: d.autoridadeCpf ?? '');
    _dataAprovacaoCtrl =
        TextEditingController(text: _formatDate(d.dataAprovacao));
    _parecerResumoCtrl = TextEditingController(text: d.parecerResumo ?? '');

    _autoridadeUserId = d.autoridadeUserId;

    _setupUsersWithSelf();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureDefaultAuthorityFromFirebase();
    });
  }

  @override
  void didUpdateWidget(covariant SectionAprovacao oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.data != widget.data) {
      final d = widget.data;

      final aut = d.autoridadeAprovadora ?? '';
      final cpf = d.autoridadeCpf ?? '';
      final data = _formatDate(d.dataAprovacao);
      final par = d.parecerResumo ?? '';

      if (_autoridadeCtrl.text != aut) _autoridadeCtrl.text = aut;
      if (_cpfAutoridadeCtrl.text != cpf) _cpfAutoridadeCtrl.text = cpf;
      if (_dataAprovacaoCtrl.text != data) _dataAprovacaoCtrl.text = data;
      if (_parecerResumoCtrl.text != par) _parecerResumoCtrl.text = par;

      _autoridadeUserId = d.autoridadeUserId;
    }

    if (oldWidget.users != widget.users) {
      _setupUsersWithSelf();
    }
  }

  @override
  void dispose() {
    _autoridadeCtrl.dispose();
    _cpfAutoridadeCtrl.dispose();
    _dataAprovacaoCtrl.dispose();
    _parecerResumoCtrl.dispose();
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

  void _setupUsersWithSelf() {
    final fbUser = FirebaseAuth.instance.currentUser;
    final currentUid = fbUser?.uid ?? '';
    final currentName = (fbUser?.displayName ?? '').trim();
    final currentEmail = (fbUser?.email ?? '').trim();
    final currentPhoto = (fbUser?.photoURL ?? '').trim();

    final alreadyInList = widget.users.any((u) => (u.uid ?? '') == currentUid);

    if (alreadyInList || currentUid.isEmpty) {
      _usersWithSelf = widget.users;
    } else {
      _usersWithSelf = [
        ...widget.users,
        UserData(
          uid: currentUid,
          name: currentName.isNotEmpty ? currentName : null,
          email: currentEmail.isNotEmpty ? currentEmail : null,
          urlPhoto: currentPhoto.isNotEmpty ? currentPhoto : null,
        ),
      ];
    }
  }

  void _ensureDefaultAuthorityFromFirebase() {
    final fbUser = FirebaseAuth.instance.currentUser;
    final currentUid = fbUser?.uid ?? '';
    final currentName = (fbUser?.displayName ?? '').trim();
    final currentEmail = (fbUser?.email ?? '').trim();
    final currentPhoto = (fbUser?.photoURL ?? '').trim();

    final noAuthority = _autoridadeUserId == null || _autoridadeUserId!.isEmpty;

    if (noAuthority && currentUid.isNotEmpty) {
      _autoridadeUserId = currentUid;

      final self = _usersWithSelf.firstWhere(
            (u) => (u.uid ?? '') == currentUid,
        orElse: () => UserData(
          uid: currentUid,
          name: currentName.isNotEmpty ? currentName : null,
          email: currentEmail.isNotEmpty ? currentEmail : null,
          urlPhoto: currentPhoto.isNotEmpty ? currentPhoto : null,
        ),
      );

      final label = self.name ?? self.email ?? currentUid;
      _autoridadeCtrl.text = label;

      _emitChange();
    }
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      autoridadeAprovadora: _autoridadeCtrl.text,
      autoridadeUserId: _autoridadeUserId,
      autoridadeCpf: _cpfAutoridadeCtrl.text,
      dataAprovacao: _parseBrDate(_dataAprovacaoCtrl.text),
      parecerResumo: _parecerResumoCtrl.text,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '7) Aprovação / Alçada'),
        LayoutBuilder(
          builder: (context, inner) {
            final w3 = inputW3(context, inner);
            final w1 = inputW1(context, inner);

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Autoridade aprovadora
                SizedBox(
                  width: w3,
                  child: CustomAutoComplete<UserData>(
                    label: 'Autoridade aprovadora',
                    controller: _autoridadeCtrl,
                    allList: _usersWithSelf,
                    enabled: widget.isEditable,
                    initialId: _autoridadeUserId,
                    idOf: (u) => u.uid,
                    displayOf: (u) => u.name ?? u.email ?? '',
                    subtitleOf: (u) => u.email ?? '',
                    photoUrlOf: (u) => u.urlPhoto,
                    validator: null,
                    onChanged: (userId) {
                      _autoridadeUserId = userId;
                      _emitChange();
                    },
                  ),
                ),

                // CPF da autoridade
                SizedBox(
                  width: w3,
                  child: CustomTextField(
                    controller: _cpfAutoridadeCtrl,
                    enabled: widget.isEditable,
                    validator: null,
                    labelText: 'CPF da autoridade',
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                      TextInputMask(mask: '999.999.999-99'),
                    ],
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Data da aprovação
                SizedBox(
                  width: w3,
                  child: CustomDateField(
                    controller: _dataAprovacaoCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Data da aprovação',
                    onChanged: (_) => _emitChange(),
                  ),
                ),

                // Parecer/resumo
                SizedBox(
                  width: w1,
                  child: CustomTextField(
                    controller: _parecerResumoCtrl,
                    enabled: widget.isEditable,
                    labelText: 'Parecer/resumo da aprovação',
                    maxLines: 3,
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
