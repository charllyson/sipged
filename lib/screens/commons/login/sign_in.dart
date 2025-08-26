import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/system/login/login_bloc.dart';
import 'package:sisged/_widgets/background/background.dart';
import 'package:sisged/_widgets/background/sisgeo_logo.dart';
import 'package:sisged/_widgets/buttons/stream_button_.dart';
import 'package:sisged/_widgets/input/custom_icon_button.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';
import 'package:sisged/_widgets/loading/loading_progress.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late TextEditingController _emailController;
  late TextEditingController _passController;
  bool _hasEmail = false;
  bool _hasPass = false;
  bool _inputObscure = true;
  late LoginBloc _loginBloc;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passController = TextEditingController();
    _loginBloc = Provider.of<LoginBloc>(context, listen: false);

    _emailController.addListener(() {
      setState(() => _hasEmail = _emailController.text.isNotEmpty);
    });

    _passController.addListener(() {
      setState(() => _hasPass = _passController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<LoginState>(
        stream: _loginBloc.outState,
        builder: (context, snapshot) {
          final isLoading = snapshot.data == LoginState.loading;

          return Stack(
            children: <Widget>[
              // background com constraints finitas
              Background(),
              // conteúdo rolável
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    children: [
                      const SisGedLogo(),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth;
                          if (constraints.maxWidth >= 1000) {
                            maxWidth = 500;
                          } else if (constraints.maxWidth >= 600) {
                            maxWidth = 400;
                          } else {
                            maxWidth = constraints.maxWidth * 0.75;
                          }
                          return Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.05,
                            ),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: maxWidth),
                                child: Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 16,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 32),
                                          child: CustomTextField(
                                            controller: _emailController,
                                            autofillHints: const [AutofillHints.username],
                                            stream: _loginBloc.outEmail,
                                            labelText: 'E-mail',
                                            prefix: const Icon(Icons.account_circle),
                                            keyboardType: TextInputType.emailAddress,
                                            onChanged: _loginBloc.changeEmail,
                                            enabled: true,
                                            suffix: _hasEmail
                                                ? CustomIconButton(
                                              radius: 32,
                                              iconData: Icons.clear,
                                              onTap: _emailController.clear,
                                            )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 32),
                                          child: CustomTextField(
                                            controller: _passController,
                                            autofillHints: const [AutofillHints.password],
                                            labelText: 'Senha',
                                            prefix: const Icon(Icons.lock),
                                            obscure: _inputObscure,
                                            stream: _loginBloc.outPassword,
                                            onChanged: _loginBloc.changePassword,
                                            enabled: true,
                                            suffix: _hasPass
                                                ? IconButton(
                                              icon: Icon(
                                                _inputObscure
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                              ),
                                              onPressed: () => setState(
                                                    () => _inputObscure = !_inputObscure,
                                              ),
                                            )
                                                : null,
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              // TODO: Implementar recuperação de senha
                                            },
                                            child: const Text(
                                              'Esqueci minha senha',
                                              style: TextStyle(color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                        StreamButton(loginBloc: _loginBloc),
                                        if (snapshot.data == LoginState.fail)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              "Erro ao fazer login",
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // overlay de loading
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingProgress(),
                        SizedBox(height: 12),
                        Text(
                          "Entrando...",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
