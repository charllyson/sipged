// lib/screens/menus/sign_up.dart (ajuste o path conforme o seu projeto)
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/validates/login_validators.dart';

import 'package:siged/_blocs/system/login/login_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_repository.dart';

// 🔔 Notificações centralizadas
import 'package:siged/_widgets/notification/app_notification.dart';
import 'package:siged/_widgets/notification/notification_center.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key, required this.userData});
  final UserData userData;

  @override
  State<SignUp> createState() => _SignUpState();
}

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

class _SignUpState extends State<SignUp> with LoginValidators {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _passController = TextEditingController();
  final _repeatPassController = TextEditingController();

  late LoginBloc _loginBloc; // ⚠️ será obtido do Provider
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    // ✅ NÃO instancie LoginBloc(); pegue do contexto (já com tenant)
    _loginBloc = context.read<LoginBloc>();
    // opcional: escutar estado se quiser
    // _loginBloc.outState.listen((_) {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passController.dispose();
    _repeatPassController.dispose();
    _loading.dispose();
    // ❌ não dispose _loginBloc aqui (é gerenciado pelo Provider)
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

      showDialog(
        context: context,
        builder: (context) => const CupertinoAlertDialog(
          title: Text('Erro na senha'),
          content: Text('As senhas digitadas não coincidem'),
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
      // 2) monta UserData (sem usar FirebaseAuth.instance direto)
      final repo = context.read<UserRepository>();
      final newUser = widget.userData
        ..email = _emailController.text.trim()
        ..name = _nameController.text.trim()
        ..surname = _surnameController.text.trim();

      // 3) Cria via LoginBloc (usa o tenant certo e já grava no Firestore)
      final ok = await _loginBloc.signUp(
        userData: newUser,
        pass: _passController.text,
      );

      if (!ok) {
        if (!mounted) return;
        _notify(
          'Erro ao cadastrar',
          subtitle: 'Verifique os dados e tente novamente.',
          type: AppNotificationType.error,
        );
        return;
      }

      // 4) Atualiza caches do UserBloc (opcional mas recomendado)
      final uid = _loginBloc.firebaseUser?.uid;
      if (uid != null) {
        await repo.save(newUser..uid = uid); // id garantido
        final bloc = context.read<UserBloc>();
        bloc
          ..add(UserFetchByIdRequested(uid))
          ..add(const CurrentUserBindToggleRequested(true));
      }

      if (!mounted) return;
      _notify('Cadastro realizado com sucesso!', type: AppNotificationType.success);
      Navigator.of(context).pop(); // fecha a tela de cadastro
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
                              // ⚠️ Usa stream/validação do LoginBloc provido
                              CustomTextField(
                                controller: _emailController,
                                stream: _loginBloc.outEmail,
                                onSaved: (v) => widget.userData.email = v,
                                labelText: 'E-mail',
                                prefix: const Icon(Icons.account_circle),
                                keyboardType: TextInputType.emailAddress,
                                onChanged: _loginBloc.changeEmail,
                                enabled: true,
                                validator: validateEmailLogin,
                              ),
                              CustomTextField(
                                initialValue: addFormatCpf(widget.userData.cpf ?? ''),
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
                                builder: (_, loading, __) {
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

            // 🔒 Bloqueio visual opcional durante o carregamento
            ValueListenableBuilder<bool>(
              valueListenable: _loading,
              builder: (_, loading, __) {
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
          child: ModalBarrier(dismissible: false, color: Color(0x66000000)),
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
                children: const [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Criando conta…',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
