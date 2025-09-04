import 'package:brasil_fields/brasil_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_utils/validates/login_validators.dart';

import 'package:siged/_blocs/system/login/login_bloc.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_repository.dart';

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

  late LoginBloc _loginBloc;
  final ValueNotifier<bool> _loading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _loginBloc = LoginBloc();
    _loginBloc.outState.listen((_) {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _passController.dispose();
    _repeatPassController.dispose();
    _loading.dispose();
    _loginBloc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // 0) senha igual
    if (_passController.text != _repeatPassController.text) {
      _passController.clear();
      _repeatPassController.clear();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const CupertinoAlertDialog(
            title: Text('Erro na senha'),
            content: Text('As senhas digitadas não coincidem'),
          ),
        );
      }
      return;
    }

    // 1) valida form
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    _formKey.currentState?.save();

    _loading.value = true;
    try {
      // 2) cria no Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text,
      );
      final uid = cred.user!.uid;

      // 3) monta UserData e salva no Firestore via UserRepository
      final repo = context.read<UserRepository>();
      final newUser = widget.userData
        ..id = uid
        ..email = _emailController.text.trim()
        ..name = _nameController.text.trim()
        ..surname = _surnameController.text.trim();

      await repo.save(newUser);

      // 4) avisa o UserBloc para refletir no estado (cache/byId/current)
      final bloc = context.read<UserBloc>();
      // carrega o novo usuário para o cache
      bloc.add(UserFetchByIdRequested(uid));
      // (opcional) ativa o bind do usuário atual para receber atualizações em tempo real
      bloc.add(const CurrentUserBindToggleRequested(true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // fecha a tela de cadastro
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado ao cadastrar: $e')),
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
                                initialValue:
                                addFormatCpf(widget.userData.cpf!),
                                labelText: 'CPF',
                                enabled: false,
                                prefix: const Icon(Icons.account_box),
                                suffix: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                keyboardType: TextInputType.number,
                                inputFormatters: [CpfInputFormatter()],
                              ),
                              CustomDateField(
                                validator: validateDateToBirthday,
                                onSaved: (v) =>
                                widget.userData.dateToBirthday = v,
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
                                      style:
                                      TextStyle(color: Colors.white),
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
            // Dica: se quiser bloquear toques enquanto salva, adicione um ModalBarrier usando _loading.
          ],
        ),
      ),
    );
  }
}
