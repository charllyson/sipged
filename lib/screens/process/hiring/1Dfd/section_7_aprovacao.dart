// lib/screens/process/hiring/1Dfd/dfd_sections/section_7_aprovacao.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_data.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/validates/form_validation_mixin.dart';
import 'package:siged/_utils/formats/mask_class.dart';

import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/autocomplete/autocomplete_user_class.dart';
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

    _autoridadeCtrl    = TextEditingController(text: d.autoridadeAprovadora);
    _cpfAutoridadeCtrl = TextEditingController(text: d.autoridadeCpf);
    _dataAprovacaoCtrl = TextEditingController(text: d.dataAprovacao);
    _parecerResumoCtrl = TextEditingController(text: d.parecerResumo);

    _autoridadeUserId  = d.autoridadeUserId;

    _setupUsersWithSelf();

    // ⚠️ IMPORTANTE:
    // Só vamos definir a autoridade padrão (usuário logado)
    // DEPOIS do primeiro frame, para não disparar setState no pai
    // enquanto o filho ainda está montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureDefaultAuthorityFromFirebase();
    });
  }

  @override
  void didUpdateWidget(covariant SectionAprovacao oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se os dados mudaram externamente, sincroniza os controllers:
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      _autoridadeCtrl.text    = d.autoridadeAprovadora;
      _cpfAutoridadeCtrl.text = d.autoridadeCpf;
      _dataAprovacaoCtrl.text = d.dataAprovacao;
      _parecerResumoCtrl.text = d.parecerResumo;
      _autoridadeUserId       = d.autoridadeUserId;
    }

    // Se a lista de usuários mudou, refaz a lista com o próprio usuário:
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setupUsersWithSelf() {
    final fbUser       = FirebaseAuth.instance.currentUser;
    final currentUid   = fbUser?.uid ?? '';
    final currentName  = (fbUser?.displayName ?? '').trim();
    final currentEmail = (fbUser?.email ?? '').trim();
    final currentPhoto = (fbUser?.photoURL ?? '').trim();

    final alreadyInList =
    widget.users.any((u) => (u.uid ?? '') == currentUid);

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

  /// Garante que, se não houver autoridade definida no DFD,
  /// a autoridade padrão seja o usuário logado.
  void _ensureDefaultAuthorityFromFirebase() {
    final fbUser       = FirebaseAuth.instance.currentUser;
    final currentUid   = fbUser?.uid ?? '';
    final currentName  = (fbUser?.displayName ?? '').trim();
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

      // Agora é seguro emitir a alteração (já estamos pós-frame)
      _emitChange();
    }
  }

  void _emitChange() {
    final updated = widget.data.copyWith(
      autoridadeAprovadora: _autoridadeCtrl.text,
      autoridadeUserId:     _autoridadeUserId,
      autoridadeCpf:        _cpfAutoridadeCtrl.text,
      dataAprovacao:        _dataAprovacaoCtrl.text,
      parecerResumo:        _parecerResumoCtrl.text,
    );
    widget.onChanged(updated);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('7) Aprovação / Alçada'),
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
                  child: AutocompleteUserClass(
                    label: 'Autoridade aprovadora',
                    controller: _autoridadeCtrl,
                    allUsers: _usersWithSelf,
                    enabled: widget.isEditable,
                    initialUserId: _autoridadeUserId,
                    validator: validateRequired,
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
                    validator: validateRequired,
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
