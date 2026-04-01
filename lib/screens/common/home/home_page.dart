// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/module/module_data.dart'; // MenuItem + PagesData
import 'package:sipged/screens/common/home/hero_header.dart';
import 'package:sipged/_widgets/draw/background/soft_bubbles.dart';
import 'package:sipged/screens/common/home/themed_actions_grid.dart'; // tipos do drawer

class HomeBody extends StatelessWidget {
  const HomeBody({super.key, this.onSelect});
  final void Function(ModuleItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundChange(),
        const SoftBubbles(),
        BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            final user = state.current;
            return LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth;
                final isWide = w >= 1080;
                final maxContentW = isWide ? 1080.0 : w;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentW),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SafeArea(top: true, child: HeroHeader(user: user)),
                          const SizedBox(height: 24),
                          ThemedActionsGrid(onSelect: onSelect, user: user),
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