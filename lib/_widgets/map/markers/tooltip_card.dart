import 'package:flutter/material.dart';

class TooltipCard extends StatelessWidget {
  const TooltipCard({
    super.key,
    required this.maxWidth,
    this.title,
    this.subTitle,
    this.onDetails,
    this.onClose,
  });

  final double maxWidth;
  final String? title;
  final String? subTitle;
  final VoidCallback? onDetails;
  final VoidCallback? onClose;


  @override
  Widget build(BuildContext context) {
    const double maxCardHeight = 110;

    return Theme(
      data: Theme.of(context).copyWith(
        shadowColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        useMaterial3: true,
      ),
      child: SizedBox( // ✅ fixa a largura
        width: maxWidth,
        child: Stack(
          clipBehavior: Clip.none, // ✅ evita recortes do X
          children: [
            // Corpo do cartão
            Container(
              width: maxWidth, // ✅ garante a largura do card
              padding: const EdgeInsets.fromLTRB(12, 10, 36, 10), // reserva pro X
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.90),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12, width: 0.5),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: maxCardHeight),
                child: DefaultTextStyle(
                  style: const TextStyle(color: Colors.white, fontSize: 10, height: 1.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null && title!.trim().isNotEmpty)
                        Text(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      if (subTitle != null && subTitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subTitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
                        ),
                      ],
                      if (onDetails != null) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 28,
                          child: TextButton.icon(
                            onPressed: onDetails,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.08),
                              shadowColor: Colors.transparent,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.info_outline_rounded, size: 14),
                            label: const Text('Ver detalhes', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Botão X
            // Botão X com splash/ripple
            Positioned(
              top: 2,
              right: 2,
              child: Theme(
                // reativa o ripple só aqui
                data: Theme.of(context).copyWith(
                  splashFactory: InkRipple.splashFactory,
                  splashColor: Colors.white24,
                  highlightColor: Colors.white10,
                  hoverColor: Colors.white12,
                ),
                child: Material(
                  color: Colors.transparent,          // sem fundo
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,       // clipa o splash no círculo
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    splashColor: Colors.white24,      // brilho do splash
                    highlightColor: Colors.white10,   // highlight ao pressionar
                    onTap: onClose,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
