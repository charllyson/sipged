import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';

import 'package:sipged/screens/common/profile/widgets/profile_body.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  String _composeDisplayName(UserData? user) {
    final name = (user?.name ?? '').trim();
    final surname = (user?.surname ?? '').trim();

    return [name, surname].where((e) => e.isNotEmpty).join(' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      buildWhen: (previous, current) {
        return previous.current != current.current ||
            previous.isLoadingUsers != current.isLoadingUsers;
      },
      builder: (context, state) {
        final user = state.current;

        return Scaffold(
          appBar: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12),
              child: CircleButtonChange(),
            ),
          ),
          body: Stack(
            children: [
              const BackgroundChange(),
              if (user == null)
                const Center(
                  child: LoadingTreeDots(size: 120),
                )
              else
                ProfileBody(
                  user: user,
                  displayName: _composeDisplayName(user),
                ),
            ],
          ),
        );
      },
    );
  }
}