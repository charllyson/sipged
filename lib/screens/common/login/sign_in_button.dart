import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/login/login_bloc.dart';

class SignInButton extends StatelessWidget {
  final LoginBloc loginBloc;
  const SignInButton({super.key, required this.loginBloc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      // ✅ só valida email+senha; não depende do módulo
      stream: loginBloc.outSubmitValidaEmailPass,
      builder: (context, canSnap) {
        return StreamBuilder<LoginState>(
          stream: loginBloc.outState,
          builder: (context, stateSnap) {
            final isLoading = stateSnap.data == LoginState.loading;
            final canSubmit = (canSnap.data == true) && !isLoading;

            return Column(
              children: [
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.blue.withOpacity(0.35),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: canSubmit
                        ? () {
                      FocusScope.of(context).unfocus();
                      loginBloc.signIn(); // verificação de módulo fica no signIn()
                    }
                        : null,
                    child: isLoading
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Entrando…',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                        : const Text(
                      'Entrar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<String?>(
                  stream: loginBloc.outLoginError,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && (snapshot.data?.isNotEmpty ?? false)) {
                      return Text(
                        snapshot.data!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
