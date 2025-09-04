import 'package:flutter/material.dart';
import 'package:siged/_widgets/schedule/schedule_status.dart';
import 'package:siged/screens/sectors/operation/schedule/schedule_modal_status.dart';

/// ======= Modal simples p/ APLICAÇÃO EM LOTE (status + comentário + data) =======
class ScheduleModalWidget {
  final ScheduleStatus status;
  final String? comment;
  final DateTime? takenAt;     // ⬅️ novo
  const ScheduleModalWidget(this.status, this.comment, this.takenAt);
}

class BulkStatusCommentSheet extends StatefulWidget {
  final int count;
  const BulkStatusCommentSheet({super.key, required this.count});

  @override
  State<BulkStatusCommentSheet> createState() => _BulkStatusCommentSheetState();
}

class _BulkStatusCommentSheetState extends State<BulkStatusCommentSheet> {
  ScheduleStatus _status = ScheduleStatus.aIniciar;
  final _commentCtrl = TextEditingController();
  DateTime? _selectedDate;                      // ⬅️ novo
  bool _busy = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  String _dateLabel(DateTime? d) {
    if (d == null) return '—';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final isSingle = widget.count == 1;
    final buttonLabel = isSingle ? 'Aplicar' : 'Aplicar em ${widget.count} célula(s)';
    final buttonIcon = isSingle ? Icons.done : Icons.done_all;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(isSingle ? Icons.edit : Icons.select_all_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSingle ? 'Editar célula' : 'Aplicar em lote',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context, null),
                    icon: const Icon(Icons.close),
                    tooltip: 'Fechar',
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Status chips
              ScheduleModalStatus(
                selected: _status,
                onSelect: _busy ? null : (s) => setState(() => _status = s),
              ),

              const SizedBox(height: 12),

              // Data (opcional) — aplicada a TODAS as células selecionadas
              Row(
                children: [
                  const Text('Data do serviço:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_dateLabel(_selectedDate)),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () async {
                      final init = _selectedDate ?? DateTime.now();
                      final d = await showDatePicker(
                        locale: const Locale('pt', 'BR'),
                        context: context,
                        initialDate: init,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                    child: Text(_selectedDate == null ? 'Definir' : 'Alterar'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Comentário
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentário (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              // Ações
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context, null),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () {
                        Navigator.pop<ScheduleModalWidget>(
                          context,
                          ScheduleModalWidget(
                            _status,
                            _commentCtrl.text.trim().isEmpty
                                ? null
                                : _commentCtrl.text.trim(),
                            _selectedDate, // ⬅️ novo
                          ),
                        );
                      },
                      icon: Icon(buttonIcon),
                      label: Text(buttonLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}