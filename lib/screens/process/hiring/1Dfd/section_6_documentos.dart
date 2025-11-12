// lib/screens/process/hiring/1Dfd/section_6_documentos.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_controller.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_storage_bloc.dart';
import 'package:siged/_widgets/layout/responsive_utils.dart';

import 'package:siged/_widgets/list/files/side_list_box.dart';
import 'package:siged/_widgets/list/files/attachment.dart';
import 'package:siged/_widgets/texts/section_text_name.dart';

import '../../../../_widgets/input/dropdown_yes_no.dart';

class SectionDocumentos extends StatefulWidget {
  final DfdController controller;
  final String contractId;

  const SectionDocumentos({
    super.key,
    required this.controller,
    required this.contractId,
  });

  @override
  State<SectionDocumentos> createState() => _SectionDocumentosState();
}

class _SectionDocumentosState extends State<SectionDocumentos> {
  late final DfdStorageBloc _storage;
  late final StreamSubscription<DfdState> _sub;

  bool _busy = false;
  double? _uploadProgress;
  int? _selectedIndex;
  List<Attachment> _items = const [];

  @override
  void initState() {
    super.initState();
    _storage = DfdStorageBloc();

    // Observa quando IDs válidos estão prontos para listar anexos (seção documentos)
    _sub = context.read<DfdBloc>().stream.listen((state) async {
      final docsId = state.sectionIds['documentos'];
      if (!state.loading && state.dfdId != null && docsId != null) {
        await _refreshDocs(state.dfdId!, docsId);
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _refreshDocs(String dfdId, String documentosId) async {
    setState(() => _busy = true);
    try {
      final list = await _storage.listarDocsDfd(
        contractId: widget.contractId,
        dfdId: dfdId,
        documentosId: documentosId,
      );
      if (mounted) setState(() => _items = list);
    } catch (e) {
      debugPrint('DFD refresh docs error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao carregar anexos do DFD.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addDoc() async {
    final state = context.read<DfdBloc>().state;
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
        onProgress: (p) => setState(() => _uploadProgress = p),
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
      );
      setState(() => _items = [..._items, a]);
    } catch (e) {
      debugPrint('DFD upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha no upload do anexo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadProgress = null);
    }
  }

  Future<void> _deleteAt(int i) async {
    if (i < 0 || i >= _items.length) return;

    final state = context.read<DfdBloc>().state;
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
    if (ok) {
      setState(() {
        final list = [..._items]..removeAt(i);
        _items = list;
        if (_selectedIndex != null && _selectedIndex! >= _items.length) {
          _selectedIndex = _items.isEmpty ? null : _items.length - 1;
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o anexo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 820;
    final panelWidth = isNarrow ? MediaQuery.of(context).size.width : 300.0;

    double inputW(int perLine) => responsiveInputWidth(
      context: context,
      itemsPerLine: perLine,
      containerWidth: MediaQuery.of(context).size.width,
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
        YesNoDrop(
          width: inputW(3),
          label: 'ETP/Estudos preliminares anexos?',
          enabled: widget.controller.isEditable,
          value: widget.controller.dfdEtpAnexoValue,
          onChanged: (v) => setState(() => widget.controller.dfdEtpAnexoValue = v),
        ),
        YesNoDrop(
          width: inputW(3),
          label: 'Projeto básico/executivo disponível?',
          enabled: widget.controller.isEditable,
          value: widget.controller.dfdProjetoBasicoValue,
          onChanged: (v) => setState(() => widget.controller.dfdProjetoBasicoValue = v),
        ),
        YesNoDrop(
          width: inputW(3),
          label: 'Termo de Referência/Matriz de riscos?',
          enabled: widget.controller.isEditable,
          value: widget.controller.dfdTermoMatrizRiscosValue,
          onChanged: (v) => setState(() => widget.controller.dfdTermoMatrizRiscosValue = v),
        ),
        YesNoDrop(
          width: inputW(3),
          label: 'Parecer jurídico prévio?',
          enabled: widget.controller.isEditable,
          value: widget.controller.dfdParecerJuridicoValue,
          onChanged: (v) => setState(() => widget.controller.dfdParecerJuridicoValue = v),
        ),
        YesNoDrop(
          width: inputW(3),
          label: 'Autorização de abertura do processo?',
          enabled: widget.controller.isEditable,
          value: widget.controller.dfdAutorizacaoAberturaValue,
          onChanged: (v) => setState(() => widget.controller.dfdAutorizacaoAberturaValue = v),
        ),
      ],
    );

    final attachmentsPanel = SizedBox(
      width: panelWidth,
      child: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_uploadProgress != null) const SizedBox(height: 6),
          if (_uploadProgress != null) LinearProgressIndicator(value: _uploadProgress),
          const SizedBox(height: 5),
          SideListBox(
            title: 'Documentos do DFD',
            items: _items,
            width: panelWidth,
            selectedIndex: _selectedIndex,
            onTap: (i) => setState(() => _selectedIndex = i),
            onAddPressed: widget.controller.isEditable ? _addDoc : null,
            onDelete: widget.controller.isEditable ? _deleteAt : null,
            onEditLabel: widget.controller.isEditable
                ? (i) async {
              final current = _items[i].label;
              final ctrl = TextEditingController(text: current);
              final newLabel = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Renomear anexo'),
                  content: TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Novo rótulo'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                      child: const Text('Salvar'),
                    ),
                  ],
                ),
              );
              if (newLabel != null && newLabel.isNotEmpty) {
                setState(() {
                  final cur = _items[i];
                  _items = [
                    ..._items.sublist(0, i),
                    cur.copyWith(label: newLabel),
                    ..._items.sublist(i + 1),
                  ];
                });
              }
            }
                : null,
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('6) Documentos / Checklists'),
        LayoutBuilder(builder: (context, inner) {
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                attachmentsPanel,
                const SizedBox(height: 12),
                rightInputs,
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                attachmentsPanel,
                const SizedBox(width: 12),
                Expanded(child: rightInputs),
              ],
            );
          }
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
