import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/login/login_bloc.dart';

class SignInButton extends StatelessWidget {
  final LoginBloc loginBloc;
  const SignInButton({super.key, required this.loginBloc});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<bool>(
          // ✅ só valida email+senha; não depende do módulo
          stream: loginBloc.outSubmitValidaEmailPass,
          builder: (context, canSnap) {
            return StreamBuilder<LoginState>(
              stream: loginBloc.outState,
              builder: (context, stateSnap) {
                final isLoading = stateSnap.data == LoginState.loading;
                final canSubmit = (canSnap.data == true) && !isLoading;

                return SizedBox(
                  height: 44,
                  width: 150,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: canSubmit
                        ? () {
                      FocusScope.of(context).unfocus();
                      loginBloc.signIn(); // verificação de módulo fica no signIn()
                    }
                        : null,
                    child: isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Text('Entrar', style: TextStyle(color: Colors.white)),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
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
  }
}
