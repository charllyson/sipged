import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sipged/_blocs/system/login/login_bloc.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/images/logos/sisgeo_logo.dart';
import 'package:sipged/_widgets/input/custom_icon_button.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/screens/common/login/sign_in_button.dart';

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
    _companyController = TextEditingController(text: SetupData.defaultModuleLabel);

    _emailFocus = FocusNode();
    _passFocus = FocusNode();

    _loginBloc = Provider.of<LoginBloc>(context, listen: false);

    // gradiente também baseado no módulo padrão
    _bgGradient = SetupData.gradientForModule(SetupData.defaultModuleLabel);

    _emailController.addListener(() {
      final has = _emailController.text.trim().isNotEmpty;
      if (has != _hasEmail) setState(() => _hasEmail = has);
    });

    // quando mudar o módulo, atualiza gradiente e informa ao bloc
    _companyController.addListener(() {
      final selected = _companyController.text.trim();
      setState(() => _bgGradient = SetupData.gradientForModule(selected));
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
    FocusScope.of(context).unfocus();
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

          return Container(
            decoration: BoxDecoration(gradient: _bgGradient),
            child: Stack(
              children: [
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = MediaQuery.of(context).size.width;

                      // bem parecido com o Boomby: 420 central, senão ocupa tudo
                      final maxW = w >= 520 ? 420.0 : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxW),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: 22,
                              right: 22,
                              top: 18,
                              bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minHeight: constraints.maxHeight),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    const SiGedLogo(),
                                    const SizedBox(height: 16),

                                    // Card “AuthCard-like”
                                    _buildLoginCard(context),

                                    const Spacer(),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return BasicCard(
      isDark: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ===== Dropdown Módulo (travado) =====
            DropDownButtonChange(
              width: double.infinity,
              controller: _companyController,
              labelText: 'Módulo',
              enabled: false, // 🔒 módulo travado por instalação
              items: SetupData.moduleName,
            ),

            const SizedBox(height: 8),

            // ===== Indicador de acesso à área escolhida =====
            StreamBuilder<AreaAccessStatus>(
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
                        hasAccess ? 'Acesso disponível para $selected' : 'Sem permissão para $selected',
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

            const SizedBox(height: 12),

            // ===== Campo E-mail =====
            CustomTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passFocus.requestFocus(),
              autofillHints: const [AutofillHints.username],
              stream: _loginBloc.outEmail,
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              keyboardType: TextInputType.emailAddress,
              onChanged: _loginBloc.changeEmail,
              enabled: true,
              suffix: _hasEmail
                  ? CustomIconButton(
                radius: 28,
                iconData: Icons.clear,
                onTap: () {
                  _emailController.clear();
                  _loginBloc.changeEmail('');
                  _emailFocus.requestFocus();
                },
              )
                  : null,
            ),

            const SizedBox(height: 12),

            // ===== Campo Senha =====
            CustomTextField(
              controller: _passController,
              focusNode: _passFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitIfPossible(),
              autofillHints: const [AutofillHints.password],
              labelText: 'Senha',
              hintText: '••••••••',
              obscure: _inputObscure,
              stream: _loginBloc.outPassword,
              onChanged: _loginBloc.changePassword,
              enabled: true,
              suffix: IconButton(
                tooltip: _inputObscure ? 'Mostrar' : 'Ocultar',
                icon: Icon(
                  _inputObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: const Color(0xFF6B7280),
                  size: 20,
                ),
                onPressed: () => setState(() => _inputObscure = !_inputObscure),
              ),
            ),

            const SizedBox(height: 10),

            // ===== Recuperar senha =====
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  final email = _emailController.text.trim();
                  if (email.isNotEmpty) _loginBloc.recoverPass(email);
                },
                child: const Text(
                  'Esqueci a senha',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // ===== Botão de login (habilitado pelo bloc) =====
            SignInButton(loginBloc: _loginBloc),

            const SizedBox(height: 6),

            // ===== Mensagem de erro (mantida, mas agora fica mais “Boomby-like”) =====
            StreamBuilder<LoginState>(
              stream: _loginBloc.outState,
              builder: (_, snap) {
                if (snap.data == LoginState.fail) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Erro ao fazer login",
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
