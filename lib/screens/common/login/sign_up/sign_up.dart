import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_utils/formats/sipged_format_numbers.dart';
import 'package:sipged/_utils/validates/sipged_validation.dart';
import 'package:sipged/_widgets/input/custom_date_field.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_event.dart';
import 'package:sipged/_blocs/system/user/user_repository.dart';

// 🔔 Notificações centralizadas
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

// 🪟 WindowDialog
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key, required this.userData});
  final UserData userData;

  @override
  State<SignUp> createState() => _SignUpState();
}

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _SignUpState extends State<SignUp> with SipGedValidation {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _passController = TextEditingController();
  final _repeatPassController = TextEditingController();

  late LoginCubit _loginCubit;
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loginCubit = context.read<LoginCubit>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passController.dispose();
    _repeatPassController.dispose();
    _loading.dispose();
    super.dispose();
  }

  void _notify(
      String title, {
        String? subtitle,
        AppNotificationType type = AppNotificationType.info,
      }) {
    NotificationCenter.instance.show(
      AppNotification(
        type: type,
        title: Text(title),
        subtitle: (subtitle != null && subtitle.isNotEmpty) ? Text(subtitle) : null,
      ),
    );
  }

  Future<void> _submit() async {
    // 0) senha igual
    if (_passController.text != _repeatPassController.text) {
      _passController.clear();
      _repeatPassController.clear();
      if (!mounted) return;

      await showWindowDialog<void>(
        context: context,
        title: 'Erro na senha',
        width: 420,
        child: Builder(
          builder: (dialogCtx) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'As senhas digitadas não coincidem. Por favor, digite novamente.',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
      return;
    }

    // 1) valida form
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    _formKey.currentState?.save();

    _loading.value = true;
    try {
      final repo = context.read<UserRepository>();

      // ✅ padroniza email no cadastro (recomendado)
      final email = _emailController.text.trim();
      final emailLower = email.toLowerCase();

      final newUser = widget.userData
        ..email = emailLower
        ..name = _nameController.text.trim()
        ..surname = _surnameController.text.trim();

      final ok = await _loginCubit.signUp(
        userData: newUser,
        pass: _passController.text,
      );

      if (!ok) {
        if (!mounted) return;
        _notify(
          'Erro ao cadastrar',
          subtitle: _loginCubit.state.errorMessage ?? 'Verifique os dados e tente novamente.',
          type: AppNotificationType.error,
        );
        return;
      }

      final uid = _loginCubit.state.firebaseUser?.uid;
      if (uid != null) {
        // garante UID no modelo antes de salvar
        newUser.uid = uid;

        // 🔥 salva no Firestore via repository
        await repo.save(newUser);

        // atualiza UserBloc (bind user atual)
        final bloc = context.read<UserBloc>();
        bloc
          ..add(UserFetchByIdRequested(uid))
          ..add(const CurrentUserBindToggleRequested(true));
      }

      if (!mounted) return;
      _notify('Cadastro realizado com sucesso!', type: AppNotificationType.success);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _notify(
        'Erro inesperado ao cadastrar',
        subtitle: '$e',
        type: AppNotificationType.error,
      );
    } finally {
      _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cpfDigits = (widget.userData.cpf ?? '').replaceAll(RegExp(r'\D'), '');
    final cpfFormatted = cpfDigits.isEmpty ? '' : SipGedFormatNumbers.formatCPF(cpfDigits);

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 16,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CustomTextField(
                                controller: _nameController,
                                onSaved: (v) => widget.userData.name = v,
                                labelText: 'Nome',
                                prefix: const Icon(Icons.account_circle),
                                validator: validateName,
                              ),
                              CustomTextField(
                                controller: _surnameController,
                                onSaved: (v) => widget.userData.surname = v,
                                labelText: 'Sobrenome',
                                prefix: const Icon(Icons.account_circle),
                                validator: validateSurname,
                              ),
                              CustomTextField(
                                controller: _emailController,
                                onSaved: (v) => widget.userData.email = v?.trim().toLowerCase(),
                                labelText: 'E-mail',
                                prefix: const Icon(Icons.account_circle),
                                keyboardType: TextInputType.emailAddress,
                                enabled: true,
                                validator: validateEmailLogin,
                              ),

                              // ✅ CPF apenas exibido, já formatado
                              CustomTextField(
                                initialValue: cpfFormatted,
                                labelText: 'CPF',
                                enabled: false,
                                prefix: const Icon(Icons.account_box),
                                suffix: const Icon(Icons.check_circle, color: Colors.green),
                                keyboardType: TextInputType.number,
                                inputFormatters: [CpfInputFormatter()],
                              ),

                              CustomDateField(
                                validator: validateDateToBirthday,
                                onSaved: (v) => widget.userData.dateToBirthday = v,
                                labelText: 'Data de nascimento',
                                prefix: const Icon(Icons.cake),
                              ),
                              CustomTextField(
                                controller: _passController,
                                labelText: 'Senha',
                                prefix: const Icon(Icons.lock),
                                obscure: true,
                                validator: validatePasswordLogin,
                              ),
                              CustomTextField(
                                controller: _repeatPassController,
                                labelText: 'Repita a Senha',
                                prefix: const Icon(Icons.lock),
                                obscure: true,
                                validator: validatePasswordLogin,
                              ),
                              const SizedBox(height: 8),
                              ValueListenableBuilder<bool>(
                                valueListenable: _loading,
                                builder: (_, loading, _) {
                                  return ElevatedButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(32),
                                      ),
                                    ),
                                    onPressed: loading ? null : _submit,
                                    child: loading
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Text(
                                      'Cadastrar',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            ValueListenableBuilder<bool>(
              valueListenable: _loading,
              builder: (_, loading, _) {
                if (!loading) return const SizedBox.shrink();
                return const _BlockingOverlay(message: 'Criando conta…');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockingOverlay extends StatelessWidget {
  const _BlockingOverlay({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: ModalBarrier(
            dismissible: false,
            color: Color(0x66000000),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6E6E6E)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
