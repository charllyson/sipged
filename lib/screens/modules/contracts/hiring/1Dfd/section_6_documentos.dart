import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_state.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_storage_bloc.dart';

import 'package:sipged/_widgets/layout/responsive_utils.dart';
import 'package:sipged/_widgets/list/files/side_list_box.dart';
import 'package:sipged/_widgets/list/files/attachment.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/input/drop_down_yes_no.dart';

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
  late final DfdStorageBloc _storage;
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
    _storage = DfdStorageBloc();

    final cubit = context.read<DfdCubit>();
    _sub = cubit.stream.listen((state) async {
      if (!mounted) return;
      if (state.loading) return;

      final dfdId = state.dfdId;
      final docsId = state.sectionIds['documentos'];

      if (dfdId == null || docsId == null) return;

      final changed = dfdId != _lastDfdId || docsId != _lastDocsId;
      if (!changed) return;

      _lastDfdId = dfdId;
      _lastDocsId = docsId;

      await _refreshDocs(dfdId, docsId);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refreshDocs(String dfdId, String documentosId) async {
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final list = await _storage.listarDocsDfd(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar anexos do DFD.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addDoc() async {
    final state = context.read<DfdCubit>().state;
    final dfdId = state.dfdId;
    final documentosId = state.sectionIds['documentos'];

    if (dfdId == null || documentosId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguarde: preparando área de documentos...')),
      );
      return;
    }

    setState(() => _uploadProgress = 0.0);
    try {
      final a = await _storage.uploadFile(
        contractId: widget.contractId,
        dfdId: dfdId,
        documentosId: documentosId,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (!mounted) return;

      setState(() {
        _items = [..._items, a];
        _selectedIndex = _items.length - 1;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha no upload do anexo.')),
      );
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  Future<void> _deleteAt(int i) async {
    if (i < 0 || i >= _items.length) return;

    final state = context.read<DfdCubit>().state;
    final dfdId = state.dfdId;
    final documentosId = state.sectionIds['documentos'];
    if (dfdId == null || documentosId == null) return;

    final fileName = _items[i].label;

    final ok = await _storage.deleteFile(
      contractId: widget.contractId,
      dfdId: dfdId,
      documentosId: documentosId,
      fileName: fileName,
    );

    if (!mounted) return;

    if (ok) {
      setState(() {
        final list = [..._items]..removeAt(i);
        _items = list;

        if (_items.isEmpty) {
          _selectedIndex = null;
        } else if (_selectedIndex != null) {
          if (_selectedIndex! == i) {
            _selectedIndex = (i - 1).clamp(0, _items.length - 1);
          } else if (_selectedIndex! > i) {
            _selectedIndex = _selectedIndex! - 1;
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o anexo.')),
      );
    }
  }

  void _updateEtp(String? v) => widget.onChanged(widget.data.copyWith(etpAnexo: v));
  void _updateProjetoBasico(String? v) =>
      widget.onChanged(widget.data.copyWith(projetoBasico: v));
  void _updateTermoMatriz(String? v) =>
      widget.onChanged(widget.data.copyWith(termoMatrizRiscos: v));

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

            double inputW(int perLine) => responsiveInputWidth(
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

            final rightInputs = Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: inputW(3),
                  child: YesNoDrop(
                    labelText: 'ETP/Estudos preliminares anexos?',
                    enabled: widget.isEditable,
                    value: d.etpAnexo,
                    controller: _updateEtp,
                  ),
                ),
                SizedBox(
                  width: inputW(3),
                  child: YesNoDrop(
                    labelText: 'Projeto básico/executivo disponível?',
                    enabled: widget.isEditable,
                    value: d.projetoBasico,
                    controller: _updateProjetoBasico,
                  ),
                ),
                SizedBox(
                  width: inputW(3),
                  child: YesNoDrop(
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
              child: SideListBox(
                title: 'Documentos do DFD',
                items: _items,
                width: panelWidth,
                selectedIndex: _selectedIndex,
                onAddPressed: widget.isEditable ? _addDoc : null,
                onDelete: widget.isEditable ? _deleteAt : null,
                loading: _busy,
                uploadProgress: _uploadProgress,

                // ✅ agora o SideListBox cuida do rename; só mantemos o pai sincronizado
                enableRename: widget.isEditable,
                onItemsChanged: (newItems) {
                  final cast = newItems.whereType<Attachment>().toList();
                  if (!mounted) return;
                  setState(() => _items = cast);
                },

                // (opcional) se quiser persistir rename depois, pluga aqui
                // onRenamePersist: ({required index, required oldItem, required newItem}) async {
                //   // TODO: persistir (ex: salvar metadata/FireStore)
                //   return true;
                // },
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
