import 'package:flutter/material.dart';
import 'package:siged/_widgets/ia/ai_chat_sheet.dart';
import 'package:siged/_widgets/ia/ai_futuristic_button.dart';
import 'package:siged/_services/map/map_box/service/nominatim_bloc.dart';

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

    // Aguarda o fechamento do bottom sheet
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
    const textStyle = TextStyle(color: Colors.grey, fontSize: 11);

    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔹 Só mostra o linear quando a IA estiver “ativa”
            SizedBox(
              height: 2,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showIaProgress
                    ? LinearProgressIndicator(
                  key: const ValueKey('ia-progress'),
                  color: Colors.blue.shade200,
                  backgroundColor: Colors.white,
                )
                    : const SizedBox(
                  key: ValueKey('no-progress'),
                ),
              ),
            ),

            // 🔹 Barra de rodapé com texto + botão futurista à direita
            Container(
              width: double.infinity,
              height: 30,
              color: Colors.white,
              child: Stack(
                children: [
                  // Texto centralizado
                  Center(
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

                  // Botão futurista colado à direita
                  Positioned(
                    right: 12,
                    top: 3,
                    bottom: 3,
                    child: AiFuturisticButton(
                      onTap: () => _openAiChat(context),
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
