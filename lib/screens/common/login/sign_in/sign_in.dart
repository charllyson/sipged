import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_state.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/images/logos/sisgeo_logo.dart';
import 'package:sipged/_widgets/input/icon_button_change.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/input/drop_down_change.dart';
import 'package:sipged/_widgets/overlays/loading_progress.dart';
import 'package:sipged/screens/common/login/forgot/forgot_password_page.dart';
import 'package:sipged/screens/common/login/sign_in/sign_in_button.dart';

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

  late Gradient _bgGradient;

  bool _didLoadLastEmail = false;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passController = TextEditingController();

    _companyController = TextEditingController(text: SetupData.defaultModuleLabel);

    _emailFocus = FocusNode();
    _passFocus = FocusNode();

    _bgGradient = SetupData.gradientForModule(SetupData.defaultModuleLabel);

    _emailController.addListener(() {
      final has = _emailController.text.trim().isNotEmpty;
      if (has != _hasEmail) setState(() => _hasEmail = has);

      context.read<LoginCubit>().changeEmail(_emailController.text);
    });

    _passController.addListener(() {
      context.read<LoginCubit>().changePassword(_passController.text);
    });

    _companyController.addListener(() {
      final selected = _companyController.text.trim();
      setState(() => _bgGradient = SetupData.gradientForModule(selected));
      context.read<LoginCubit>().changeSelectedArea(selected);
    });

    // garante que a área default foi registrada no cubit
    context.read<LoginCubit>().changeSelectedArea(_companyController.text.trim());

    // ✅ carrega o último email e preenche o campo
    _loadLastEmailIntoField();
  }

  Future<void> _loadLastEmailIntoField() async {
    if (_didLoadLastEmail) return;
    _didLoadLastEmail = true;

    final cubit = context.read<LoginCubit>();
    final savedEmail = await cubit.loadLastEmail();

    if (!mounted) return;

    if (savedEmail != null && savedEmail.trim().isNotEmpty) {
      _emailController.text = savedEmail.trim();
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailController.text.length),
      );

      setState(() => _hasEmail = true);

      // foco direto na senha
      _passFocus.requestFocus();
    } else {
      _emailFocus.requestFocus();
    }
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
    context.read<LoginCubit>().signIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, st) {
          final isLoading = st.isLoading;

          return Container(
            decoration: BoxDecoration(gradient: _bgGradient),
            child: Stack(
              children: [
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = MediaQuery.of(context).size.width;
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
            DropDownChange(
              width: double.infinity,
              controller: _companyController,
              labelText: 'Módulo',
              enabled: false,
              items: SetupData.moduleName,
            ),
            /*BlocBuilder<LoginCubit, LoginState>(
              buildWhen: (a, b) => a.areaAccessStatus != b.areaAccessStatus || a.data.selectedArea != b.data.selectedArea,
              builder: (context, st) {
                final status = st.areaAccessStatus;
                final selected = (st.data.selectedArea ?? '').trim();

                if (selected.isEmpty || status == AreaAccessStatus.idle) {
                  return const SizedBox(height: 4);
                }

                if (status == AreaAccessStatus.needEmail) {
                  return Row(
                    children: const [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('Informe o e-mail', style: TextStyle(fontSize: 12, color: Colors.blue)),
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
                        style: TextStyle(fontSize: 12, color: hasAccess ? Colors.green : Colors.red),
                      ),
                    ),
                  ],
                );
              },
            ),
*/
            const SizedBox(height: 24),
            CustomTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _passFocus.requestFocus(),
              autofillHints: const [AutofillHints.username],
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) {},
              enabled: true,
              suffix: _hasEmail
                  ? IconButtonChange(
                radius: 28,
                iconData: Icons.clear,
                onTap: () {
                  _emailController.clear();
                  _emailFocus.requestFocus();
                },
              )
                  : null,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _passController,
              focusNode: _passFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitIfPossible(),
              autofillHints: const [AutofillHints.password],
              labelText: 'Senha',
              hintText: '••••••••',
              obscure: _inputObscure,
              onChanged: (_) {},
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

            // ✅ agora navega para a tela dedicada
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                  );
                },
                child: const Text('Esqueci a senha', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 6),
            const SignInButton(),
            const SizedBox(height: 6),
            BlocBuilder<LoginCubit, LoginState>(
              buildWhen: (a, b) => a.errorMessage != b.errorMessage || a.status != b.status,
              builder: (_, st) {
                final err = st.errorMessage;
                if (err != null && err.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      err,
                      style: const TextStyle(color: Colors.red),
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
