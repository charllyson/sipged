import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_util' as jsu;

import 'package:sisged/_widgets/carousel/photo_item.dart';
import 'package:sisged/_utils/images/web_fetch_bytes.dart' show fetchBytesWeb;
import 'package:sisged/_utils/images/heic_web_convert.dart' show convertHeicBytesToJpegWeb;
import 'package:sisged/_blocs/widgets/carousel/carousel_metadata.dart' as pm;

import 'photo_metadata_overlay.dart';

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

  Uint8List _blank1x1Png() => Uint8List.fromList(
      [137,80,78,71,13,10,26,10,0,0,0,13,73,72,68,82,0,0,0,1,0,0,0,1,8,6,0,0,0,31,21,196,137,0,0,0,10,73,68,65,84,120,156,99,0,1,0,0,5,0,1,13,10,45,66,0,0,0,0,73,69,78,68,174,66,96,130]);

  bool _isJpeg(Uint8List b) => b.length >= 2 && b[0] == 0xFF && b[1] == 0xD8;

  Future<Widget> _buildImage(PhotoItem item) async {
    Image img;
    if (item is PhotoBytesItem) {
      img = Image.memory(item.bytes, fit: fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain);
    } else if (item is PhotoUrlItem) {
      // WEB: sempre via bytes (converte HEIC se necessário)
      if (kIsWeb) {
        try {
          final raw = await fetchBytesWeb(item.url);
          final fmt = pm.sniffFormat(raw);
          if (fmt == pm.ImgFmt.heic) {
            if (!jsu.hasProperty(html.window, 'heic2any')) {
              return Center(child: Text('HEIC sem conversor', style: const TextStyle(color: Colors.redAccent)));
            }
            final jpg = await convertHeicBytesToJpegWeb(raw);
            if (_isJpeg(jpg)) {
              img = Image.memory(jpg, fit: fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain);
            } else {
              img = Image.memory(_blank1x1Png(), fit: BoxFit.contain);
            }
          } else {
            img = Image.memory(raw, fit: fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain);
          }
        } catch (_) {
          return const Center(child: Text('Falha ao carregar imagem', style: TextStyle(color: Colors.redAccent)));
        }
      } else {
        img = Image.network(
          item.url,
          fit: fitMode == _FitMode.cover ? BoxFit.cover : BoxFit.contain,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('Erro ao carregar', style: TextStyle(color: Colors.redAccent)),
          ),
        );
      }
    } else {
      return const Center(child: Text('Tipo de foto desconhecido', style: TextStyle(color: Colors.redAccent)));
    }

    // Para “cover” não deixar sobras, certifica que ocupa totalmente:
    return Positioned.fill(child: img);
  }

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.8),
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
                              future: _buildImage(items[pageIndex]),
                              builder: (c, snap) {
                                if (snap.connectionState != ConnectionState.done) {
                                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                }
                                return Stack(children: [
                                  // Imagem ocupa todo o espaço (sem “barras”).
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

                      // Metadados (do item atual)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: PhotoMetadataOverlay(meta: item.meta),
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
                                  ? () => controller.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
                                  : null,
                              icon: const Icon(Icons.chevron_left, size: 42),
                              color: Colors.white.withOpacity(idx > 0 ? 0.9 : 0.3),
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
                                  ? () => controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
                                  : null,
                              icon: const Icon(Icons.chevron_right, size: 42),
                              color: Colors.white.withOpacity(idx < items.length - 1 ? 0.9 : 0.3),
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
