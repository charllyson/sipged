// lib/_widgets/map/markers/tooltip_animated_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TooltipAnimatedCard extends StatefulWidget {
  const TooltipAnimatedCard({
    super.key,
    required this.title,
    this.subtitle,
    this.maxWidth = 260,
    this.onDetails,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final double maxWidth;
  final VoidCallback? onDetails;
  final VoidCallback? onClose;

  @override
  State<TooltipAnimatedCard> createState() => _TooltipAnimatedCardState();
}

class _TooltipAnimatedCardState extends State<TooltipAnimatedCard> with SingleTickerProviderStateMixin {

  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
    reverseDuration: const Duration(milliseconds: 120),
  )..forward();

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const r = 12.0; // raio do card

    return FadeTransition(
      opacity: CurvedAnimation(parent: _ac, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _ac,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: 180, maxWidth: widget.maxWidth),
          child: Material(
            color: Colors.black87,
            elevation: 10,
            shadowColor: Colors.black38,
            borderRadius: BorderRadius.circular(r),
            clipBehavior: Clip.antiAlias, // garante clip do ripple no card
            child: Stack(
              children: [
                // conteúdo
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: .2,
                        ),
                      ),
                      if ((widget.subtitle ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            height: 1.2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

                      // Linha de ações (alinha botão à direita)
                      Row(
                        children: [
                          const Spacer(),
                          // ---- Botão "Detalhes" com hover/splash visíveis ----
                          Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: widget.onDetails,
                              radius: 18,
                              borderRadius: BorderRadius.circular(12),
                              mouseCursor: SystemMouseCursors.click,
                              splashColor: Colors.white.withOpacity(0.28),
                              hoverColor: Colors.white.withOpacity(0.12),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Text('Detalhes', style: TextStyle(color: Colors.white),),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ---- Botão X com hover/splash circular ----
                Positioned(
                  top: 2,
                  right: 2,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: widget.onClose,
                      radius: 18,
                      borderRadius: BorderRadius.circular(20),
                      mouseCursor: SystemMouseCursors.click,
                      // estes dois funcionam bem no web
                      splashColor: Colors.white.withOpacity(0.28),
                      hoverColor: Colors.white.withOpacity(0.12),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close, size: 18, color: Colors.white70),
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