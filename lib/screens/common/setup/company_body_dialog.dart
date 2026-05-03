import 'package:cpf_cnpj_validator/cnpj_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dialog/windows/window_dialog.dart';
import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';
import 'package:sipged/_utils/mask/sipged_masks.dart';

Future<String?> showCreateTenantProfileDialog(
    BuildContext context, {
      String dialogTitle = 'Dados do tenant',
      String nameFieldLabel = 'Nome/Razão social',
      String fantasyFieldLabel = 'Nome fantasia',
      String cnpjFieldLabel = 'CNPJ',
    }) async {
  final nomeCtrl = TextEditingController();
  final fantasiaCtrl = TextEditingController();
  final cnpjCtrl = TextEditingController();

  final formKey = GlobalKey<FormState>();
  final tenantCubit = context.read<TenantCubit>();

  final current = tenantCubit.state.tenantProfile;

  if (current != null) {
    nomeCtrl.text = current.companyName ?? current.label;
    fantasiaCtrl.text = current.fantasyName ?? '';
    cnpjCtrl.text = current.cnpj ?? '';
  }

  String? validateNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome/razão social';
    }

    return null;
  }

  String? validateCnpj(String? value) {
    final text = value ?? '';
    final raw = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (raw.isEmpty) return 'Você deve informar um CNPJ';
    if (raw.length < 14) return 'CNPJ incompleto';
    if (!CNPJValidator.isValid(raw)) return 'CNPJ inválido';

    return null;
  }

  bool canSave() {
    return validateNome(nomeCtrl.text) == null &&
        validateCnpj(cnpjCtrl.text) == null;
  }

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final enabledSave = canSave();

          void revalidate() {
            setState(() {
              formKey.currentState?.validate();
            });
          }

          return WindowDialog(
            title: dialogTitle,
            onClose: () => Navigator.pop(ctx, false),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: nomeCtrl,
                    labelText: nameFieldLabel,
                    validator: validateNome,
                    onChanged: (_) => revalidate(),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: fantasiaCtrl,
                    labelText: fantasyFieldLabel,
                    onChanged: (_) => revalidate(),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: cnpjCtrl,
                    labelText: cnpjFieldLabel,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                      SipGedMasks.cnpj,
                    ],
                    validator: validateCnpj,
                    onChanged: (_) => revalidate(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        onPressed: enabledSave
                            ? () {
                          if (formKey.currentState?.validate() ??
                              false) {
                            Navigator.pop(ctx, true);
                          }
                        }
                            : null,
                        child: const Text('Salvar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (ok != true) return null;

  final nome = nomeCtrl.text.trim();
  final fantasia = fantasiaCtrl.text.trim();
  final cnpj = cnpjCtrl.text.trim();

  if (nome.isEmpty) return null;

  final saved = await tenantCubit.saveTenantProfile(
    label: nome,
    fantasyName: fantasia,
    cnpj: cnpj,
  );

  return saved?.label ?? nome;
}

/// Compatibilidade temporária com chamadas antigas.
///
/// Use `showCreateTenantProfileDialog` nas novas telas.
Future<String?> showCreateCompanyBodyDialog(
    BuildContext context, {
      String dialogTitle = 'Dados do tenant',
      String nameFieldLabel = 'Nome/Razão social',
      String cnpjFieldLabel = 'CNPJ',
    }) {
  return showCreateTenantProfileDialog(
    context,
    dialogTitle: dialogTitle,
    nameFieldLabel: nameFieldLabel,
    cnpjFieldLabel: cnpjFieldLabel,
  );
}