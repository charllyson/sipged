// lib/screens/common/subscription/system_plans_page.dart

import 'dart:ui';

import 'package:flutter/material.dart';

enum SystemPlanInterval {
  monthly,
  yearly,
}

class SystemPlanData {
  const SystemPlanData({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.highlightLabel,
    required this.features,
    required this.color,
    required this.icon,
    this.recommended = false,
    this.enterprise = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final String highlightLabel;
  final List<String> features;
  final Color color;
  final IconData icon;
  final bool recommended;
  final bool enterprise;
}

class _PlanUi {
  static const Color pageStart = Color(0xFFF8FAFC);
  static const Color pageMiddle = Color(0xFFF1F5F9);
  static const Color pageEnd = Color(0xFFEFF6FF);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF64748B);

  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
}

class SystemPlansPage extends StatefulWidget {
  const SystemPlansPage({
    super.key,
    this.currentPlanId,
    this.initialSelectedPlanId,
    this.dialogMode = false,
    this.blockedMode = false,
    this.reasonTitle,
    this.reasonMessage,
    this.onClose,
    this.onPlanSelected,
    this.onContinue,
  });

  final String? currentPlanId;
  final String? initialSelectedPlanId;

  /// true quando for aberto dentro de Dialog.
  final bool dialogMode;

  /// true quando o usuário não pode continuar sem contratar/regularizar.
  final bool blockedMode;

  final String? reasonTitle;
  final String? reasonMessage;

  final VoidCallback? onClose;

  /// Chamado ao clicar em um plano.
  final ValueChanged<SystemPlanData>? onPlanSelected;

  /// Chamado ao clicar no botão principal.
  final ValueChanged<SystemPlanData>? onContinue;

  @override
  State<SystemPlansPage> createState() => _SystemPlansPageState();

  static Future<SystemPlanData?> openAsDialog({
    required BuildContext context,
    String? currentPlanId,
    String? initialSelectedPlanId,
    bool blockedMode = false,
    String? reasonTitle,
    String? reasonMessage,
    ValueChanged<SystemPlanData>? onPlanSelected,
    ValueChanged<SystemPlanData>? onContinue,
  }) {
    return showDialog<SystemPlanData>(
      context: context,
      barrierDismissible: !blockedMode,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(18),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1180,
              maxHeight: 820,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Material(
                color: Colors.transparent,
                child: SystemPlansPage(
                  currentPlanId: currentPlanId,
                  initialSelectedPlanId: initialSelectedPlanId,
                  dialogMode: true,
                  blockedMode: blockedMode,
                  reasonTitle: reasonTitle,
                  reasonMessage: reasonMessage,
                  onPlanSelected: onPlanSelected,
                  onContinue: (plan) {
                    onContinue?.call(plan);
                    Navigator.of(dialogContext).pop(plan);
                  },
                  onClose: blockedMode
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SystemPlansPageState extends State<SystemPlansPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late String _selectedPlanId;
  SystemPlanInterval _interval = SystemPlanInterval.monthly;

  final List<SystemPlanData> _plans = const <SystemPlanData>[
    SystemPlanData(
      id: 'starter',
      name: 'Essencial',
      subtitle: 'Para iniciar a gestão digital',
      description:
      'Ideal para pequenos times que precisam organizar contratos, dados e documentos com segurança.',
      monthlyPrice: 497,
      yearlyPrice: 4970,
      highlightLabel: 'Entrada estratégica',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFF4F46E5),
      features: <String>[
        'Gestão básica de contratos',
        'Cadastro de usuários e permissões',
        'Painel inicial de indicadores',
        'Upload de documentos PDF',
        'Suporte por e-mail',
      ],
    ),
    SystemPlanData(
      id: 'professional',
      name: 'Profissional',
      subtitle: 'Para órgãos e empresas em operação',
      description:
      'Plano recomendado para quem precisa controlar contratos, medições, aditivos, mapas e painéis executivos.',
      monthlyPrice: 1297,
      yearlyPrice: 12970,
      highlightLabel: 'Mais escolhido',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF0EA5E9),
      recommended: true,
      features: <String>[
        'Contratos, medições, aditivos e apostilamentos',
        'Dashboards executivos e gráficos interativos',
        'Mapa georreferenciado de obras e regiões',
        'Notificações internas do sistema',
        'Permissões por módulo e perfil',
        'Suporte prioritário',
      ],
    ),
    SystemPlanData(
      id: 'enterprise',
      name: 'Enterprise',
      subtitle: 'Para operação completa e expansão',
      description:
      'Para instituições que precisam de módulos personalizados, múltiplas unidades, integrações e escala.',
      monthlyPrice: 0,
      yearlyPrice: 0,
      highlightLabel: 'Sob medida',
      icon: Icons.domain_rounded,
      color: Color(0xFF10B981),
      enterprise: true,
      features: <String>[
        'Todos os módulos do plano Profissional',
        'Multiempresa / multiunidade',
        'Módulos personalizados',
        'Integrações com Firebase, APIs e serviços externos',
        'Treinamento da equipe',
        'Acompanhamento estratégico',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _selectedPlanId = widget.initialSelectedPlanId ??
        widget.currentPlanId ??
        _plans.firstWhere((p) => p.recommended).id;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  SystemPlanData get _selectedPlan {
    return _plans.firstWhere(
          (plan) => plan.id == _selectedPlanId,
      orElse: () => _plans.firstWhere((plan) => plan.recommended),
    );
  }

  String _formatPrice(SystemPlanData plan) {
    if (plan.enterprise) return 'Sob consulta';

    final value = _interval == SystemPlanInterval.monthly
        ? plan.monthlyPrice
        : plan.yearlyPrice;

    final formatted = value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );

    return 'R\$ $formatted';
  }

  String _formatInterval(SystemPlanData plan) {
    if (plan.enterprise) return 'proposta personalizada';

    return _interval == SystemPlanInterval.monthly ? '/mês' : '/ano';
  }

  String _savingText(SystemPlanData plan) {
    if (plan.enterprise) return 'Atendimento consultivo';

    if (_interval == SystemPlanInterval.yearly) {
      final monthlyTotal = plan.monthlyPrice * 12;
      final saving = monthlyTotal - plan.yearlyPrice;
      if (saving <= 0) return 'Plano anual';
      return 'Economize R\$ ${saving.toStringAsFixed(0)} no ano';
    }

    return 'Cancele ou altere quando precisar';
  }

  void _selectPlan(SystemPlanData plan) {
    setState(() => _selectedPlanId = plan.id);
    widget.onPlanSelected?.call(plan);
  }

  void _continue() {
    widget.onContinue?.call(_selectedPlan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _PremiumBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 920;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 18 : 34,
                    widget.dialogMode ? 18 : 28,
                    isCompact ? 18 : 34,
                    34,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeOut,
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.035),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeaderSection(
                                dialogMode: widget.dialogMode,
                                blockedMode: widget.blockedMode,
                                reasonTitle: widget.reasonTitle,
                                reasonMessage: widget.reasonMessage,
                                onClose: widget.onClose,
                              ),
                              const SizedBox(height: 22),
                              _BillingSwitch(
                                interval: _interval,
                                onChanged: (value) {
                                  setState(() => _interval = value);
                                },
                              ),
                              const SizedBox(height: 22),
                              _PlansGrid(
                                plans: _plans,
                                currentPlanId: widget.currentPlanId,
                                selectedPlanId: _selectedPlanId,
                                interval: _interval,
                                isCompact: isCompact,
                                priceBuilder: _formatPrice,
                                intervalBuilder: _formatInterval,
                                savingBuilder: _savingText,
                                onSelected: _selectPlan,
                              ),
                              const SizedBox(height: 24),
                              _SelectedPlanSummary(
                                plan: _selectedPlan,
                                currentPlanId: widget.currentPlanId,
                                price: _formatPrice(_selectedPlan),
                                interval: _formatInterval(_selectedPlan),
                                blockedMode: widget.blockedMode,
                                onContinue: _continue,
                              ),
                              const SizedBox(height: 16),
                              const _TrustSection(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _PlanUi.pageStart,
                _PlanUi.pageMiddle,
                _PlanUi.pageEnd,
              ],
            ),
          ),
        ),
        Positioned(
          top: -160,
          left: -120,
          child: _BlurCircle(
            size: 360,
            color: const Color(0xFF93C5FD).withValues(alpha: 0.34),
          ),
        ),
        Positioned(
          top: 130,
          right: -140,
          child: _BlurCircle(
            size: 400,
            color: const Color(0xFF99F6E4).withValues(alpha: 0.32),
          ),
        ),
        Positioned(
          bottom: -190,
          left: 160,
          child: _BlurCircle(
            size: 430,
            color: const Color(0xFFC4B5FD).withValues(alpha: 0.26),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: _GridPainter(),
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A).withValues(alpha: 0.035)
      ..strokeWidth = 1;

    const spacing = 42.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.dialogMode,
    required this.blockedMode,
    required this.reasonTitle,
    required this.reasonMessage,
    required this.onClose,
  });

  final bool dialogMode;
  final bool blockedMode;
  final String? reasonTitle;
  final String? reasonMessage;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final title = reasonTitle ??
        (blockedMode
            ? 'Regularize seu acesso ao SIPGED'
            : 'Escolha o plano ideal para sua operação');

    final message = reasonMessage ??
        (blockedMode
            ? 'Para continuar usando o sistema, selecione um plano ou regularize sua contratação. Seus dados permanecem seguros e preservados.'
            : 'Contrate uma plataforma moderna para gestão de demandas, contratos públicos, obras rodoviárias, documentos, mapas e indicadores executivos.');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(
          color: _PlanUi.border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 720;

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeaderLogoCompact(),
                    const SizedBox(height: 18),
                    _HeaderContent(
                      blockedMode: blockedMode,
                      title: title,
                      message: message,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const _HeaderLogoSide(),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _HeaderContent(
                      blockedMode: blockedMode,
                      title: title,
                      message: message,
                    ),
                  ),
                  if (dialogMode && onClose != null) const SizedBox(width: 52),
                ],
              );
            },
          ),
          if (dialogMode && onClose != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton.filledTonal(
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
                color: _PlanUi.textPrimary,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  hoverColor: const Color(0xFFE2E8F0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderLogoSide extends StatelessWidget {
  const _HeaderLogoSide();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 112,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFFF8FAFC),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Image.asset(
        'assets/logos/sipged/sipged.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _HeaderLogoCompact extends StatelessWidget {
  const _HeaderLogoCompact();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 74,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF8FAFC),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Image.asset(
        'assets/logos/sipged/sipged.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class _HeaderContent extends StatelessWidget {
  const _HeaderContent({
    required this.blockedMode,
    required this.title,
    required this.message,
  });

  final bool blockedMode;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Pill(
              icon: blockedMode
                  ? Icons.lock_clock_rounded
                  : Icons.verified_rounded,
              text: blockedMode ? 'Acesso pendente' : 'Planos SIPGED',
              color: blockedMode
                  ? const Color(0xFFF97316)
                  : const Color(0xFF16A34A),
            ),
            const _Pill(
              icon: Icons.shield_rounded,
              text: 'Firebase + Flutter',
              color: Color(0xFF0284C7),
            ),
            const _Pill(
              icon: Icons.map_rounded,
              text: 'Gestão georreferenciada',
              color: Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: _PlanUi.textPrimary,
            fontSize: 30,
            height: 1.08,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: const TextStyle(
            color: _PlanUi.textSecondary,
            fontSize: 15,
            height: 1.42,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BillingSwitch extends StatelessWidget {
  const _BillingSwitch({
    required this.interval,
    required this.onChanged,
  });

  final SystemPlanInterval interval;
  final ValueChanged<SystemPlanInterval> onChanged;

  @override
  Widget build(BuildContext context) {
    final yearly = interval == SystemPlanInterval.yearly;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _PlanUi.border,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SwitchItem(
              text: 'Mensal',
              selected: !yearly,
              onTap: () => onChanged(SystemPlanInterval.monthly),
            ),
            _SwitchItem(
              text: 'Anual',
              badge: 'melhor valor',
              selected: yearly,
              onTap: () => onChanged(SystemPlanInterval.yearly),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchItem extends StatelessWidget {
  const _SwitchItem({
    required this.text,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String text;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: selected ? _PlanUi.textPrimary : Colors.transparent,
            boxShadow: selected
                ? [
              BoxShadow(
                color: _PlanUi.textPrimary.withValues(alpha: 0.20),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.white : _PlanUi.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: selected
                        ? Colors.white.withValues(alpha: 0.16)
                        : const Color(0xFFDCFCE7),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color:
                      selected ? Colors.white : const Color(0xFF15803D),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlansGrid extends StatelessWidget {
  const _PlansGrid({
    required this.plans,
    required this.currentPlanId,
    required this.selectedPlanId,
    required this.interval,
    required this.isCompact,
    required this.priceBuilder,
    required this.intervalBuilder,
    required this.savingBuilder,
    required this.onSelected,
  });

  final List<SystemPlanData> plans;
  final String? currentPlanId;
  final String selectedPlanId;
  final SystemPlanInterval interval;
  final bool isCompact;
  final String Function(SystemPlanData plan) priceBuilder;
  final String Function(SystemPlanData plan) intervalBuilder;
  final String Function(SystemPlanData plan) savingBuilder;
  final ValueChanged<SystemPlanData> onSelected;

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Column(
        children: plans
            .map(
              (plan) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PlanCard(
              plan: plan,
              selected: selectedPlanId == plan.id,
              current: currentPlanId == plan.id,
              price: priceBuilder(plan),
              interval: intervalBuilder(plan),
              saving: savingBuilder(plan),
              onTap: () => onSelected(plan),
            ),
          ),
        )
            .toList(),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: plans
            .map(
              (plan) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _PlanCard(
                plan: plan,
                selected: selectedPlanId == plan.id,
                current: currentPlanId == plan.id,
                price: priceBuilder(plan),
                interval: intervalBuilder(plan),
                saving: savingBuilder(plan),
                onTap: () => onSelected(plan),
              ),
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.current,
    required this.price,
    required this.interval,
    required this.saving,
    required this.onTap,
  });

  final SystemPlanData plan;
  final bool selected;
  final bool current;
  final String price;
  final String interval;
  final String saving;
  final VoidCallback onTap;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final elevated = widget.selected || _hovered || plan.recommended;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          scale: _hovered ? 1.018 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: widget.selected
                  ? plan.color.withValues(alpha: 0.055)
                  : _PlanUi.card.withValues(alpha: 0.94),
              border: Border.all(
                width: widget.selected ? 1.7 : 1,
                color: widget.selected
                    ? plan.color.withValues(alpha: 0.92)
                    : _PlanUi.border,
              ),
              boxShadow: elevated
                  ? [
                BoxShadow(
                  color: plan.color.withValues(alpha: 0.16),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: const Color(0xFF0F172A)
                      .withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
                  : [
                BoxShadow(
                  color: const Color(0xFF0F172A)
                      .withValues(alpha: 0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [
                            plan.color,
                            plan.color.withValues(alpha: 0.70),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: plan.color.withValues(alpha: 0.24),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        plan.icon,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: widget.selected
                          ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('selected'),
                        color: plan.color,
                        size: 28,
                      )
                          : Icon(
                        Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('unselected'),
                        color:
                        _PlanUi.textMuted.withValues(alpha: 0.42),
                        size: 26,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SmallBadge(
                      text: plan.highlightLabel,
                      color: plan.color,
                    ),
                    if (widget.current)
                      const _SmallBadge(
                        text: 'Plano atual',
                        color: Color(0xFFEAB308),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  plan.name,
                  style: const TextStyle(
                    color: _PlanUi.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  plan.subtitle,
                  style: const TextStyle(
                    color: _PlanUi.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  plan.description,
                  style: const TextStyle(
                    color: _PlanUi.textMuted,
                    fontSize: 13.5,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        widget.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _PlanUi.textPrimary,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        widget.interval,
                        style: const TextStyle(
                          color: _PlanUi.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  widget.saving,
                  style: TextStyle(
                    color: plan.color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  height: 1,
                  color: _PlanUi.border,
                ),
                const SizedBox(height: 20),
                ...plan.features.map(
                      (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: plan.color,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(
                              color: _PlanUi.textSecondary,
                              fontSize: 13.2,
                              height: 1.28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: widget.selected
                        ? LinearGradient(
                      colors: [
                        plan.color,
                        plan.color.withValues(alpha: 0.76),
                      ],
                    )
                        : null,
                    color: widget.selected ? null : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: widget.selected
                          ? Colors.transparent
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.current
                          ? 'Plano selecionado'
                          : widget.selected
                          ? 'Selecionado'
                          : 'Escolher plano',
                      style: TextStyle(
                        color: widget.selected
                            ? Colors.white
                            : _PlanUi.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedPlanSummary extends StatelessWidget {
  const _SelectedPlanSummary({
    required this.plan,
    required this.currentPlanId,
    required this.price,
    required this.interval,
    required this.blockedMode,
    required this.onContinue,
  });

  final SystemPlanData plan;
  final String? currentPlanId;
  final String price;
  final String interval;
  final bool blockedMode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final isCurrent = currentPlanId == plan.id;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.92),
        border: Border.all(
          color: _PlanUi.border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.055),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          final info = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: plan.color.withValues(alpha: 0.11),
                  border: Border.all(
                    color: plan.color.withValues(alpha: 0.24),
                  ),
                ),
                child: Icon(
                  plan.icon,
                  color: plan.color,
                  size: 25,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrent
                          ? 'Você está visualizando o plano ${plan.name}'
                          : 'Plano selecionado: ${plan.name}',
                      style: const TextStyle(
                        color: _PlanUi.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.enterprise
                          ? 'Nossa equipe prepara uma proposta personalizada para sua operação.'
                          : '$price $interval • contratação segura e ativação conforme configuração da conta.',
                      style: const TextStyle(
                        color: _PlanUi.textMuted,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final button = SizedBox(
            width: compact ? double.infinity : 260,
            height: 52,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: plan.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                shadowColor: plan.color.withValues(alpha: 0.38),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plan.enterprise
                        ? 'Solicitar proposta'
                        : isCurrent
                        ? 'Manter plano'
                        : blockedMode
                        ? 'Regularizar acesso'
                        : 'Continuar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          );

          if (compact) {
            return Column(
              children: [
                info,
                const SizedBox(height: 16),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 18),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _TrustSection extends StatelessWidget {
  const _TrustSection();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _TrustItem(
        icon: Icons.security_rounded,
        title: 'Dados protegidos',
        text: 'Base preparada para autenticação, permissões e regras por perfil.',
      ),
      _TrustItem(
        icon: Icons.insights_rounded,
        title: 'Gestão executiva',
        text: 'Indicadores, mapas, contratos, medições e histórico operacional.',
      ),
      _TrustItem(
        icon: Icons.auto_graph_rounded,
        title: 'Pronto para escalar',
        text: 'Estrutura modular para novos órgãos, unidades, obras e integrações.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 820;

        if (compact) {
          return Column(
            children: items
                .map(
                  (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: item,
              ),
            )
                .toList(),
          );
        }

        return Row(
          children: items
              .map(
                (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: item,
              ),
            ),
          )
              .toList(),
        );
      },
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.88),
        border: Border.all(
          color: _PlanUi.border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _PlanUi.textSecondary,
            size: 24,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _PlanUi.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(
                    color: _PlanUi.textMuted,
                    fontSize: 12.2,
                    height: 1.26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.10),
        border: Border.all(
          color: color.withValues(alpha: 0.26),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}