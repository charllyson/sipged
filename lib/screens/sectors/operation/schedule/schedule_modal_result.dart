import 'package:flutter/material.dart';

class ScheduleModalResultClass {
  final String status;
  final String? comment;
  const ScheduleModalResultClass(this.status, this.comment);
}

class ScheduleModalResult extends StatefulWidget {
  /// Quantidade de células alvo (1 = clique simples; >1 = lote)
  final int count;

  /// Rótulo do serviço atual (ex.: "ASFALTO")
  final String serviceLabel;

  /// Pré-preenchimento opcional (útil no clique simples)
  final String? initialStatus;   // 'concluido' | 'em andamento' | 'a iniciar'
  final String? initialComment;

  /// Personalização opcional
  final IconData? leadingIcon;   // se null, escolhe pencil (1) ou select_all (>1)

  const ScheduleModalResult({
    super.key,
    required this.count,
    required this.serviceLabel,
    this.initialStatus,
    this.initialComment,
    this.leadingIcon,
  });

  @override
  State<ScheduleModalResult> createState() => _ScheduleModalResultState();
}

class _ScheduleModalResultState extends State<ScheduleModalResult> {
  late String _status;
  final TextEditingController _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus?.trim().isNotEmpty == true
        ? widget.initialStatus!
        : 'concluido';
    if (widget.initialComment != null) {
      _commentCtrl.text = widget.initialComment!;
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Widget _statusChip(String value, String label, IconData icon, Color color) {
    final selected = _status == value;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _status = value),
      avatar: Icon(icon, size: 18, color: selected ? Colors.white : color),
      label: Text(label),
      selectedColor: color,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      backgroundColor: Colors.grey.shade200,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isSingle = widget.count == 1;

    final titleText = isSingle
        ? 'Editar célula — ${widget.serviceLabel}'
        : 'Aplicar em lote (${widget.count}) — ${widget.serviceLabel}';

    final titleIcon = widget.leadingIcon ??
        (isSingle ? Icons.edit : Icons.select_all_rounded);

    final buttonLabel =
    isSingle ? 'Aplicar' : 'Aplicar em ${widget.count} célula(s)';

    final buttonIcon = isSingle ? Icons.done : Icons.done_all;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // título
                Row(
                  children: [
                    Icon(titleIcon),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        titleText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, null),
                      icon: const Icon(Icons.close),
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // status
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('concluido', 'Concluído',
                        Icons.check_circle, Colors.green),
                    _statusChip('em andamento', 'Em andamento',
                        Icons.build, Colors.orange),
                    _statusChip('a iniciar', 'A iniciar',
                        Icons.refresh, Colors.blue),
                  ],
                ),
                const SizedBox(height: 12),

                // comentário
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comentário (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => Navigator.pop(
                    context,
                    ScheduleModalResultClass(_status, _commentCtrl.text),
                  ),
                ),
                const SizedBox(height: 12),

                // aplicar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(buttonIcon),
                    label: Text(buttonLabel),
                    onPressed: () => Navigator.pop(
                      context,
                      ScheduleModalResultClass(_status, _commentCtrl.text),
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
