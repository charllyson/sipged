// lib/screens/common/login/forgot/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';
import 'package:sipged/_widgets/images/logos/sipged_logo.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/screens/common/login/forgot/forgot_cubit.dart';
import 'package:sipged/screens/common/login/forgot/forgot_state.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({
    super.key,
    ForgotCubit? cubit,
  }) : _externalCubit = cubit;

  final ForgotCubit? _externalCubit;

  static const Gradient _defaultGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 27, 32, 51),
      Color.fromARGB(255, 144, 202, 249),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final externalCubit = _externalCubit;

    if (externalCubit != null) {
      externalCubit.preloadLastEmail();

      return BlocProvider<ForgotCubit>.value(
        value: externalCubit,
        child: const _ForgotPasswordView(),
      );
    }

    return BlocProvider<ForgotCubit>(
      create: (_) => ForgotCubit()..preloadLastEmail(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  late final TextEditingController _emailCtrl;
  late final FocusNode _emailFocus;

  @override
  void initState() {
    super.initState();

    _emailCtrl = TextEditingController();
    _emailFocus = FocusNode();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();

    super.dispose();
  }

  void _notify(
      String title, {
        String? subtitle,
        NotificationStatus status = NotificationStatus.info,
      }) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: title,
        subtitle: subtitle,
        leadingLabel: 'Login',
        status: status,
        duration: const Duration(seconds: 4),
        extra: const <String, dynamic>{
          'module': 'forgot_password',
          'source': 'forgot_password_page',
        },
      ),
    );
  }

  Future<void> _send() async {
    final ok = await context.read<ForgotCubit>().send();

    if (!mounted) return;

    final forgotState = context.read<ForgotCubit>().state;

    if (ok) {
      _notify(
        forgotState.successMessage ?? 'Link de redefinição enviado',
        subtitle: 'Verifique sua caixa de entrada e spam.',
        status: NotificationStatus.success,
      );

      Navigator.of(context).pop();
      return;
    }

    final error = forgotState.errorMessage;

    if (error != null && error.trim().isNotEmpty) {
      _notify(
        'Não foi possível enviar o link',
        subtitle: error,
        status: NotificationStatus.error,
      );
    }

    _emailFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotCubit, ForgotState>(
      listenWhen: (previous, current) {
        return previous.data.email != current.data.email;
      },
      listener: (context, state) {
        if (_emailCtrl.text == state.data.email) return;

        _emailCtrl.text = state.data.email;
        _emailCtrl.selection = TextSelection.fromPosition(
          TextPosition(
            offset: _emailCtrl.text.length,
          ),
        );

        if (state.data.email.trim().isEmpty) {
          _emailFocus.requestFocus();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: UpBar(
            showPhotoMenu: false,
            leading: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: CircleButtonChange(
                icon: Icons.arrow_back,
                tooltip: 'Voltar',
                onPressed: state.isLoading
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: ForgotPasswordPage._defaultGradient,
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
                          constraints: BoxConstraints(
                            maxWidth: maxWidth,
                          ),
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
                                    const SizedBox(height: 24),
                                    _buildForgotCard(
                                      context: context,
                                      state: state,
                                    ),
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
                if (state.isLoading) const _ForgotLoadingOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForgotCard({
    required BuildContext context,
    required ForgotState state,
  }) {
    final hasEmail = state.data.email.trim().isNotEmpty;

    return BasicCard(
      isDark: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              'Recuperar senha',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 18),
            CustomTextField(
              controller: _emailCtrl,
              focusNode: _emailFocus,
              textInputAction: TextInputAction.done,
              onChanged: context.read<ForgotCubit>().changeEmail,
              onSubmitted: (_) {
                if (!state.isLoading) {
                  _send();
                }
              },
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              keyboardType: TextInputType.emailAddress,
              enabled: !state.isLoading,
              suffix: hasEmail
                  ? Padding(
                padding: const EdgeInsets.only(right: 6),
                child: SizedBox.square(
                  dimension: 28,
                  child: CircleButtonChange(
                    radius: 14,
                    iconSize: 18,
                    icon: Icons.clear,
                    tooltip: 'Limpar',
                    onPressed: state.isLoading
                        ? null
                        : () {
                      context.read<ForgotCubit>().clearEmail();
                      _emailFocus.requestFocus();
                    },
                  ),
                ),
              )
                  : null,
            ),
            if (state.errorMessage != null &&
                state.errorMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.canSubmit ? _send : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.withValues(alpha: 0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.isLoading
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingTreeDots(
                      size: 18,
                      strokeWidth: 2,
                      color: Colors.white,
                      centered: false,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Enviando...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
                    : const Text(
                  'Enviar link',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed:
              state.isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Voltar para o login',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgotLoadingOverlay extends StatelessWidget {
  const _ForgotLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingTreeDots(
              size: 22,
              strokeWidth: 2.6,
              color: Colors.white,
              centered: false,
            ),
            SizedBox(height: 12),
            Text(
              'Enviando...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}