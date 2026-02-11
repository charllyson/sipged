import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_widgets/texts/section_text_name.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';

import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/list/files/side_list_box.dart';

import 'package:siged/_blocs/modules/actives/oacs/active_oacs_cubit.dart';
import 'package:siged/_blocs/modules/actives/oacs/active_oacs_state.dart';
import 'package:siged/_blocs/modules/actives/oacs/active_oacs_data.dart';
import 'package:siged/_blocs/modules/actives/oacs/active_oacs_repository.dart';

class OacInspectionsPage extends StatefulWidget {
  const OacInspectionsPage({super.key});

  @override
  State<OacInspectionsPage> createState() => _OacInspectionsPageState();
}

class _OacInspectionsPageState extends State<OacInspectionsPage> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ActiveOacsRepository(); // usado para upload

  // ===== Form inspeção (UI)
  final _inspectorCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  final _methodCtrl = TextEditingController(); // substitui "condition"
  final _anomaliesCtrl = TextEditingController(); // tags separadas por vírgula
  final _notesCtrl = TextEditingController(); // aqui vai defects/actions + observações
  final _costCtrl = TextEditingController(); // (não existe no Entry -> vai para notes)

  final _dateCtrl = TextEditingController();
  final _nextDateCtrl = TextEditingController();
  DateTime? _date;
  DateTime? _nextDate;

  // Edição
  String? _editingInspectionId;

  // Anexos em memória por inspeção (UI-only)
  // Observação: como OacInspectionEntry não tem attachments, isto não persiste no Firestore.
  final Map<String, List<Attachment>> _attachmentsByInspection = {};

  @override
  void dispose() {
    _inspectorCtrl.dispose();
    _scoreCtrl.dispose();
    _methodCtrl.dispose();
    _anomaliesCtrl.dispose();
    _notesCtrl.dispose();
    _costCtrl.dispose();
    _dateCtrl.dispose();
    _nextDateCtrl.dispose();
    super.dispose();
  }

  double? _parseDouble(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year.toString()}';
  }

  List<String>? _parseTags(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final parts = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts;
  }

  String _buildNotes({
    required String? notes,
    required String? costEstimate,
    required DateTime? nextDate,
  }) {
    final buf = StringBuffer();
    if (notes != null && notes.trim().isNotEmpty) {
      buf.writeln(notes.trim());
    }
    if (costEstimate != null && costEstimate.trim().isNotEmpty) {
      buf.writeln('Custo estimado: R\$ ${costEstimate.trim()}');
    }
    if (nextDate != null) {
      buf.writeln('Próxima inspeção: ${_fmtDate(nextDate)}');
    }
    return buf.toString().trim();
  }


  List<OacInspectionEntry> _readInspectionsFromForm(ActiveOacsData form) {
    final raw = form.inspections ?? const <OacInspectionEntry>[];
    return raw.map((e) => e.copy()).toList(growable: true);
  }

  void _writeInspectionsToCubit({
    required ActiveOacsCubit cubit,
    required ActiveOacsData base,
    required List<OacInspectionEntry> inspections,
  }) {
    cubit.patchForm(
      base.copyWith(
        inspections: inspections,
        // manter campos agregados do documento coerentes (opcional)
        lastInspectionDate: inspections.isEmpty ? base.lastInspectionDate : inspections.first.date,
        nextInspectionDate: base.nextInspectionDate, // você pode derivar se quiser
      ),
    );
  }

  void _clearInspectionForm() {
    setState(() {
      _editingInspectionId = null;
      _inspectorCtrl.clear();
      _scoreCtrl.clear();
      _methodCtrl.clear();
      _anomaliesCtrl.clear();
      _notesCtrl.clear();
      _costCtrl.clear();
      _dateCtrl.clear();
      _nextDateCtrl.clear();
      _date = null;
      _nextDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOacsCubit, ActiveOacsState>(
      builder: (context, st) {
        final cubit = context.read<ActiveOacsCubit>();
        final oac = st.form;

        if (oac.id == null || oac.id!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Salve a OAC primeiro para liberar Inspeções.'),
          );
        }

        // Lista tipada correta
        final inspections = _readInspectionsFromForm(oac);

        // Ordena (mais recente primeiro)
        inspections.sort((a, b) => b.date.compareTo(a.date));

        void onEdit(OacInspectionEntry ins) {
          setState(() {
            _editingInspectionId = ins.id;
            _date = ins.date;
            _dateCtrl.text = _fmtDate(ins.date);

            // método/inspector/score/notes
            _inspectorCtrl.text = ins.inspectorUserId ?? '';
            _scoreCtrl.text = ins.score?.toString() ?? '';
            _methodCtrl.text = ins.method ?? '';
            _anomaliesCtrl.text = (ins.anomalies ?? const <String>[]).join(', ');
            _notesCtrl.text = ins.notes ?? '';

            // nextDate/cost ficam no notes (fallback)
            // Se você quiser, pode implementar parser no notes.
            _nextDate = null;
            _nextDateCtrl.text = '-';
            _costCtrl.clear();
          });
        }

        Future<void> onDelete(String id) async {
          final updated = inspections.where((e) => e.id != id).toList();
          _writeInspectionsToCubit(cubit: cubit, base: oac, inspections: updated);
          await cubit.upsert(cubit.state.form);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inspeção removida.')),
            );
          }
        }

        Future<void> onSaveInspection() async {
          if (!(_formKey.currentState?.validate() ?? false)) return;

          final nowId = _editingInspectionId ?? 'insp_${DateTime.now().millisecondsSinceEpoch}';
          final date = _date ?? DateTime.now();

          final entry = OacInspectionEntry(
            id: nowId,
            date: date,
            inspectorUserId: _inspectorCtrl.text.trim().isEmpty ? null : _inspectorCtrl.text.trim(),
            score: _parseDouble(_scoreCtrl.text),
            method: _methodCtrl.text.trim().isEmpty ? null : _methodCtrl.text.trim(),
            anomalies: _parseTags(_anomaliesCtrl.text),
            notes: _buildNotes(
              notes: _notesCtrl.text,
              costEstimate: _costCtrl.text,
              nextDate: _nextDate,
            ),
          );

          final idx = inspections.indexWhere((e) => e.id == nowId);
          if (idx == -1) {
            inspections.insert(0, entry);
          } else {
            inspections[idx] = entry;
          }

          _writeInspectionsToCubit(cubit: cubit, base: oac, inspections: inspections);
          await cubit.upsert(cubit.state.form);

          _clearInspectionForm();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(idx == -1 ? 'Inspeção adicionada.' : 'Inspeção atualizada.')),
            );
          }
        }

        Future<void> onUploadInspectionAttachment(String inspectionId) async {
          final att = await _repo.pickAndUploadSingle(
            baseDir: 'actives_oacs/${oac.id}/inspections/$inspectionId',
            allowedExtensions: null,
            forcedLabel: null,
          );
          if (att == null) return;

          final list = _attachmentsByInspection[inspectionId] ?? <Attachment>[];
          _attachmentsByInspection[inspectionId] = [att, ...list];

          if (mounted) setState(() {});
        }


        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(text: 'Nova inspeção'),
              const SizedBox(height: 8),

              Form(
                key: _formKey,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    double w(int perLine) => width >= 900
                        ? (width - (perLine - 1) * 12) / perLine
                        : width >= 600
                        ? (width - 12) / 2
                        : width;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: w(4),
                          child: CustomDateField(
                            controller: _dateCtrl,
                            labelText: 'Data da inspeção',
                            initialValue: _date,
                            onChanged: (d) => _date = d,
                          ),
                        ),
                        CustomTextField(
                          controller: _inspectorCtrl,
                          labelText: 'Inspetor (UID/nome)',
                          width: w(4),
                        ),
                        CustomTextField(
                          controller: _scoreCtrl,
                          labelText: 'Nota (0..5)',
                          width: w(4),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        CustomTextField(
                          controller: _methodCtrl,
                          labelText: 'Método (visual/drone/etc.)',
                          width: w(4),
                        ),
                        CustomTextField(
                          controller: _anomaliesCtrl,
                          labelText: 'Anomalias (tags separadas por vírgula)',
                          width: w(1),
                        ),
                        CustomTextField(
                          controller: _notesCtrl,
                          labelText: 'Observações (defeitos/ações)',
                          width: w(1),
                          maxLines: 3,
                        ),
                        CustomTextField(
                          controller: _costCtrl,
                          labelText: 'Custo estimado (R\$) (opcional)',
                          width: w(4),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                        SizedBox(
                          width: w(4),
                          child: CustomDateField(
                            controller: _nextDateCtrl,
                            labelText: 'Próxima inspeção (opcional)',
                            initialValue: _nextDate,
                            onChanged: (d) => _nextDate = d,
                          ),
                        ),
                        SizedBox(
                          width: w(4),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: st.saving ? null : onSaveInspection,
                                  icon: st.saving
                                      ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(_editingInspectionId == null ? 'Salvar inspeção' : 'Atualizar inspeção'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _clearInspectionForm,
                                child: const Text('Limpar'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              const SectionTitle(text: 'Inspeções cadastradas'),
              const SizedBox(height: 8),

              if (inspections.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Nenhuma inspeção cadastrada.'),
                ),

              if (inspections.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    itemCount: inspections.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (_, i) {
                      final ins = inspections[i];

                      final title =
                          '${_fmtDate(ins.date)} • ${ins.method ?? 'Sem método'}';
                      final subtitle =
                          'Inspetor: ${ins.inspectorUserId ?? '-'} • Nota: ${ins.score?.toStringAsFixed(1) ?? '-'}';

                      final attachments = _attachmentsByInspection[ins.id] ?? const <Attachment>[];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => onEdit(ins),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Excluir',
                                    onPressed: () => onDelete(ins.id),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                              Text(subtitle),
                              const SizedBox(height: 8),

                              if ((ins.anomalies ?? const <String>[]).isNotEmpty)
                                Text('Anomalias: ${(ins.anomalies ?? const <String>[]).join(', ')}'),

                              if ((ins.notes ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(ins.notes!.trim()),
                              ],

                              const SizedBox(height: 10),

                              SideListBox(
                                title: 'Anexos da inspeção',
                                items: attachments,
                                onAddPressed: () => onUploadInspectionAttachment(ins.id),
                                //onDelete: (a) => onRemoveInspectionAttachment(ins.id, a),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
