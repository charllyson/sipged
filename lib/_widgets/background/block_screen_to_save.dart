import 'package:flutter/material.dart';

import '../../_blocs/login/login_bloc.dart';
import '../../_blocs/user/user_bloc.dart';
import '../loading/loading_progress.dart';

class BlockScreenToSave extends StatelessWidget {
  const BlockScreenToSave({super.key, this.userBloc, this.loginBloc});
  final UserBloc? userBloc;
  final LoginBloc? loginBloc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: userBloc?.outLoading ?? loginBloc?.outLoading,
      initialData: false,
      builder: (context, snapshot) {
        return IgnorePointer(
          ignoring: !snapshot.data!,
          child: Container(
            color:
            snapshot.data!
                ? Colors.black54
                : Colors.transparent,
            child:
            snapshot.data! ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LoadingProgress(),
                const Text(
                  "Salvando os dados ...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ],
            )
                : Container(),
          ),
        );
      },
    );
  }
}
