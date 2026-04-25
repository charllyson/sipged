import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/module/module_data.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/draw/background/soft_bubbles.dart';
import 'package:sipged/screens/common/home/hero_header.dart';
import 'package:sipged/screens/common/home/themed_actions_grid.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.onSelect,
  });

  final void Function(ModuleItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundChange(),
        const SoftBubbles(),
        BlocBuilder<UserCubit, UserState>(
          builder: (context, state) {
            final user = state.current;

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isWide = width >= 1180;
                final maxContentWidth = isWide ? 1180.0 : width;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 44),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SafeArea(
                            top: true,
                            child: HeroHeader(user: user),
                          ),
                          const SizedBox(height: 30),
                          ThemedActionsGrid(
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