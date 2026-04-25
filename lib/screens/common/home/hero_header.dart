import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/setup/setup_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots_grey.dart';

class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.user,
  });

  final UserData? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Colors.blue.shade900;

    return BlocBuilder<SetupCubit, SetupState>(
      builder: (context, setupState) {
        final company = setupState.companyProfile;

        final razaoSocial = (company?.companyName ?? '').trim().isNotEmpty
            ? company!.companyName!.trim()
            : 'SipGed';

        final nomeFantasia = (company?.fantasyName ?? '').trim().isNotEmpty
            ? company!.fantasyName!.trim()
            : 'Sistema Integrado de Planejamento e Gestão de Dados';

        final logoUrl = (company?.logoUrl ?? '').trim();

        return Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.center,
              children: [
                _CompanyLogo(
                  logoUrl: logoUrl,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        razaoSocial,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: .5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nomeFantasia,
                        textAlign: TextAlign.start,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: accent.withValues(alpha: .85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: .06),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
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
      },
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({
    required this.logoUrl,
  });

  final String logoUrl;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    if (logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(
          width: 88,
          height: 88,
          child: Image.network(
            logoUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) {
              return _fallbackLogo(borderRadius);
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                width: 88,
                height: 88,
                child: LoadingTreeDotsGrey(
                  size: 22,
                  strokeWidth: 2,
                ),
              );
            },
          ),
        ),
      );
    }

    return _fallbackLogo(borderRadius);
  }

  Widget _fallbackLogo(BorderRadius borderRadius) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        'assets/logos/sipged/sipged.png',
        height: 88,
        width: 88,
        fit: BoxFit.contain,
      ),
    );
  }
}