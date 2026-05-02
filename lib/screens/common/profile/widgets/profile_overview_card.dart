import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/screens/common/profile/widgets/info_chip.dart';
import 'package:sipged/screens/common/profile/widgets/modern_card.dart';

class ProfileOverviewCard extends StatelessWidget {
  const ProfileOverviewCard({
    super.key,
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final role = (user.baseRole ?? '').trim();
    final profile = (user.baseProfile ?? '').trim();

    return ModernCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Resumo da conta',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              InfoChip(
                icon: Icons.email_rounded,
                text: user.email ?? 'sem e-mail',
              ),
              if (profile.isNotEmpty)
                InfoChip(
                  icon: Icons.admin_panel_settings_rounded,
                  text: profile,
                ),
              if (role.isNotEmpty)
                InfoChip(
                  icon: Icons.work_rounded,
                  text: role,
                ),
            ],
          ),
        ],
      ),
    );
  }
}