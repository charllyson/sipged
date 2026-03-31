import 'package:flutter/material.dart';
import 'package:sipged/_services/map/map_box/service/nominatim_bloc.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/ia/ai_chat_sheet.dart';
import 'package:sipged/_widgets/ia/ai_futuristic_button.dart';

class FootBar extends StatefulWidget {
  const FootBar({super.key});

  @override
  State<FootBar> createState() => _FootBarState();
}

class _FootBarState extends State<FootBar> {
  bool _showIaProgress = false;

  Future<void> _openAiChat(BuildContext context) async {
    setState(() {
      _showIaProgress = true;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiChatSheet(),
    );

    if (!mounted) return;

    setState(() {
      _showIaProgress = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final systemBloc = NominatimBloc();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
    );

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 2,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _showIaProgress
                    ? LinearProgressIndicator(
                  key: const ValueKey('ia-progress'),
                  minHeight: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade200,
                  ),
                  backgroundColor: Colors.transparent,
                )
                    : const SizedBox(
                  key: ValueKey('no-progress'),
                ),
              ),
            ),
            BasicCard(
              isDark: isDark,
              height: 38,
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              borderRadius: 0,
              useGlassEffect: true,
              blurSigmaX: 18,
              blurSigmaY: 18,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.12),
              borderColor: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.35),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.03),
                ]
                    : [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 72),
                      child: FutureBuilder<int>(
                        future: systemBloc.getBuildNumber(),
                        builder: (context, snapshot) {
                          final buildText = snapshot.hasData
                              ? ' • Build nº ${snapshot.data}'
                              : '';

                          return Text(
                            'Desenvolvido por C.A.S Engenharia & Tecnologia • Versão 1.0.0$buildText',
                            style: textStyle,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: AiFuturisticButton(
                        onTap: () => _openAiChat(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}