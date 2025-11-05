// lib/screens/crm/precatorios/widgets/crm_step_page.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/input/custom_date_field.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';
import 'package:siged/_widgets/input/drop_down_botton_change.dart';

abstract class CrmStepController extends ChangeNotifier {
  /// Mapa de campos: chave -> TextEditingController
  Map<String, TextEditingController> get fields;

  /// Campos de data/chaveados à parte
  DateTime? get nextActionDate;
  set nextActionDate(DateTime? v);

  /// Status da etapa (ex.: NOVO, EM ANDAMENTO, AGUARDANDO CLIENTE, CONCLUÍDO, PERDIDO)
  String get status;
  set status(String v);

  /// Inicializa com dados mock para testes
  void initWithMock();

  /// Serialização para salvar em Firestore
  Map<String, dynamic> toMap();

  /// Simula salvamento (você troca aqui para chamar seu Bloc/Repository)
  Future<void> save() async {}

  @mustCallSuper
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }
}

class CrmStepPage extends StatelessWidget {
  final CrmStepController controller;
  final bool readOnly;

  const CrmStepPage({
    super.key,
    required this.controller,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    final entries = controller.fields.entries.toList();

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final e in entries)
                    SizedBox(
                      width: 540,
                      child: CustomTextField(
                        controller: e.value,
                        readOnly: readOnly,
                      ),
                    ),
                  SizedBox(
                    width: 260,
                    child: _StatusDropdown(
                      value: controller.status,
                      enabled: !readOnly,
                      onChanged: (v) {
                        if (v != null) {
                          controller.status = v;
                          controller.notifyListeners();
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: _DateField(
                      label: 'Próxima ação',
                      value: controller.nextActionDate,
                      enabled: !readOnly,
                      onChanged: (v) {
                        controller.nextActionDate = v;
                        controller.notifyListeners();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar'),
                    onPressed: readOnly ? null : () async {
                      await controller.save();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Etapa salva com sucesso!')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Carregar mock'),
                    onPressed: readOnly ? null : () {
                      controller.initWithMock();
                      controller.notifyListeners();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForKey(String key) {
    final k = key.replaceAll('_', ' ');
    return k.substring(0,1).toUpperCase() + k.substring(1);
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  const _StatusDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  static const _items = <String>[
    'NOVO',
    'EM ANDAMENTO',
    'AGUARDANDO CLIENTE',
    'AGUARDANDO INTERNO',
    'PROPOSTA ENVIADA',
    'FECHADO (GANHO)',
    'FECHADO (PERDIDO)',
  ];

  @override
  Widget build(BuildContext context) {
    return DropDownButtonChange(
      controller: TextEditingController(text: value),
      onChanged: enabled ? onChanged : null,
      items: _items,
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final bool enabled;
  final ValueChanged<DateTime?> onChanged;
  const _DateField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value == null ? '' : _fmt(value!),
    );
    return CustomDateField(
      controller: controller,
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
