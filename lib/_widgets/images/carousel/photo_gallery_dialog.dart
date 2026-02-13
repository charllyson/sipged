import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/images/carousel/photo_item.dart';
import 'package:sipged/_widgets/images/carousel/carousel_metadata.dart' as pm;

// Adapter condicional
import 'package:sipged/_utils/images/image_adapter_loader.dart';

enum _FitMode { cover, contain }

Future<void> showPhotoGalleryDialog(
    BuildContext context, {
      required List<PhotoItem> items,
      int initialIndex = 0,
    }) async {
  if (!context.mounted || items.isEmpty) return;

  final controller = PageController(initialPage: initialIndex);
  var idx = initialIndex;
  var fitMode = _FitMode.cover; // padrão: preencher (sem bordas pretas)



  Future<Widget> buildImage(PhotoItem item) async {
    Image img;
    if (item is PhotoBytesItem) {
      img = Image.memory(
        item.bytes,
        fit: fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain,
      );
    } else if (item is PhotoUrlItem) {
      if (kIsWeb) {
        try {
          final raw = await loadImageBytes(item.url);
          final isHeic = pm.sniffFormat(raw) == pm.ImgFmt.heic || sniffIsHeic(raw);
          final converted = isHeic ? await tryConvertHeicToJpeg(raw) : null;
          final bytes = converted ?? raw;
          img = Image.memory(
            bytes,
            fit: fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain,
          );
        } catch (_) {
          return const Center(
            child: Text('Falha ao carregar imagem', style: TextStyle(color: Colors.redAccent)),
          );
        }
      } else {
        img = Image.network(
          item.url,
          fit: fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (_, _, _) => const Center(
            child: Text('Erro ao carregar', style: TextStyle(color: Colors.redAccent)),
          ),
        );
      }
    } else {
      return const Center(
        child: Text('Tipo de foto desconhecido', style: TextStyle(color: Colors.redAccent)),
      );
    }

    // Para “cover”, ocupar totalmente:
    return Positioned.fill(child: img);
  }

  await showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final item = items[idx];

          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, c) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 800),
                  child: Stack(
                    children: [
                      // Área da imagem (PageView)
                      Positioned.fill(
                        child: PageView.builder(
                          controller: controller,
                          onPageChanged: (i) => setState(() => idx = i),
                          itemCount: items.length,
                          itemBuilder: (_, pageIndex) {
                            return FutureBuilder<Widget>(
                              future: buildImage(items[pageIndex]),
                              builder: (c, snap) {
                                if (snap.connectionState != ConnectionState.done) {
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                }
                                return Stack(children: [
                                  if (snap.data != null) snap.data!,
                                ]);
                              },
                            );
                          },
                        ),
                      ),

                      // Fechar
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          color: Colors.white,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          tooltip: 'Fechar',
                        ),
                      ),

                      // Metadados (você já tem esse overlay em outro arquivo)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _DefaultMetaOverlay(meta: item.meta),
                      ),

                      // Setas navegação
                      if (items.length > 1) ...[
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              onPressed: idx > 0
                                  ? () => controller.previousPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              )
                                  : null,
                              icon: const Icon(Icons.chevron_left, size: 42),
                              color: Colors.white.withValues(alpha: idx > 0 ? 0.9 : 0.3),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: IconButton(
                              onPressed: idx < items.length - 1
                                  ? () => controller.nextPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                              )
                                  : null,
                              icon: const Icon(Icons.chevron_right, size: 42),
                              color: Colors.white.withValues(alpha: idx < items.length - 1 ? 0.9 : 0.3),
                            ),
                          ),
                        ),
                      ],

                      // Botão de ajuste (Cover/Contain)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          onPressed: () => setState(() {
                            fitMode = fitMode == _FitMode.cover ? _FitMode.contain : _FitMode.cover;
                          }),
                          icon: Icon(fitMode == _FitMode.cover ? Icons.crop : Icons.fit_screen),
                          label: Text(fitMode == _FitMode.cover ? 'Preencher' : 'Ajustar'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}

/// Overlay de metadados simples para manter o exemplo autocontido
class _DefaultMetaOverlay extends StatelessWidget {
  final pm.CarouselMetadata? meta;
  const _DefaultMetaOverlay({required this.meta});

  @override
  Widget build(BuildContext context) {
    // Se você já tem PhotoMetadataOverlay, troque por ele aqui.
    final m = meta;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xCC000000), Color(0x66000000), Colors.transparent],
          stops: [0, 0.5, 1],
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: Text(
          m == null ? '—' : [
            if ((m.make ?? '').trim().isNotEmpty) m.make!,
            if ((m.model ?? '').trim().isNotEmpty) m.model!,
          ].join(' '),
        ),
      ),
    );
  }
}
