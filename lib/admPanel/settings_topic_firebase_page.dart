import 'package:flutter/material.dart';

// Importando suas páginas/tiles já existentes
import 'package:siged/_utils/firebase_utils.dart';
import 'package:siged/_widgets/background/background_cleaner.dart'; // se não usar, pode remover
import 'package:siged/admPanel/cleanup_subcollections/cleanup_subcollections_tile.dart';
import 'package:siged/admPanel/cleanup_subcollections/selective_delete_tile.dart';
import 'package:siged/admPanel/migrateCollections/migration.dart';
import 'package:siged/admPanel/migrateDocForSubCollection/migrateDocForSubCollection.dart';
import 'package:siged/admPanel/firestore/firestore_explorer_page.dart';
import 'package:siged/admPanel/converters/importExcel/excel_import_controller.dart';

import '../_widgets/buttons/back_circle_button.dart';
import '../_widgets/upBar/up_bar.dart';

class SettingsTopicFirebasePage extends StatelessWidget {
  const SettingsTopicFirebasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final topPadding = topSafe + 72 + 12; // conteúdo visível desde o início

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, // conteúdo rola por baixo da app bar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        flexibleSpace: SafeArea(
          bottom: false,
          child: UpBar(
            leading: const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: BackCircleButton(),
            ),
          ),
        ),
        toolbarHeight: 72,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Centraliza e limita a largura em telas grandes
          double maxW = constraints.maxWidth;
          if (constraints.maxWidth >= 1600) maxW = 1100;
          if (constraints.maxWidth >= 1200 && constraints.maxWidth < 1600) maxW = 1000;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                children: [
                  const _SectionHeader('Exploração & Ferramentas'),
                  _tile(
                    context,
                    title: 'Verificar coleções e documentos (Cloud Firestore)',
                    subtitle: 'Coleções e subcoleções',
                    icon: Icons.storage_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FirestoreExplorerPage()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const _SectionHeader('Importação / Atualização em massa'),
                  _tile(
                    context,
                    title: 'Excel → Firebase (coleção ou subcoleção)',
                    subtitle: 'Importar/atualizar registros via Excel',
                    icon: Icons.upload_file_outlined,
                    onTap: () async {
                      final path = await _askPath(context,
                          hint: 'Ex: actives_oaes ou documents/abc123/accidents');
                      if (!context.mounted || path == null || path.isEmpty) return;

                      _showLoading(context);
                      try {
                        await ImportExcelController.importar(
                          context: context,
                          path: path,
                          onFinished: () {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Importação finalizada!')),
                              );
                            }
                          },
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro na importação: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  const _SectionHeader('Migrações'),
                  _tile(
                    context,
                    title: 'Migrar documentos para subcoleção (custom)',
                    subtitle: 'Executa rotina migrarAcidentesPorAno()',
                    icon: Icons.merge_type_outlined,
                    onTap: () async {
                      _showLoading(context);
                      try {
                        await migrarAcidentesPorAno();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Migração concluída com sucesso!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro na migração: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 6),
                  _tile(
                    context,
                    title: 'Migrar coleções (widget)',
                    subtitle: 'Ferramenta visual para migrações',
                    icon: Icons.transfer_within_a_station_outlined,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MigrationCollections()),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const _SectionHeader('Limpeza & Manutenção'),
                  _tile(
                    context,
                    title: 'Apagar coleção inteira',
                    subtitle: 'Use com cuidado! Operação irreversível',
                    icon: Icons.delete_forever_rounded,
                    onTap: () async {
                      final path = await _askPath(context,
                          hint: 'Ex: actives_oaes ou documents/abc123/accidents');
                      if (!context.mounted || path == null || path.isEmpty) return;

                      _showLoading(context);
                      try {
                        await FirebaseUtils.deleteCollectionCompletamente(
                          context: context,
                          path: path,
                          onFinished: () {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Coleção deletada!')),
                              );
                            }
                          },
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro ao deletar: $e')),
                          );
                        }
                      } finally {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const CleanUpSubcollectionsTile(),
                  const SizedBox(height: 8),
                  SelectiveDeleteSubcollectionTile(),
                  const SizedBox(height: 24),

                  const _TipBox(
                    text:
                    'Dica: para rotinas destrutivas, exiba confirmação dupla (ex.: digitar o nome da coleção) e considere habilitar “modo somente leitura” em produção.',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- helpers UI ----------------

Widget _tile(
    BuildContext context, {
      required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap,
      Color? tileColor,
    }) {
  final bg = tileColor ?? Colors.white10;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        hoverColor: Colors.white.withOpacity(0.04), // efeito hover (web/desktop)
        splashColor: Colors.white.withOpacity(0.08),
        child: Container(
          color: Colors.black12,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Icon(icon),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.arrow_forward_ios),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ),
  );
}

Future<String?> _askPath(BuildContext context, {String? hint}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Informe o caminho da coleção'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint ?? 'Ex: actives_oaes ou documents/abc123/accidents',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final path = controller.text.trim();
            if (path.isNotEmpty) Navigator.pop(context, path);
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

void _showLoading(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }
}

class _TipBox extends StatelessWidget {
  const _TipBox({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
