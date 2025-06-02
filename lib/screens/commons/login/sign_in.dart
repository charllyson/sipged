import 'package:flutter/material.dart';
import '../../../_blocs/login/login_bloc.dart';
import '../../../_widgets/background/background.dart';
import '../../../_widgets/background/der_logo.dart';
import '../../../_widgets/buttons/stream_button_.dart'; // Presume-se que StreamBotton foi um erro de digitação
import '../../../_widgets/input/custom_icon_button.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../../../_widgets/loading/loading_progress.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
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
    _loginBloc = LoginBloc();

    _emailController.addListener(() {
      setState(() {
        _hasEmail = _emailController.text.isNotEmpty;
      });
    });

    _passController.addListener(() {
      setState(() {
        _hasPass = _passController.text.isNotEmpty;
      });
    });

    // Se necessário, ative esta escuta para ações com base em estados:
    /*
    _loginBloc.outState.listen((state) {
      switch (state) {
        case LoginState.successProfileCommom:
          break;
        case LoginState.successProfileGovernment:
          break;
        case LoginState.successProfileCollaborator:
          break;
        case LoginState.successProfileCompany:
          break;
        case LoginState.fail:
          break;
        case LoginState.loading:
        case LoginState.idle:
      }
    });
    */
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _loginBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<LoginState>(
        stream: _loginBloc.outState,
        builder: (context, snapshot) {
          final isLoading = snapshot.data == LoginState.loading;
          return Stack(
            children: <Widget>[
              Background(),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    children: [
                      DERLogo(),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          double maxWidth;
                          if (constraints.maxWidth >= 1000) {
                            maxWidth = 500;
                          } else if (constraints.maxWidth >= 600) {
                            maxWidth = 400;
                          } else {
                            maxWidth = constraints.maxWidth * 0.9;
                          }
                          return Align(
                            alignment: Alignment.center,
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
                                      CustomTextField(
                                        controller: _emailController,
                                        autofillHints: [AutofillHints.username],
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
                                          onTap: () {
                                            _emailController.clear();
                                          },
                                        )
                                            : null,
                                      ),
                                      SizedBox(height: 16),
                                      CustomTextField(
                                        controller: _passController,
                                        autofillHints: [AutofillHints.password],
                                        labelText: 'Senha',
                                        prefix: const Icon(Icons.lock),
                                        obscure: _inputObscure,
                                        stream: _loginBloc.outPassword,
                                        onChanged: _loginBloc.changePassword,
                                        enabled: true,
                                        suffix: _hasPass
                                            ? IconButton(
                                          icon: Icon(
                                            _inputObscure ? Icons.visibility_off : Icons.visibility,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _inputObscure = !_inputObscure;
                                            });
                                          },
                                        )
                                            : null,
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
                                      StreamButton(loginBloc: _loginBloc), // Corrigido nome do widget
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
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.white,
                    height: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          'Ainda não tem conta?',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Implementar cadastro
                          },
                          child: Text(
                            'Cadastre-se',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black54,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoadingProgress(),
                      const Text(
                        "Entrando...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
