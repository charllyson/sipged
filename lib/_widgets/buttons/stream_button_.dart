import 'package:flutter/material.dart';
import '../../_blocs/system/login_bloc.dart';

class StreamButton extends StatelessWidget {
  final LoginBloc loginBloc;

  const StreamButton({
    super.key,
    required this.loginBloc,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StreamBuilder<bool>(
          stream: loginBloc.outSubmitValidaEmailPass,
          builder: (context, snapshot) {
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
                    onPressed: (snapshot.hasData && !isLoading)
                        ? () {
                      FocusScope.of(context).unfocus();
                      loginBloc.signIn();
                    }
                        : null,
                    child: isLoading
                        ? SizedBox(
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
