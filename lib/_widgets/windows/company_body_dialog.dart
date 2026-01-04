// lib/_widgets/dialogs/company_body_dialog.dart
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/formats/mask_class.dart';
import 'package:siged/_blocs/system/setup/setup_cubit.dart';
import 'package:siged/_widgets/windows/window_dialog.dart';

Future<String?> showCreateCompanyBodyDialog(
    BuildContext context, {
      String dialogTitle = 'Nova empresa',
      String nameFieldLabel = 'Nome/Razão social',
      String cnpjFieldLabel = 'CNPJ',
    }) async {
  final nomeCtrl = TextEditingController();
  final cnpjCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String? _validateNome(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome da empresa';
    }
    return null;
  }

  String? _validateCnpj(String? value) {
    final text = value ?? '';
    final raw = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return 'Você deve informar um CNPJ';
    if (raw.length < 14) return 'CNPJ incompleto';
    if (!CNPJValidator.isValid(raw)) return 'CNPJ inválido';
    return null;
  }

  bool _canSave() {
    return _validateNome(nomeCtrl.text) == null &&
        _validateCnpj(cnpjCtrl.text) == null;
  }

  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true, // clicar fora fecha
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        final canSave = _canSave();

        return WindowDialog(
          title: dialogTitle,
          onClose: () => Navigator.pop(ctx, false), // X fecha
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: nomeCtrl,
                  labelText: nameFieldLabel,
                  validator: _validateNome,
                  onChanged: (_) {
                    setState(() {
                      formKey.currentState?.validate();
                    });
                  },
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: cnpjCtrl,
                  labelText: cnpjFieldLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(14),
                    TextInputMask(mask: '99.999.999/9999-99'),
                  ],
                  validator: _validateCnpj,
                  onChanged: (_) {
                    setState(() {
                      formKey.currentState?.validate();
                    });
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilledButton(
                      onPressed: canSave
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

  // 🔧 Ajuste: não existe mais `loadingCompanies`
  if (system.state.companies.isEmpty) {
    await system.loadCompanies();
  }

  final companies = system.state.companies;
  if (companies.isEmpty) {
    // Sem nenhuma company cadastrada: só devolve o nome para preencher o campo.
    return nome;
  }

  // Para garantir, usa companyId se existir, senão cai no id do doc.
  final parentCompanyId =
      companies.first.companyId ?? companies.first.id;

  final created = await system.createCompanyBody(
    parentCompanyId,
    nome,
    cnpj: cnpj,
  );

  return created?.label ?? nome;
}
