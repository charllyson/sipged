import 'package:flutter/material.dart';
import 'package:siged/_utils/firebase_utils.dart';
import 'package:siged/admPanel/cleanup_subcollections/cleanup_subcollections_tile.dart';
import 'package:siged/admPanel/cleanup_subcollections/selective_delete_tile.dart';
import 'package:siged/admPanel/migrateCollections/migration.dart';
import 'package:siged/admPanel/users/manager_permissions_users_page.dart';
import 'cleanup_subcollections/nofilter_tile.dart';
import 'converters/generic_import_excel_page.dart';
import 'converters/importExcel/excel_import_controller.dart';
import 'migrateDocForSubCollection/migrateDocForSubCollection.dart';
import 'firestore/firestore_explorer_page.dart';

class SettingsSystemPage extends StatefulWidget {
  const SettingsSystemPage({super.key});

  @override
  State<SettingsSystemPage> createState() => _SettingsSystemPageState();
}

class _SettingsSystemPageState extends State<SettingsSystemPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Configurações'),
        ),
        body: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FirestoreExplorerPage(),
                    ),
                  );
                },
                title: Text(
                  'Verificar Coleções e documentos do CloudFirestore',
                ),
                subtitle: Text('Coleções e subcoleções'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManagerPermissionsUsersPage(),
                    ),
                  );
                },
                title: Text('Gerenciar permissões de usuário'),
                subtitle: Text('Permissões e configurações'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenericImportExcelPage(),
                    ),
                  );
                },
                title: Text('Excel para Json - Genérico'),
                subtitle: Text('Converter excel para json'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  final TextEditingController _pathController =
                      TextEditingController();

                  final path = await showDialog<String>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Informe o caminho da coleção'),
                          content: TextField(
                            controller: _pathController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Ex: actives_oaes ou documents/abc123/accidents',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final path = _pathController.text.trim();
                                if (path.isNotEmpty) {
                                  Navigator.pop(
                                    context,
                                    path,
                                  ); // 👈 retorna path como resultado
                                }
                              },
                              child: const Text('submeter'),
                            ),
                          ],
                        ),
                  );

                  // 👇 aqui o contexto ainda está montado
                  if (context.mounted && path != null && path.isNotEmpty) {
                    await ImportExcelController.importar(
                      context: context,
                      path: path,
                      onFinished: () {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Importação finalizada!'),
                            ),
                          );
                        }
                      },
                    );
                  }
                },
                title: Text('Excel para Firebase'),
                subtitle: Text('Converter excel para firebase'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever),
                tileColor: Colors.red,
                onTap: () async {
                  final TextEditingController _pathController =
                      TextEditingController();
                  final path = await showDialog<String>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Informe o caminho da coleção'),
                          content: TextField(
                            controller: _pathController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Ex: actives_oaes ou documents/abc123/accidents',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final path = _pathController.text.trim();
                                if (path.isNotEmpty) {
                                  Navigator.pop(
                                    context,
                                    path,
                                  ); // 👈 retorna path como resultado
                                }
                              },
                              child: const Text('Deletar'),
                            ),
                          ],
                        ),
                  );
                  // 👇 aqui o contexto ainda está montado
                  if (context.mounted && path != null && path.isNotEmpty) {
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
                  }
                },
                title: Text('Apagar coleção no Firebase'),
                subtitle: Text('Deletar coleção'),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              ListTile(
                leading: Icon(Icons.add),
                tileColor: Colors.white10,
                onTap: () async {
                  // Mostra um loading enquanto executa
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    await migrarAcidentesPorAno();
                    Navigator.pop(context); // fecha o loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Migração concluída com sucesso!'),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context); // fecha o loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro na migração: $e')),
                    );
                  }
                },
                title: Text('Migrar documentos para subcoleção'),
                subtitle: Text(''),
                trailing: Icon(Icons.arrow_forward_ios),
              ),
              /// MIGRANDO COLEÇÕES
              MigrationCollections(),
              /// DELETANDO COLEÇÕES
              const CleanUpSubcollectionsTile(),
              /// DELETANDO DOCUMENTOS
              SelectiveDeleteSubcollectionTile(),
              /// DELETANDO CAMPOS EM SUBCOLEÇÕES
              const DeleteFieldInSubcollectionTile(),
            ],
          ),
        ),
      ),
    );
  }
}
