// lib/admPanel/firebase/firebase_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/admPanel/bloc/firebase_admin_cubit.dart';
import 'package:sipged/admPanel/bloc/firebase_admin_data.dart';
import 'package:sipged/admPanel/bloc/firebase_admin_state.dart';

import 'package:sipged/_services/excel/excel_import_controller.dart';

import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/dialog/show_dialogs/show_window_dialog.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/tiles/tile_widget.dart';

import 'package:sipged/admPanel/firebase/firebase_section.dart';
import 'package:sipged/admPanel/firebase/firebase_toolkit.dart';

class FirebaseSettingsPage extends StatelessWidget {
  const FirebaseSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FirebaseAdminCubit(),
      child: const _SettingsFirebaseView(),
    );
  }
}

class _SettingsFirebaseView extends StatefulWidget {
  const _SettingsFirebaseView();

  @override
  State<_SettingsFirebaseView> createState() => _SettingsFirebaseViewState();
}

class _SettingsFirebaseViewState extends State<_SettingsFirebaseView> {
  void _showMessage(
      String message, {
        Color? backgroundColor,
        Duration duration = const Duration(seconds: 4),
      }) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) return;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
  }

  Future<void> _handleExcelImport() async {
    final path = await _askSimplePath(
      context,
      title: 'Importar Excel para Firestore',
      label: 'Caminho da coleção',
      hint:
      'Ex: tenants/{tenantId}/contracts ou tenants/{tenantId}/contracts/{contractId}/orders',
    );

    if (!mounted || path == null || path.isEmpty) return;

    await _runWithDialogLoading(
      action: () async {
        await ImportExcelController.importar(
          context: context,
          path: path,
          onFinished: () {
            _showMessage(
              'Importação finalizada!',
              backgroundColor: Colors.green.shade700,
            );
          },
        );
      },
      errorPrefix: 'Erro na importação',
    );
  }

  Future<void> _handlePreviewCollectionCount() async {
    final path = await _askSimplePath(
      context,
      title: 'Contar documentos',
      label: 'Caminho da coleção',
      hint:
      'Ex: tenants/{tenantId}/contracts ou tenants/{tenantId}/contracts/{contractId}/orders',
    );

    if (!mounted || path == null || path.isEmpty) return;

    try {
      final count = await context.read<FirebaseAdminCubit>().previewCollectionCount(
        path,
      );

      if (!mounted) return;

      _showMessage(
        'Coleção "$path": $count documento(s).',
        backgroundColor: Colors.green.shade700,
      );
    } catch (_) {
      // O Cubit já emite a mensagem de erro.
    }
  }

  Future<void> _runWithDialogLoading({
    required Future<void> Function() action,
    required String errorPrefix,
  }) async {
    final nav = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Material(
        color: Colors.black26,
        child: Center(
          child: LoadingTreeDots(size: 110),
        ),
      ),
    );

    try {
      await action();
    } catch (e) {
      _showMessage(
        '$errorPrefix: $e',
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (nav.canPop()) {
        nav.pop();
      }
    }
  }

  void _openMigrationToolkit() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FirebaseToolkit(
          title: 'Migração de vigências / ordens',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FirebaseAdminCubit, FirebaseAdminState>(
      listenWhen: (previous, current) {
        return previous.message != current.message && current.message != null;
      },
      listener: (context, state) {
        final isError = state.status == FirebaseAdminStatus.failure;

        _showMessage(
          state.message!,
          backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
          duration:
          isError ? const Duration(seconds: 6) : const Duration(seconds: 4),
        );
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final topSafe = MediaQuery.of(context).padding.top;
        const barHeight = 72.0;
        final topPadding = topSafe + barHeight + 12;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  bottom: false,
                  child: UpBar(
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 12.0),
                      child: CircleButtonChange(),
                    ),
                  ),
                ),
                toolbarHeight: barHeight,
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  double maxW = constraints.maxWidth;

                  if (constraints.maxWidth >= 1600) {
                    maxW = 1100;
                  }

                  if (constraints.maxWidth >= 1200 &&
                      constraints.maxWidth < 1600) {
                    maxW = 1000;
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
                        children: [
                          const FirebaseSection(
                            'Migração Multi-Tenant',
                            icon: Icons.account_tree_outlined,
                          ),
                          const SizedBox(height: 8),
                          TileWidget(
                            title: 'Migrar vigências / ordens',
                            subtitle:
                            'Copia collectionGroup(orders) para tenants/{tenantId}/contracts/{contractId}/orders/{orderId}',
                            leading: Icons.timeline_outlined,
                            onTap: _openMigrationToolkit,
                          ),
                          const SizedBox(height: 8),
                          BasicCard(
                            isDark: isDark,
                            padding: const EdgeInsets.all(12),
                            borderRadius: 12,
                            backgroundColor:
                            Colors.blue.withValues(alpha: 0.06),
                            borderColor: Colors.blue.withValues(alpha: 0.18),
                            enableShadow: false,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Migração ativa nesta etapa:\n'
                                        'collectionGroup("orders")\n'
                                        '→ tenants/${FirebaseAdminTenantPaths.fixedMigrationTenantId}/contracts/{contractId}/orders/{orderId}\n\n'
                                        'As rotinas de company, empenhos, aditivos e apostilamentos foram removidas desta tela porque já foram executadas.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const FirebaseSection(
                            'Importação / Atualização',
                            icon: Icons.upload_file_outlined,
                          ),
                          TileWidget(
                            title: 'Excel → Firebase',
                            subtitle:
                            'Importar ou atualizar registros via Excel em uma coleção informada',
                            leading: Icons.upload_file_outlined,
                            onTap: _handleExcelImport,
                          ),
                          const SizedBox(height: 18),
                          const FirebaseSection(
                            'Prévia / Consulta',
                            icon: Icons.search_outlined,
                          ),
                          TileWidget(
                            title: 'Contar documentos de uma coleção',
                            subtitle:
                            'Informe uma coleção e veja quantos documentos existem nela',
                            leading: Icons.numbers_outlined,
                            onTap: _handlePreviewCollectionCount,
                          ),
                          const SizedBox(height: 24),
                          BasicCard(
                            isDark: isDark,
                            padding: const EdgeInsets.all(12),
                            borderRadius: 12,
                            backgroundColor:
                            Colors.amber.withValues(alpha: 0.08),
                            borderColor: Colors.amber.withValues(alpha: 0.25),
                            enableShadow: false,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Esta área administrativa foi reduzida para evitar execução acidental '
                                        'de rotinas antigas ou destrutivas. Operações de exclusão em massa '
                                        'devem ser mantidas em uma tela separada e protegida.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (state.isLoading)
              const Material(
                color: Colors.black38,
                child: Center(
                  child: LoadingTreeDots(size: 110),
                ),
              ),
          ],
        );
      },
    );
  }
}

Future<String?> _askSimplePath(
    BuildContext context, {
      required String title,
      required String label,
      String? hint,
    }) async {
  final controller = TextEditingController();

  try {
    return await showWindowDialog<String>(
      context: context,
      title: title,
      width: 540,
      child: Builder(
        builder: (dialogCtx) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: controller,
                  labelText: hint ?? label,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(null),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();

                        if (value.isNotEmpty) {
                          Navigator.of(dialogCtx).pop(value);
                        }
                      },
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  } finally {
    controller.dispose();
  }
}