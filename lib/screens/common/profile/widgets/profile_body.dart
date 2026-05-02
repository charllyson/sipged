import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/screens/common/profile/widgets/profile_hero.dart';
import 'package:sipged/screens/common/profile/widgets/profile_overview_card.dart';
import 'package:sipged/screens/common/profile/widgets/profile_settings_list.dart';

class ProfileBody extends StatelessWidget {
  const ProfileBody({
    super.key,
    required this.user,
    required this.displayName,
  });

  final UserData user;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 960;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isWide ? 32 : 16,
            18,
            isWide ? 32 : 16,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHero(
                    user: user,
                    displayName: displayName,
                    currentPhoto: user.urlPhoto,
                    previewBytes: null,
                    hasChanges: false,
                    showEditButton: false,
                  ),
                  const SizedBox(height: 18),
                  ProfileOverviewCard(user: user),
                  const SizedBox(height: 18),
                  ProfileSettingsList(user: user),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}