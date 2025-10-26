import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:siged/_blocs/system/login/login_bloc.dart';

class StreamButton extends StatelessWidget {
  final LoginBloc loginBloc;

  const StreamButton({
    super.key,
    required this.loginBloc,
  });

  @override
  Widget build(BuildContext context) {
    // Habilita o botão somente quando:
    // 1) e-mail e senha estão válidos
    // 2) há acesso à área escolhida (preview true)
    final canSubmitStream = Rx.combineLatest2<bool, bool, bool>(
      loginBloc.outSubmitValidaEmailPass,
      loginBloc.outAreaAccessPreview,
          (formOk, areaOk) => formOk && areaOk,
    );

    return Column(
      children: [
        StreamBuilder<bool>(
          stream: canSubmitStream,
          builder: (context, canSnap) {
            return StreamBuilder<LoginState>(
              stream: loginBloc.outState,
              builder: (context, stateSnapshot) {
                final isLoading = stateSnapshot.data == LoginState.loading;

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
                    onPressed: (canSnap.data == true && !isLoading)
                        ? () {
                      FocusScope.of(context).unfocus();
                      loginBloc.signIn();
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
                        : const Text(
                      'Entrar',
                      style: TextStyle(color: Colors.white),
                    ),
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
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return Text(
                snapshot.data!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    );
  }
}
