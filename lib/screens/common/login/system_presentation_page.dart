import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/images/logos/sipged_logo.dart';

class SystemPresentationPage extends StatelessWidget {
  const SystemPresentationPage({super.key});

  static const Gradient _pageGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 27, 32, 51),
      Color.fromARGB(255, 39, 105, 236),
      Color.fromARGB(255, 144, 202, 249),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Color _darkColor = Color(0xFF101828);
  static const Color _mutedColor = Color(0xFF475467);

  static Future<void> openWhatsAppPresentation() async {
    final message = Uri.encodeComponent(
      'Olá! Tenho interesse em conhecer o SIPGED para empresas e gostaria de solicitar uma apresentação.',
    );

    final uri = Uri.parse(
      'https://wa.me/5582999391906?text=$message',
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!opened) {
      throw Exception('Não foi possível abrir o WhatsApp.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final compact = width < 720;
            final veryCompact = width < 460;

            final maxContentWidth = compact ? width : 1120.0;

            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: _pageGradient,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxContentWidth,
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 14 : 20,
                            compact ? 12 : 20,
                            compact ? 14 : 20,
                            compact ? 32 : 48,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _TopActions(
                                compact: compact,
                              ),
                              SizedBox(height: compact ? 24 : 38),
                              _HeroSection(
                                compact: compact,
                                veryCompact: veryCompact,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxContentWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 14 : 20,
                          compact ? 22 : 36,
                          compact ? 14 : 20,
                          36,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _BenefitsGrid(compact: compact),
                            SizedBox(height: compact ? 16 : 22),
                            const _ModulesSection(),
                            SizedBox(height: compact ? 16 : 22),
                            _CallToActionCard(compact: compact),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopActions extends StatelessWidget {
  const _TopActions({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleButtonChange(
          icon: Icons.arrow_back,
          tooltip: 'Voltar',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            foregroundColor: Colors.white,
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.34),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 18,
              vertical: compact ? 10 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          onPressed: SystemPresentationPage.openWhatsAppPresentation,
          child: Text(
            compact ? 'Conhecer' : 'SIPGED para empresas',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.compact,
    required this.veryCompact,
  });

  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 22 : 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(compact ? 26 : 32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 38,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: compact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroText(
            compact: compact,
            veryCompact: veryCompact,
          ),
          const SizedBox(height: 26),
          _LogoBox(
            compact: compact,
          ),
        ],
      )
          : Row(
        children: [
          Expanded(
            flex: 6,
            child: _HeroText(
              compact: compact,
              veryCompact: veryCompact,
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 4,
            child: _LogoBox(
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({
    required this.compact,
    required this.veryCompact,
  });

  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!veryCompact)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.32),
              ),
            ),
            child: const Text(
              'Gestão, dados e território em uma única plataforma',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        if (!veryCompact) const SizedBox(height: 22),
        Text(
          'Transforme a operação da sua empresa com inteligência geoespacial.',
          style: TextStyle(
            color: Colors.white,
            fontSize: veryCompact
                ? 28
                : compact
                ? 31
                : 40,
            height: 1.06,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'O SIPGED centraliza contratos, mapas e indicadores estratégicos em uma estrutura personalizada para empresas e órgãos que precisam enxergar, controlar e decidir melhor.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontSize: compact ? 15 : 17,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: const [
            _HeroTag('Mapas'),
            _HeroTag('Dashboards'),
            _HeroTag('IA'),
            _HeroTag('Geodados'),
          ],
        ),
      ],
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 180,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF12337A),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRect(
        child: SizedBox(
          width: compact ? 260 : 360,
          height: compact ? 120 : 160,
          child: const FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: SizedBox(
              width: 360,
              child: SipgedLogo(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitsGrid extends StatelessWidget {
  const _BenefitsGrid({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _BenefitCard(
        icon: Icons.map_rounded,
        title: 'Geointeligência',
        description:
        'Visualize contratos, obras, ativos e regiões diretamente no mapa.',
      ),
      _BenefitCard(
        icon: Icons.dashboard_customize_rounded,
        title: 'Dashboards vivos',
        description:
        'Monte seu próprio Dashboard com dados espaciais conectados aos dados reais.',
      ),
      _BenefitCard(
        icon: Icons.admin_panel_settings_rounded,
        title: 'Controle por perfil',
        description:
        'Permissões por módulo, função e usuário para ambientes robustos e seguros.',
      ),
    ];

    if (compact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i != cards.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 720;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: compact ? 190 : 176,
      ),
      padding: EdgeInsets.all(compact ? 22 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1D4ED8),
                  Color(0xFF60A5FA),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: SystemPresentationPage._darkColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            softWrap: true,
            style: const TextStyle(
              color: SystemPresentationPage._mutedColor,
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulesSection extends StatelessWidget {
  const _ModulesSection();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 720;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 24,
        compact ? 22 : 24,
        compact ? 20 : 24,
        compact ? 22 : 26,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uma base. Vários módulos. Escala real.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'O sistema pode evoluir por módulos, permitindo que cada empresa comece com uma necessidade específica e amplie a plataforma conforme a operação cresce.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _ModuleChip(
                icon: Icons.assignment_rounded,
                label: 'Contratos',
              ),
              _ModuleChip(
                icon: Icons.timeline_rounded,
                label: 'Cronogramas',
              ),
              _ModuleChip(
                icon: Icons.payments_rounded,
                label: 'Financeiro',
              ),
              _ModuleChip(
                icon: Icons.traffic_rounded,
                label: 'Trânsito',
              ),
              _ModuleChip(
                icon: Icons.location_on_rounded,
                label: 'Ativos',
              ),
              _ModuleChip(
                icon: Icons.insights_rounded,
                label: 'Indicadores',
              ),
              _ModuleChip(
                icon: Icons.notifications_active_rounded,
                label: 'Alertas',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  const _ModuleChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 190,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF93C5FD),
            size: 18,
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallToActionCard extends StatelessWidget {
  const _CallToActionCard({
    required this.compact,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        shadowColor: Colors.orange.shade900,
        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 15,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      onPressed: SystemPresentationPage.openWhatsAppPresentation,
      icon: const Icon(Icons.handshake_rounded),
      label: const Text(
        'Solicitar apresentação',
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.all(compact ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE4E7EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: compact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CallToActionText(),
          const SizedBox(height: 16),
          button,
        ],
      )
          : Row(
        children: [
          const Expanded(
            child: _CallToActionText(),
          ),
          const SizedBox(width: 22),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: button,
            ),
          ),
        ],
      ),
    );
  }
}

class _CallToActionText extends StatelessWidget {
  const _CallToActionText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Queremos te ouvir, solicite uma apresentação para conhecer o SIPGED.',
      style: TextStyle(
        color: Color(0xFF344054),
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}