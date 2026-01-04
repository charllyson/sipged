// lib/screens/login/sign_in.dart (ou caminho equivalente)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:siged/_blocs/system/login/login_bloc.dart';
import 'package:siged/_blocs/system/setup/setup_data.dart';
import 'package:siged/_widgets/images/logos/sisgeo_logo.dart';
import 'package:siged/_widgets/login/sign_in_button.dart';
import 'package:siged/_widgets/input/custom_icon_button.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';
import 'package:siged/_widgets/overlays/loading_progress.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late final TextEditingController _emailController;
  late final TextEditingController _companyController;
  late final TextEditingController _passController;

  late final FocusNode _emailFocus;
  late final FocusNode _passFocus;

  bool _hasEmail = false;
  bool _inputObscure = true;

  late LoginBloc _loginBloc;
  late Gradient _bgGradient;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passController = TextEditingController();

    // 🔥 começa com o módulo padrão definido no SetupData
    _companyController = TextEditingController(
      text: SetupData.defaultModuleLabel,
    );

    _emailFocus = FocusNode();
    _passFocus = FocusNode();

    _loginBloc = Provider.of<LoginBloc>(context, listen: false);

    // gradiente também baseado no módulo padrão
    _bgGradient = SetupData.gradientForModule(SetupData.defaultModuleLabel);

    _emailController.addListener(() {
      setState(() => _hasEmail = _emailController.text.isNotEmpty);
    });

    // quando mudar o módulo, atualiza gradiente e informa ao bloc
    _companyController.addListener(() {
      final selected = _companyController.text.trim();
      setState(() => _bgGradient = SetupData.gradientForModule(selected));
      // ✅ agora envia o módulo realmente selecionado, e não "DER" fixo
      _loginBloc.changeSelectedArea(selected);
    });
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passFocus.dispose();
    _emailController.dispose();
    _passController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _submitIfPossible() {
    _loginBloc.signIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: StreamBuilder<LoginState>(
        stream: _loginBloc.outState,
        builder: (context, snapshot) {
          final isLoading = snapshot.data == LoginState.loading;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                // gradiente cobre toda a tela
                decoration: BoxDecoration(gradient: _bgGradient),
                child: Stack(
                  children: [
                    SafeArea(
                      top: true,
                      bottom: false,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                const SiGedLogo(),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: _buildLoginCard(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    double maxWidth;
    if (screenW >= 1000) {
      maxWidth = 500;
    } else if (screenW >= 600) {
      maxWidth = 420;
    } else {
      maxWidth = screenW * 0.82;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 16,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ===== Dropdown Módulo (atualmente só exibe o módulo em uso) =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: DropDownButtonChange(
                  width: maxWidth,
                  controller: _companyController,
                  labelText: 'Módulo',
                  enabled: false, // 🔒 módulo travado por instalação
                  items: SetupData.moduleName,
                ),
              ),

              // ===== Indicador de acesso à área escolhida =====
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                child: StreamBuilder<AreaAccessStatus>(
                  stream: _loginBloc.outAreaAccessStatus,
                  builder: (context, snap) {
                    final status = snap.data ?? AreaAccessStatus.idle;
                    final selected = _companyController.text.trim();

                    if (selected.isEmpty || status == AreaAccessStatus.idle) {
                      return const SizedBox(height: 4);
                    }

                    if (status == AreaAccessStatus.needEmail) {
                      return Row(
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Informe o e-mail',
                              style: TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                          ),
                        ],
                      );
                    }

                    final hasAccess = (status == AreaAccessStatus.allowed);
                    return Row(
                      children: [
                        Icon(
                          hasAccess ? Icons.verified_user : Icons.lock_outline,
                          size: 16,
                          color: hasAccess ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            hasAccess
                                ? 'Acesso disponível para $selected'
                                : 'Sem permissão para $selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: hasAccess ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // ===== Campo E-mail =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: CustomTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passFocus.requestFocus(),
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
                    onTap: () {
                      _emailController.clear();
                      _loginBloc.changeEmail('');
                    },
                  )
                      : null,
                ),
              ),

              const SizedBox(height: 16),

              // ===== Campo Senha =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: CustomTextField(
                  controller: _passController,
                  focusNode: _passFocus,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submitIfPossible(),
                  autofillHints: const [AutofillHints.password],
                  labelText: 'Senha',
                  prefix: const Icon(Icons.lock),
                  obscure: _inputObscure,
                  stream: _loginBloc.outPassword,
                  onChanged: _loginBloc.changePassword,
                  enabled: true,
                  suffix: IconButton(
                    icon: Icon(
                      _inputObscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _inputObscure = !_inputObscure),
                  ),
                ),
              ),

              // ===== Recuperar senha =====
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    final email = _emailController.text.trim();
                    if (email.isNotEmpty) {
                      _loginBloc.recoverPass(email);
                    }
                  },
                  child: const Text(
                    'Esqueci a senha',
                    style: TextStyle(color: Colors.blue, fontSize: 11),
                  ),
                ),
              ),

              // ===== Botão de login (habilitado pelo bloc) =====
              SignInButton(loginBloc: _loginBloc),

              // ===== Mensagem de erro =====
              StreamBuilder<LoginState>(
                stream: _loginBloc.outState,
                builder: (_, snap) {
                  if (snap.data == LoginState.fail) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Erro ao fazer login",
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
