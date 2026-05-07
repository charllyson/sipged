// lib/screens/common/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';

import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/draw/background/soft_bubbles.dart';

import 'package:sipged/screens/common/home/hero_header.dart';
import 'package:sipged/screens/common/modules/module_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onSelect,
  });

  final void Function(ModuleEnum item)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundChange(),
        const SoftBubbles(),
        BlocSelector<UserCubit, UserState, UserData?>(
          selector: (state) {
            return state.current;
          },
          builder: (context, user) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isWide = width >= 1180;
                final maxContentWidth = isWide ? 1180.0 : width;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        24,
                        20,
                        44,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SafeArea(
                            top: true,
                            child: HeroHeader(user: user),
                          ),
                          const SizedBox(height: 30),
                          ModuleGrid(
                            onSelect: onSelect,
                            user: user,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}