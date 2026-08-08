// lib/screens/common/login/sign_in/sign_in.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/screens/common/login/sign_in/login_cubit.dart';
import 'package:sipged/screens/common/login/sign_in/login_state.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/images/logos/sipged_logo.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/footBar/foot_bar.dart';

import 'package:sipged/screens/common/login/forgot/forgot_password_page.dart';
import 'package:sipged/screens/common/login/sign_in/sign_in_button.dart';
import 'package:sipged/screens/common/login/sign_in/system_invite_floating_button.dart';
import 'package:sipged/screens/common/system_presentation_page.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  static const Gradient _defaultGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 27, 32, 51),
      Color.fromARGB(255, 144, 202, 249),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  late final TextEditingController _emailController;
  late final TextEditingController _passController;

  late final FocusNode _emailFocus;
  late final FocusNode _passFocus;

  bool _hasEmail = false;
  bool _inputObscure = true;
  bool _didLoadLastEmail = false;

  @override
  void initState() {
    super.initState();

    _emailController = TextEditingController();
    _passController = TextEditingController();

    _emailFocus = FocusNode();
    _passFocus = FocusNode();

    _emailController.addListener(_handleEmailChanged);
    _passController.addListener(_handlePasswordChanged);

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

    _emailFocus.dispose();
    _passFocus.dispose();

    _emailController.dispose();
    _passController.dispose();

    super.dispose();
  }

  void _submitIfPossible() {
    FocusScope.of(context).unfocus();
    context.read<LoginCubit>().signIn();
  }

  void _openSystemPresentationPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SystemPresentationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: false,
      bottomNavigationBar: const FootBar(
        mode: FootBarMode.signIn,
      ),
      body: BlocBuilder<LoginCubit, LoginState>(
        builder: (context, state) {
          final isLoading = state.isLoading;

          return Container(
            decoration: const BoxDecoration(
              gradient: _defaultGradient,
            ),
            child: Stack(
              children: [
                SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = MediaQuery.of(context).size.width;
                      final compact = width < 520;

                      final maxWidth = compact ? 382.0 : 420.0;

                      final horizontalPagePadding = compact ? 14.0 : 18.0;
                      final topPadding = compact ? 14.0 : 16.0;
                      final bottomPadding = compact ? 14.0 : 16.0;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxWidth,
                          ),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.only(
                              left: horizontalPagePadding,
                              right: horizontalPagePadding,
                              top: topPadding,
                              bottom: bottomPadding +
                                  MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight -
                                    topPadding -
                                    bottomPadding,
                              ),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: compact ? 6 : 8),
                                    Transform.scale(
                                      scale: compact ? 0.92 : 1.0,
                                      child: const SipgedLogo(),
                                    ),
                                    SizedBox(height: compact ? 14 : 16),
                                    _buildLoginCard(context),
                                    const Spacer(),
                                    SizedBox(height: compact ? 8 : 12),
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
                Positioned(
                  right: 18,
                  bottom: 20,
                  child: SafeArea(
                    child: SystemInviteFloatingButton(
                      onPressed: _openSystemPresentationPage,
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
    final width = MediaQuery.of(context).size.width;
    final compact = width < 520;

    return BasicCard(
      isDark: false,
      backgroundColor: Colors.white,
      gradient: null,
      borderColor: Colors.white.withValues(alpha: 0.92),
      borderRadius: 24,
      enableShadow: true,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: compact ? 0.14 : 0.16,
          ),
          blurRadius: compact ? 22 : 26,
          offset: Offset(0, compact ? 10 : 12),
        ),
      ],
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 4 : 8,
                  vertical: compact ? 4 : 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
          SizedBox(height: compact ? 10 : 6),
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
                  padding: const EdgeInsets.only(top: 8),
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
    );
  }
}