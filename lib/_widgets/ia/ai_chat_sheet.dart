import 'package:flutter/material.dart';
import 'package:siged/_services/ia/ai_service.dart';
import 'package:siged/_widgets/ia/chat_message.dart';
import 'package:siged/_widgets/sheets/draggable_sheet/draggable_sheet.dart';

class AiChatSheet extends StatefulWidget {
  const AiChatSheet({super.key});

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  late final AiService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AiService(
      endpoint: 'https://us-central1-sisgeoderal.cloudfunctions.net/iaChat',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isLoading = true;
    });

    try {
      final reply = await _aiService.ask(text);

      setState(() {
        _messages.add(
          ChatMessage(
            text: reply,
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
            'Ocorreu um erro ao falar com a IA. Tente novamente em instantes.\n\nDetalhes: $e',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return BaseDraggableSheet(
          title: 'SIPGED • Assistente IA',
          icon: Icons.auto_awesome,
          isLoading: _isLoading,
          scrollController: scrollController,

          // ===== MODO LISTA =====
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final msg = _messages[index];
            final isUser = msg.isUser;

            return Align(
              alignment:
              isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color:
                  isUser ? theme.colorScheme.primary : Colors.grey[850],
                  borderRadius: BorderRadius.circular(10).copyWith(
                    bottomLeft: isUser
                        ? const Radius.circular(10)
                        : Radius.zero,
                    bottomRight: isUser
                        ? Radius.zero
                        : const Radius.circular(10),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },

          onClose: () => Navigator.of(context).pop(),

          // Rodapé = input
          bottomArea: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: const InputDecoration(
                    hintText:
                    'Pergunte algo sobre processos, contratos...',
                    hintStyle: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _isLoading
                      ? Icons.stop_circle_outlined
                      : Icons.send_rounded,
                  size: 18,
                  color: Colors.lightBlueAccent,
                ),
                onPressed: _isLoading ? null : _sendMessage,
              ),
            ],
          ),
        );
      },
    );
  }
}
