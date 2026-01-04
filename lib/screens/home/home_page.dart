// lib/screens/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/menu/footBar/foot_bar.dart';
import 'package:siged/_widgets/images/photo_circle/photo_circle.dart';
import 'package:siged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:siged/_widgets/menu/upBar/up_bar.dart';
import 'package:siged/_widgets/background/background_cleaner.dart';

import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_state.dart';
import 'package:siged/_blocs/system/pages/pages_data.dart'; // MenuItem + PagesData
import 'package:siged/_blocs/system/permitions/page_permission.dart' as perms;
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/menu/drawer/menu_drawer_item.dart';
import 'package:siged/screens/home/hero_header.dart';
import 'package:siged/screens/home/soft_bubbles.dart';
import 'package:siged/screens/home/themed_actions_grid.dart'; // tipos do drawer

class HomeBody extends StatelessWidget {
  const HomeBody({super.key, this.onSelect});
  final void Function(MenuItem item)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const BackgroundClean(),
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