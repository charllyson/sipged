import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_area_config.dart';
import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/images/logos/sipged_logo.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/dropdown/drop_down_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/screens/common/login/forgot/forgot_password_page.dart';
import 'package:sipged/screens/common/login/sign_in/sign_in_button.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  late final TextEditingController _emailController;
  late final TextEditingController _areaController;
  late final TextEditingController _passController;

  late final FocusNode _emailFocus;
  late final FocusNode _passFocus;

  bool _hasEmail = false;
  bool _inputObscure = true;
  bool _didLoadLastEmail = false;

  late Gradient _bgGradient;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passController = TextEditingController();

    _areaController = TextEditingController(
      text: AppAreaConfig.defaultAreaLabel,
    );

    _emailFocus = FocusNode();
    _passFocus = FocusNode();

    _bgGradient = AppAreaConfig.gradientForArea(
      AppAreaConfig.defaultAreaLabel,
    );

    _emailController.addListener(_handleEmailChanged);
    _passController.addListener(_handlePasswordChanged);
    _areaController.addListener(_handleAreaChanged);

    context.read<LoginCubit>().changeSelectedArea(
      _areaController.text.trim(),
    );

    _loadLastEmailIntoField();
  }

  void _handleEmailChanged() {
    final email = _emailController.text.trim();
    final has = email.isNotEmpty;

    if (has != _hasEmail) {
      setState(() => _hasEmail = has);
    }

    context.read<LoginCubit>().changeEmail(email);
  }

  void _handlePasswordChanged() {
    context.read<LoginCubit>().changePassword(_passController.text);
  }

  void _handleAreaChanged() {
    final selected = _areaController.text.trim();

    setState(() {
      _bgGradient = AppAreaConfig.gradientForArea(selected);
    });

    context.read<LoginCubit>().changeSelectedArea(selected);
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

      _passFocus.requestFocus();
    } else {
      _emailFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleEmailChanged);
    _passController.removeListener(_handlePasswordChanged);
    _areaController.removeListener(_handleAreaChanged);

    _emailFocus.dispose();
    _passFocus.dispose();

    _emailController.dispose();
    _passController.dispose();
    _areaController.dispose();

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
        builder: (context, state) {
          final isLoading = state.isLoading;

          return Container(
            decoration: BoxDecoration(
              gradient: _bgGradient,
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = MediaQuery.of(context).size.width;
                      final maxWidth = width >= 520 ? 420.0 : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: 22,
                              right: 22,
                              top: 18,
                              bottom:
                              18 + MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    const SipgedLogo(),
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
                          LoadingTreeDots(),
                          SizedBox(height: 12),
                          Text(
                            'Entrando...',
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
              controller: _areaController,
              labelText: 'Área',
              enabled: false,
              items: AppAreaConfig.areaNames,
            ),
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
              enabled: true,
              suffix: _hasEmail
                  ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox.square(
                  dimension: 28,
                  child: CircleButtonChange(
                    radius: 14,
                    iconSize: 18,
                    icon: Icons.clear,
                    tooltip: 'Limpar',
                    onPressed: () {
                      _emailController.clear();
                      _emailFocus.requestFocus();
                    },
                  ),
                ),
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
              enabled: true,
              suffix: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox.square(
                  dimension: 28,
                  child: CircleButtonChange(
                    radius: 14,
                    iconSize: 18,
                    icon: _inputObscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    tooltip: _inputObscure ? 'Mostrar' : 'Ocultar',
                    onPressed: () {
                      setState(() {
                        _inputObscure = !_inputObscure;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordPage(),
                    ),
                  );
                },
                child: const Text(
                  'Esqueci a senha',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const SignInButton(),
            const SizedBox(height: 6),
            BlocBuilder<LoginCubit, LoginState>(
              buildWhen: (previous, current) {
                return previous.errorMessage != current.errorMessage ||
                    previous.status != current.status;
              },
              builder: (_, state) {
                final error = state.errorMessage;

                if (error != null && error.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      error,
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