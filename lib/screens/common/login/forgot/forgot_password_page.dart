import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_data.dart';

import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/images/logos/sisgeo_logo.dart';
import 'package:sipged/_widgets/input/custom_icon_button.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

// 🔔 Notificações centralizadas
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final TextEditingController _emailCtrl;
  late final FocusNode _emailFocus;

  bool _hasEmail = false;
  bool _loading = false;
  bool _didPreload = false;

  late final TextEditingController _companyController;
  late Gradient _bgGradient;

  @override
  void initState() {
    super.initState();

    _emailCtrl = TextEditingController();
    _emailFocus = FocusNode();

    _companyController = TextEditingController(text: SetupData.defaultModuleLabel);
    _bgGradient = SetupData.gradientForModule(SetupData.defaultModuleLabel);

    _emailCtrl.addListener(() {
      final has = _emailCtrl.text.trim().isNotEmpty;
      if (has != _hasEmail) setState(() => _hasEmail = has);
    });

    // carrega o último e-mail salvo (se houver)
    _preloadEmail();
  }

  Future<void> _preloadEmail() async {
    if (_didPreload) return;
    _didPreload = true;

    final cubit = context.read<LoginCubit>();
    final last = await cubit.loadLastEmail();

    if (!mounted) return;

    if (last != null && last.trim().isNotEmpty) {
      _emailCtrl.text = last.trim();
      _emailCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _emailCtrl.text.length),
      );
      setState(() => _hasEmail = true);
    } else {
      _emailFocus.requestFocus();
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _emailFocus.dispose();
    _companyController.dispose();
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

  bool _isValidEmail(String email) {
    final e = email.trim();
    if (e.isEmpty) return false;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim().toLowerCase();

    if (!_isValidEmail(email)) {
      _notify(
        'Informe um e-mail válido',
        subtitle: 'Ex: usuario@dominio.com',
        type: AppNotificationType.error,
      );
      _emailFocus.requestFocus();
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<LoginCubit>().recoverPass(email);

      if (!mounted) return;

      _notify(
        'Link de redefinição enviado',
        subtitle: 'Verifique sua caixa de entrada (e spam).',
        type: AppNotificationType.success,
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _notify(
        'Não foi possível enviar o link',
        subtitle: '$e',
        type: AppNotificationType.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: UpBar(
          showPhotoMenu: false,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: BackCircleButton(),
          ),
        ),
      ),
      body: Container(
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

                                // ✅ Logo igual ao SignIn
                                const SiGedLogo(),
                                const SizedBox(height: 24),

                                _buildForgotCard(context),

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

            if (_loading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.6,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Enviando...",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotCard(BuildContext context) {
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
              onSubmitted: (_) => _loading ? null : _send(),
              labelText: 'E-mail',
              hintText: 'Digite seu e-mail',
              keyboardType: TextInputType.emailAddress,
              enabled: !_loading,
              suffix: _hasEmail
                  ? CustomIconButton(
                radius: 28,
                iconData: Icons.clear,
                onTap: _loading
                    ? null
                    : () {
                  _emailCtrl.clear();
                  _emailFocus.requestFocus();
                },
              )
                  : null,
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.withOpacity(0.35),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
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
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Voltar para o login', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
