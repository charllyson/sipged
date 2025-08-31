import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'magic_table_controller.dart' as bc;

import 'header_row.dart';
import 'gutter_column.dart';
import 'grid_body.dart';

class MagicTableChanged extends StatefulWidget {
  const MagicTableChanged({
    super.key,
    required this.controller,
    this.onInit,
    this.gap = 3,
    this.rowHeight = 44,
    this.headerHeight = 40,
    this.gutterWidth = 56,
    this.cellPad = const EdgeInsets.symmetric(horizontal: 12),
    this.leadingWidth = 0,
    this.leadingHeaderBuilder,
    this.leadingCellBuilder,
    this.floatingActionsBuilder,

    /// Espaço vertical extra que rola junto (no final).
    this.bottomScrollGap = 0,

    /// Espaço horizontal extra no final (lado direito) que rola junto.
    this.rightScrollGap = 0,

    /// Se deve selecionar todo o conteúdo ao iniciar a edição.
    /// Por padrão, **no Web** NÃO seleciona tudo (cursor no fim),
    /// e no mobile seleciona (melhor UX para sobrescrita).
    this.selectAllOnEdit = !kIsWeb,
  });

  final bc.MagicTableController controller;

  final Future<void> Function(bc.MagicTableController ctrl)? onInit;

  final double gap;
  final double rowHeight;
  final double headerHeight;
  final double gutterWidth;
  final EdgeInsets cellPad;

  final double leadingWidth;
  final Widget Function(BuildContext context)? leadingHeaderBuilder;
  final Widget Function(BuildContext context, int row)? leadingCellBuilder;

  final List<Widget> Function(BuildContext context, bc.MagicTableController ctrl)?
  floatingActionsBuilder;

  final double bottomScrollGap;
  final double rightScrollGap;

  final bool selectAllOnEdit;

  @override
  State<MagicTableChanged> createState() => _MagicTableChangedState();
}

class _MagicTableChangedState extends State<MagicTableChanged> {
  final _hHeaderCtrl = ScrollController();
  final _hGridCtrl = ScrollController();
  final _vGutterCtrl = ScrollController();
  final _vGridCtrl = ScrollController();

  int? _editRow;
  int? _editCol;
  final TextEditingController _cellController = TextEditingController();
  final FocusNode _cellFocus = FocusNode();

  bool _didInit = false;

  @override
  void initState() {
    super.initState();

    _hGridCtrl.addListener(() {
      if (_hHeaderCtrl.hasClients && _hHeaderCtrl.offset != _hGridCtrl.offset) {
        _hHeaderCtrl.jumpTo(_hGridCtrl.offset);
      }
    });
    _hHeaderCtrl.addListener(() {
      if (_hGridCtrl.hasClients && _hGridCtrl.offset != _hHeaderCtrl.offset) {
        _hGridCtrl.jumpTo(_hHeaderCtrl.offset);
      }
    });

    _vGridCtrl.addListener(() {
      if (_vGutterCtrl.hasClients && _vGutterCtrl.offset != _vGridCtrl.offset) {
        _vGutterCtrl.jumpTo(_vGridCtrl.offset);
      }
    });
    _vGutterCtrl.addListener(() {
      if (_vGridCtrl.hasClients && _vGridCtrl.offset != _vGutterCtrl.offset) {
        _vGridCtrl.jumpTo(_vGutterCtrl.offset);
      }
    });

    _cellFocus.addListener(() {
      if (!_cellFocus.hasFocus && _editRow != null && _editCol != null) {
        _commitEdit();
      }
    });
  }

  @override
  void dispose() {
    _hHeaderCtrl.dispose();
    _hGridCtrl.dispose();
    _vGutterCtrl.dispose();
    _vGridCtrl.dispose();
    _cellController.dispose();
    _cellFocus.dispose();
    super.dispose();
  }

  void _ensureInitOnce() {
    if (_didInit) return;
    _didInit = true;
    if (widget.onInit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onInit!(widget.controller);
      });
    }
  }

  void _startEdit(int r, int c) {
    final ctrl = widget.controller;

    // commit anterior, se houver
    if (_editRow != null && _editCol != null) {
      final prevR = _editRow!;
      final prevC = _editCol!;
      final raw = _cellController.text;
      final value = ctrl.normalizeValueOnCommit(prevC, raw);
      ctrl.setCellValue(prevR, prevC, value);
    }

    _editRow = r;
    _editCol = c;

    String cell = '';
    if (r < ctrl.rowCount && c < ctrl.tableData[r].length) {
      cell = ctrl.tableData[r][c];
    }

    _cellController.text = cell;

    // 👇 Aqui está a mudança: seleção depende de selectAllOnEdit
    if (widget.selectAllOnEdit) {
      _cellController.selection = TextSelection(baseOffset: 0, extentOffset: cell.length);
    } else {
      _cellController.selection = TextSelection.collapsed(offset: cell.length);
    }

    setState(() {});

    // 👇 Garante foco (no mobile, isso abre o teclado; no desktop web não abre OSK)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_cellFocus);
      }
    });
  }

  void _commitEdit() {
    final ctrl = widget.controller;
    if (_editRow == null || _editCol == null) return;

    final r = _editRow!;
    final c = _editCol!;
    final raw = _cellController.text;

    if (c < 0 || c >= ctrl.colCount) {
      _editRow = _editCol = null;
      return;
    }

    final value = ctrl.normalizeValueOnCommit(c, raw);
    ctrl.setCellValue(r, c, value);

    _editRow = _editCol = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitOnce();

    final ctrl = widget.controller;
    final hasLeading = widget.leadingWidth > 0 &&
        (widget.leadingHeaderBuilder != null || widget.leadingCellBuilder != null);

    final rowCountWithGhost = ctrl.rowCount + 1;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: !ctrl.hasData
                  ? const Center(child: Text('Cole dados do Excel aqui (Ctrl+V).'))
                  : Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: widget.gutterWidth,
                        height: widget.headerHeight,
                        color: Colors.grey.shade100,
                      ),
                      SizedBox(width: widget.gap),
                      if (hasLeading)
                        Container(
                          width: widget.leadingWidth,
                          height: widget.headerHeight,
                          alignment: Alignment.center,
                          color: Colors.grey.shade100,
                          child: widget.leadingHeaderBuilder?.call(context),
                        ),
                      if (hasLeading) SizedBox(width: widget.gap),
                      Expanded(
                        child: MagicHeaderRow(
                          ctrl: ctrl,
                          hHeaderCtrl: _hHeaderCtrl,
                          headerHeight: widget.headerHeight,
                          ghostColWidth: 48,
                          rightScrollGap: widget.rightScrollGap,
                          onAddColumn: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _commitEdit();
                            ctrl.addEmptyColumnAtEnd();
                            final newC = ctrl.colCount - 1;
                            setState(() {});
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _startEdit(0, newC);
                            });
                          },
                          onRemoveColumn: (c) {
                            FocusManager.instance.primaryFocus?.unfocus();
                            _commitEdit();
                            ctrl.removeColumn(c);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.gap),
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: widget.gutterWidth,
                          child: MagicGutterColumn(
                            ctrl: ctrl,
                            vGutterCtrl: _vGutterCtrl,
                            rowHeight: widget.rowHeight,
                            rowCountWithGhost: rowCountWithGhost,
                            bottomScrollGap: widget.bottomScrollGap,
                            onAddRow: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              _commitEdit();
                              final newR = ctrl.rowCount;
                              ctrl.setCellValue(newR, 0, '');
                              setState(() {});
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _startEdit(newR, 0);
                              });
                            },
                          ),
                        ),
                        SizedBox(width: widget.gap),
                        if (hasLeading)
                          SizedBox(
                            width: widget.leadingWidth,
                            child: SingleChildScrollView(
                              controller: _vGridCtrl,
                              child: Column(
                                children: [
                                  ...List.generate(ctrl.rowCount, (r) {
                                    if (r == 0) {
                                      return Container(
                                        height: widget.rowHeight,
                                        color: Colors.grey.shade200,
                                        alignment: Alignment.center,
                                        child: widget.leadingHeaderBuilder?.call(context),
                                      );
                                    }
                                    return Container(
                                      height: widget.rowHeight,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          bottom: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      child: widget.leadingCellBuilder?.call(context, r),
                                    );
                                  }),
                                  SizedBox(height: widget.bottomScrollGap),
                                ],
                              ),
                            ),
                          ),
                        if (hasLeading) SizedBox(width: widget.gap),
                        Expanded(
                          child: MagicGridBody(
                            ctrl: ctrl,
                            vGridCtrl: _vGridCtrl,
                            hGridCtrl: _hGridCtrl,
                            rowHeight: widget.rowHeight,
                            cellPad: widget.cellPad,
                            editRow: _editRow,
                            editCol: _editCol,
                            cellController: _cellController,
                            cellFocus: _cellFocus,
                            onStartEdit: _startEdit,
                            onCommitEdit: _commitEdit,
                            bottomScrollGap: widget.bottomScrollGap,
                            rightScrollGap: widget.rightScrollGap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        if (widget.floatingActionsBuilder != null)
          Positioned(
            top: 72,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.floatingActionsBuilder!(context, ctrl),
            ),
          ),
      ],
    );
  }
}
