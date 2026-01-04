import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/user/user_data.dart';
import 'package:siged/_widgets/menu/pop_up/pup_up_photo_menu.dart';


class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key, required this.user});
  final UserData? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Colors.blue.shade900;

    return Column(
      children: [
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/logos/siged/siged.png',
                height: 88,
                width: 88,
                fit: BoxFit.contain,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SipGed',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: .5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistema Integrado de Planejamento e Gestão de Dados',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: accent.withOpacity(.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (user?.name != null && user!.name!.trim().isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PopUpPhotoMenu(),
              const SizedBox(width: 4),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(.06)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Text(
                  'Olá, ${user!.name}!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}