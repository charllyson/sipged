import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTip extends StatefulWidget {
  const HomeTip({
    super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  State<HomeTip> createState() => _HomeTipState();
}

class _HomeTipState extends State<HomeTip> {
  static const String _prefKey = 'home_tip_modules_seen';

  bool _loading = true;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _loadTipVisibility();
  }

  Future<void> _loadTipVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySeen = prefs.getBool(_prefKey) ?? false;

    if (!mounted) return;

    setState(() {
      _visible = !alreadySeen;
      _loading = false;
    });
  }

  Future<void> _closeTip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);

    if (!mounted) return;

    setState(() {
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: child,
            ),
          );
        },
        child: !_visible
            ? const SizedBox(
          key: ValueKey('home-tip-hidden'),
          width: double.infinity,
          height: 0,
        )
            : _HomeTipCard(
          key: const ValueKey('home-tip-visible'),
          isDark: widget.isDark,
          onClose: _closeTip,
        ),
      ),
    );
  }
}

class _HomeTipCard extends StatelessWidget {
  const _HomeTipCard({
    super.key,
    required this.isDark,
    required this.onClose,
  });

  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.76)
        : const Color(0xFF475569);

    final backgroundGradient = isDark
        ? const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF111827),
        Color(0xFF172554),
      ],
    )
        : const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFFFFF),
        Color(0xFFF8FAFC),
        Color(0xFFEFF6FF),
      ],
    );

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.90);

    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.38)
        : const Color(0xFF1E3A8A).withValues(alpha: 0.10);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -42,
                top: -54,
                child: _DecorativeCircle(
                  size: 150,
                  opacity: 0.09,
                ),
              ),
              const Positioned(
                right: 66,
                bottom: -58,
                child: _DecorativeCircle(
                  size: 112,
                  opacity: 0.07,
                ),
              ),
              Positioned.fill(
                left: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.yellow,
                          Colors.orange.shade500,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 18 : 22,
                  compact ? 16 : 18,
                  compact ? 12 : 14,
                  compact ? 16 : 18,
                ),
                child: compact
                    ? _CompactContent(
                  titleColor: titleColor,
                  textColor: textColor,
                  isDark: isDark,
                  onClose: onClose,
                )
                    : _WideContent(
                  titleColor: titleColor,
                  textColor: textColor,
                  isDark: isDark,
                  onClose: onClose,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WideContent extends StatelessWidget {
  const _WideContent({
    required this.titleColor,
    required this.textColor,
    required this.isDark,
    required this.onClose,
  });

  final Color titleColor;
  final Color textColor;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TipIcon(isDark: isDark),
        const SizedBox(width: 16),
        Expanded(
          child: _TipText(
            titleColor: titleColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 12),
        _CloseIconButton(
          isDark: isDark,
          onClose: onClose,
        ),
      ],
    );
  }
}

class _CompactContent extends StatelessWidget {
  const _CompactContent({
    required this.titleColor,
    required this.textColor,
    required this.isDark,
    required this.onClose,
  });

  final Color titleColor;
  final Color textColor;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TipIcon(isDark: isDark),
        const SizedBox(width: 13),
        Expanded(
          child: _TipText(
            titleColor: titleColor,
            textColor: textColor,
          ),
        ),
        const SizedBox(width: 6),
        _CloseIconButton(
          isDark: isDark,
          onClose: onClose,
        ),
      ],
    );
  }
}

class _TipIcon extends StatelessWidget {
  const _TipIcon({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      width: 52,
      decoration: BoxDecoration(
        color: Colors.yellow.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.yellow
        ),
      ),
      child: Icon(
        Icons.tips_and_updates_rounded,
        color: Colors.yellow.shade800,
        size: 28,
      ),
    );
  }
}

class _TipText extends StatelessWidget {
  const _TipText({
    required this.titleColor,
    required this.textColor,
  });

  final Color titleColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dica rápida',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: titleColor,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Cada ícone representa um módulo independente do SIPGED e pode ser habilitado conforme o contrato ou perfil de acesso do órgão.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: textColor,
            height: 1.32,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CloseIconButton extends StatelessWidget {
  const _CloseIconButton({
    required this.isDark,
    required this.onClose,
  });

  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Fechar dica',
      child: IconButton(
        visualDensity: VisualDensity.compact,
        splashRadius: 18,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        onPressed: onClose,
        icon: Icon(
          Icons.close_rounded,
          size: 22,
          color: isDark
              ? Colors.white.withValues(alpha: 0.72)
              : Colors.blueGrey.shade500,
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({
    required this.size,
    required this.opacity,
  });

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue.withValues(alpha: opacity),
        ),
      ),
    );
  }
}