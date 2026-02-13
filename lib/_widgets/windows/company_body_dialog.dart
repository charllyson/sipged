import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/windows/window_dialog.dart';
import 'package:sipged/_blocs/system/setup/setup_cubit.dart';

// ✅ novos utils (ajuste o path conforme sua estrutura)
import 'package:sipged/_utils/mask/sipged_masks.dart';
// se você não tiver SipGedMasks.cnpj pronto, pode usar o formatter genérico:

Future<String?> showCreateCompanyBodyDialog(
    BuildContext context, {
      String dialogTitle = 'Nova empresa',
      String nameFieldLabel = 'Nome/Razão social',
      String cnpjFieldLabel = 'CNPJ',
    }) async {
  final nomeCtrl = TextEditingController();
  final cnpjCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? validateNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome da empresa';
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
    builder: (_) => StatefulBuilder(
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
                        if (formKey.currentState?.validate() ?? false) {
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
    ),
  );

  if (ok != true) return null;

  final nome = nomeCtrl.text.trim();
  final cnpj = cnpjCtrl.text.trim();
  if (nome.isEmpty) return null;

  final system = context.read<SetupCubit>();

  // garante companies carregadas (se o state vier vazio)
  if (system.state.companies.isEmpty) {
    await system.loadCompanies();
  }

  final companies = system.state.companies;
  if (companies.isEmpty) {
    // sem company cadastrada ainda: devolve só o nome (seu fluxo atual)
    return nome;
  }

  final parentCompanyId = companies.first.companyId ?? companies.first.id;

  final created = await system.createCompanyBody(
    parentCompanyId,
    nome,
    cnpj: cnpj,
  );

  return created?.label ?? nome;
}
