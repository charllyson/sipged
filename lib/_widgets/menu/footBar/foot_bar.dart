// lib/_widgets/menu/footBar/foot_bar.dart

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/ia/ai_chat_sheet.dart';
import 'package:sipged/_widgets/ia/ai_futuristic_button.dart';

import 'package:sipged/screens/common/login/sign_up/sign_up.dart';
import 'package:sipged/screens/common/login/sign_up/sign_up_data.dart';

enum FootBarMode {
  defaultMode,
  signIn,
}

class FootBar extends StatefulWidget {
  const FootBar({
    super.key,
    this.mode = FootBarMode.defaultMode,
  });

  final FootBarMode mode;

  @override
  State<FootBar> createState() => _FootBarState();
}

class _FootBarState extends State<FootBar> {
  bool _showIaProgress = false;

  bool get _isSignInMode => widget.mode == FootBarMode.signIn;

  Future<void> _openAiChat(BuildContext context) async {
    setState(() {
      _showIaProgress = true;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiChatSheet(),
    );

    if (!mounted) return;

    setState(() {
      _showIaProgress = false;
    });
  }

  Future<void> _openSignUp(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUp(
          userData: UserData.empty(),
          mode: SignUpMode.selfRegister,
        ),
      ),
    );
  }

  Widget _buildSignInContent(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 2,
        children: [
          const Text(
            'Ainda não tem conta?',
            style: TextStyle(
              color: Color(0xFF475467),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 0,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _openSignUp(context),
            child: const Text(
              'Cadastre-se',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context) {
    const textStyle = TextStyle(
      color: Color(0xFF475467),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    );

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 72),
            child: FutureBuilder<int>(
              future: null,
              builder: (context, snapshot) {
                final buildText =
                snapshot.hasData ? ' • Build nº ${snapshot.data}' : '';

                return Text(
                  'Desenvolvido por C.A.S Engenharia & Tecnologia • Versão 1.0.0$buildText',
                  style: textStyle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Center(
            child: AiFuturisticButton(
              onTap: () => _openAiChat(context),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _showIaProgress && !_isSignInMode
                  ? LinearProgressIndicator(
                key: const ValueKey('ia-progress'),
                minHeight: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade200,
                ),
                backgroundColor: Colors.transparent,
              )
                  : const SizedBox(
                key: ValueKey('no-progress'),
              ),
            ),
          ),
          BasicCard(
            isDark: isDark,
            height: _isSignInMode ? 42 : 35,
            padding: EdgeInsets.symmetric(
              vertical: _isSignInMode ? 6 : 3,
              horizontal: _isSignInMode ? 10 : 6,
            ),
            borderRadius: 0,
            useGlassEffect: false,
            backgroundColor: Colors.white,
            gradient: null,
            borderColor: const Color(0xFFE4E7EC),
            enableShadow: false,
            child: _isSignInMode
                ? _buildSignInContent(context)
                : _buildDefaultContent(context),
          ),
        ],
      ),
    );
  }
}