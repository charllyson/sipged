import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_state.dart';

import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/notification_type.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/box_list_files.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/dropdown/drop_down_yes_no.dart';

class SectionDocumentos extends StatefulWidget {
  final bool isEditable;
  final DfdData data;
  final void Function(DfdData updated) onChanged;
  final String contractId;

  const SectionDocumentos({
    super.key,
    required this.isEditable,
    required this.data,
    required this.onChanged,
    required this.contractId,
  });

  @override
  State<SectionDocumentos> createState() => _SectionDocumentosState();
}

class _SectionDocumentosState extends State<SectionDocumentos> {
  StreamSubscription<DfdState>? _sub;

  bool _busy = false;
  double? _uploadProgress;

  int? _selectedIndex;
  List<Attachment> _items = const [];

  String? _lastDfdId;
  String? _lastDocsId;

  @override
  void initState() {
    super.initState();

    final cubit = context.read<DfdCubit>();

    _sub = cubit.stream.listen((state) async {
      if (!mounted) return;
      if (state.loading) return;

      final dfdId = state.dfdId;
      final docsId = state.currentDocsCheckId;

      if (dfdId == null || docsId == null) return;

      final changed = dfdId != _lastDfdId || docsId != _lastDocsId;

      if (!changed) return;

      _lastDfdId = dfdId;
      _lastDocsId = docsId;

      await _refreshDocs(
        dfdId: dfdId,
        documentosId: docsId,
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final state = context.read<DfdCubit>().state;
      final dfdId = state.dfdId;
      final docsId = state.currentDocsCheckId;

      if (dfdId == null || docsId == null) return;

      _lastDfdId = dfdId;
      _lastDocsId = docsId;

      _refreshDocs(
        dfdId: dfdId,
        documentosId: docsId,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _notifyError(String message) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Erro',
        subtitle: message,
        type: NotificationStatus.error,
        leadingLabel: 'DFD',
      ),
    );
  }

  void _notifyWarning(String message) {
    if (!mounted) return;

    context.read<NotificationLocalCubit>().show(
      NotificationData(
        title: 'Atenção',
        subtitle: message,
        type: NotificationStatus.warning,
        leadingLabel: 'DFD',
      ),
    );
  }

  Future<void> _refreshDocs({
    required String dfdId,
    required String documentosId,
  }) async {
    if (!mounted) return;

    setState(() => _busy = true);

    try {
      final list = await context.read<DfdCubit>().listarDocsDfd(
        contractId: widget.contractId,
        dfdId: dfdId,
        documentosId: documentosId,
      );

      if (!mounted) return;

      setState(() {
        _items = list;

        if (_selectedIndex != null && _selectedIndex! >= _items.length) {
          _selectedIndex = _items.isEmpty ? null : _items.length - 1;
        }
      });
    } catch (_) {
      _notifyError('Falha ao carregar anexos do DFD.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _addDoc() async {
    final cubit = context.read<DfdCubit>();
    final state = cubit.state;
    final dfdId = state.dfdId;
    final documentosId = state.currentDocsCheckId;

    if (dfdId == null || documentosId == null) {
      _notifyWarning('Aguarde: preparando área de documentos...');
      return;
    }

    setState(() => _uploadProgress = 0.0);

    try {
      final attachment = await cubit.uploadDocDfd(
        contractId: widget.contractId,
        dfdId: dfdId,
        documentosId: documentosId,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
        allowedExtensions: const <String>[
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'webp',
        ],
      );

      if (!mounted) return;

      setState(() {
        _items = <Attachment>[..._items, attachment]
          ..sort((a, b) => a.label.compareTo(b.label));

        _selectedIndex = _items.indexWhere(
              (item) => item.path == attachment.path,
        );

        if (_selectedIndex == -1) {
          _selectedIndex = _items.length - 1;
        }
      });
    } catch (error) {
      final text = error.toString();

      if (text.contains('Nenhum arquivo selecionado')) {
        return;
      }

      _notifyError('Falha no upload do anexo.');
    } finally {
      if (mounted) {
        setState(() => _uploadProgress = null);
      }
    }
  }

  Future<void> _deleteAt(int index) async {
    if (index < 0 || index >= _items.length) return;

    final cubit = context.read<DfdCubit>();
    final state = cubit.state;
    final dfdId = state.dfdId;
    final documentosId = state.currentDocsCheckId;

    if (dfdId == null || documentosId == null) {
      _notifyWarning('Área de documentos ainda não está pronta.');
      return;
    }

    final fileName = _items[index].label;

    final ok = await cubit.deleteDocDfd(
      contractId: widget.contractId,
      dfdId: dfdId,
      documentosId: documentosId,
      fileName: fileName,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        final list = <Attachment>[..._items]..removeAt(index);
        _items = list;

        if (_items.isEmpty) {
          _selectedIndex = null;
        } else if (_selectedIndex != null) {
          if (_selectedIndex! == index) {
            _selectedIndex = (index - 1).clamp(0, _items.length - 1);
          } else if (_selectedIndex! > index) {
            _selectedIndex = _selectedIndex! - 1;
          }
        }
      });
    } else {
      _notifyError('Não foi possível excluir o anexo.');
    }
  }

  void _updateEtp(String? value) {
    widget.onChanged(widget.data.copyWith(etpAnexo: value));
  }

  void _updateProjetoBasico(String? value) {
    widget.onChanged(widget.data.copyWith(projetoBasico: value));
  }

  void _updateTermoMatriz(String? value) {
    widget.onChanged(widget.data.copyWith(termoMatrizRiscos: value));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(text: '6) Documentos / Checklists'),
        LayoutBuilder(
          builder: (context, inner) {
            final isNarrow = inner.maxWidth < 820;
            final panelWidth = isNarrow ? inner.maxWidth : 300.0;

            double inputW(int perLine) {
              return responsiveInputWidth(
                context: context,
                itemsPerLine: perLine,
                containerWidth: inner.maxWidth,
                reservedWidth: isNarrow ? 0.0 : panelWidth,
                spaceBetweenReserved: isNarrow ? 0.0 : 12.0,
                margin: 12,
                extraPadding: 0.0,
                spacing: 12.0,
                minItemWidth: 260.0,
                minWidthSmallScreen: 280,
                forceItemsPerLineOnSmall: true,
              );
            }

            final rightInputs = Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: inputW(3),
                  child: DropDownYesNoDrop(
                    labelText: 'ETP/Estudos preliminares anexos?',
                    enabled: widget.isEditable,
                    value: d.etpAnexo,
                    controller: _updateEtp,
                  ),
                ),
                SizedBox(
                  width: inputW(3),
                  child: DropDownYesNoDrop(
                    labelText: 'Projeto básico/executivo disponível?',
                    enabled: widget.isEditable,
                    value: d.projetoBasico,
                    controller: _updateProjetoBasico,
                  ),
                ),
                SizedBox(
                  width: inputW(3),
                  child: DropDownYesNoDrop(
                    labelText: 'Termo de Referência/Matriz de riscos?',
                    enabled: widget.isEditable,
                    value: d.termoMatrizRiscos,
                    controller: _updateTermoMatriz,
                  ),
                ),
              ],
            );

            final attachmentsPanel = SizedBox(
              width: panelWidth,
              child: BoxListFiles(
                title: 'Documentos do DFD',
                items: _items,
                width: panelWidth,
                selectedIndex: _selectedIndex,
                onAddPressed: widget.isEditable ? _addDoc : null,
                onDelete: widget.isEditable ? _deleteAt : null,
                loading: _busy,
                uploadProgress: _uploadProgress,
                enableRename: widget.isEditable,
                onItemsChanged: (newItems) {
                  final cast = newItems.whereType<Attachment>().toList();

                  if (!mounted) return;

                  setState(() => _items = cast);
                },
              ),
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  attachmentsPanel,
                  const SizedBox(height: 12),
                  rightInputs,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                attachmentsPanel,
                const SizedBox(width: 12),
                Expanded(child: rightInputs),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}