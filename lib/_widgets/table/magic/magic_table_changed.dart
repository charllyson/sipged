import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:siged/_widgets/table/magic/bands_header.dart';
import 'package:siged/_widgets/table/magic/grid_body.dart';
import 'package:siged/_widgets/table/magic/gutter_column.dart';
import 'package:siged/_widgets/table/magic/gutter_header_box.dart';
import 'package:siged/_widgets/table/magic/leading_column.dart';
import 'package:siged/_widgets/table/magic/bands_footer.dart';

import 'magic_table_controller.dart' as bc;
import 'header_row.dart';

typedef RowStyleResolver = ({Color bg, TextStyle text}) Function(int r);

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

    // painel esquerdo (opcional)
    this.leadingWidth = 0,
    this.leadingHeaderBuilder,
    this.leadingCellBuilder,

    this.floatingActionsBuilder,

    this.bottomScrollGap = 0,
    this.rightScrollGap = 0,

    this.selectAllOnEdit = !kIsWeb,

    this.onRequestSaveAfterStructureChange,

    // flags
    this.allowAddColumn = true,
    this.allowRemoveColumn = true,
    this.allowAddRow = true,

    /// Quando true, não há scroll vertical interno (usa o da página)
    this.useExternalVScroll = false,

    /// Quando null, usa o footer de totais por grupo
    this.footerBarBuilder,
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

  final Future<void> Function(bc.MagicTableController ctrl)?
  onRequestSaveAfterStructureChange;

  final bool allowAddColumn;
  final bool allowRemoveColumn;
  final bool allowAddRow;

  final bool useExternalVScroll;

  final Widget Function(BuildContext context, bc.MagicTableController ctrl)?
  footerBarBuilder;

  @override
  State<MagicTableChanged> createState() => _MagicTableChangedState();
}

class _MagicTableChangedState extends State<MagicTableChanged> {
  // scrollers
  final _hGridCtrl = ScrollController();
  final _vGutterCtrl = ScrollController();
  final _vGridCtrl = ScrollController();

  int? _editRow;
  int? _editCol;
  final TextEditingController _cellController = TextEditingController();
  final FocusNode _cellFocus = FocusNode();

  bool _didInit = false;

  static const double _bandHeight = 28;
  double _totalRowHeight = 36;

  @override
  void initState() {
    super.initState();

    // V: manter gutter e grid sincronizados
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

    if (widget.selectAllOnEdit) {
      _cellController.selection =
          TextSelection(baseOffset: 0, extentOffset: cell.length);
    } else {
      _cellController.selection =
          TextSelection.collapsed(offset: cell.length);
    }

    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) FocusScope.of(context).requestFocus(_cellFocus);
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

  double get _mainGridWidth =>
      widget.controller.colWidths.fold<double>(0.0, (s, w) => s + w);

  // ===== estilo por linha (mantido p/ leading e grid)
  bool _isUpperCase(String v) {
    final only = v.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    return only.isNotEmpty && only == only.toUpperCase();
  }

  RowStyleResolver get _rowStyleResolver {
    return (int r) {
      final rows = widget.controller.tableData;
      final isFirst = r == 0;
      final firstCol =
      (r < rows.length && rows[r].isNotEmpty) ? rows[r][0] : '';
      final secondCol =
      (r < rows.length && rows[r].length > 1) ? rows[r][1] : '';

      final isIntegerRow = !isFirst && int.tryParse(firstCol) != null;
      final isUpperCaseRow = !isFirst && _isUpperCase(secondCol);

      final bg = isFirst
          ? const Color(0xFF091D68)
          : isIntegerRow
          ? Colors.grey.shade200
          : isUpperCaseRow
          ? Colors.grey.shade100
          : Colors.white;

      final text = isFirst
          ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
          : isIntegerRow
          ? const TextStyle(fontWeight: FontWeight.w600)
          : isUpperCaseRow
          ? const TextStyle(fontStyle: FontStyle.italic)
          : const TextStyle();

      return (bg: bg, text: text);
    };
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitOnce();

    final ctrl = widget.controller;
    final hasLeading = widget.leadingWidth > 0 &&
        (widget.leadingHeaderBuilder != null ||
            widget.leadingCellBuilder != null);
    final rowCountWithGhost = ctrl.rowCount + 1;

    if (!ctrl.hasData) {
      return const Center(child: Text('Cole dados do Excel aqui (Ctrl+V).'));
    }

    // largura total do conteúdo dentro do scroller horizontal único
    final double totalHorizontalWidth =
        widget.gutterWidth +
            widget.gap +
            (hasLeading ? widget.leadingWidth + widget.gap : 0) +
            _mainGridWidth +
            widget.rightScrollGap;

    // ====== CONSTRUÇÃO COM CONSTRAINT VERTICAL (evita overflow)
    Widget buildTableContent(BoxConstraints constraints) {
      // Altura disponível (quando estamos dentro do Expanded)
      final maxH = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : MediaQuery.of(context).size.height;

      // Alturas fixas dos blocos
      final headerBlockH = _bandHeight + widget.headerHeight; // bands + header
      final footerBlockH = _totalRowHeight;                    // footer totals
      // gaps e pequenos espaçamentos verticais
      final extraGaps = widget.gap /* gap entre header e body */ + 2 /* margens internas */;

      // Altura disponível para o BODY (apenas quando usamos scroll interno)
      final double bodyHeight = (maxH - headerBlockH - footerBlockH - extraGaps)
          .clamp(120.0, maxH);

      final headerRow = Row(
        children: [
          GutterHeaderBox(
            width: widget.gutterWidth,
            height: _bandHeight + widget.headerHeight,
          ),
          SizedBox(width: widget.gap),

          if (hasLeading)
            SizedBox(
              width: widget.leadingWidth,
              height: _bandHeight + widget.headerHeight,
              child: widget.leadingHeaderBuilder?.call(context),
            ),
          if (hasLeading) SizedBox(width: widget.gap),

          SizedBox(
            width: _mainGridWidth + widget.rightScrollGap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MagicBandsHeader(
                  ctrl: ctrl,
                  bandHeight: _bandHeight,
                  addTopBorder: true,
                ),
                const SizedBox(height: 2),
                MagicHeaderRow(
                  hHeaderCtrl: _hGridCtrl,
                  ctrl: ctrl,
                  headerHeight: widget.headerHeight,
                  ghostColWidth: 0,
                  rightScrollGap: 0,
                  onAddColumn: null,
                  onRemoveColumn: null,
                  allowAddColumn: false,
                  allowRemoveColumn: false,
                  showTypeBadge: true,
                  useExternalHScroll: true,
                  addTopBorder: true,
                ),
              ],
            ),
          ),
        ],
      );

      // BODY: com ou sem altura limitada dependendo do useExternalVScroll
      final bodyRow = Row(
        children: [
          SizedBox(
            width: widget.gutterWidth,
            child: MagicGutterColumn(
              ctrl: ctrl,
              vGutterCtrl: _vGutterCtrl,
              rowHeight: widget.rowHeight,
              rowCountWithGhost: rowCountWithGhost,
              bottomScrollGap: widget.bottomScrollGap,
              onAddRow: null,
              addTopBorder: false,
            ),
          ),
          SizedBox(width: widget.gap),

          if (hasLeading)
            SizedBox(
              width: widget.leadingWidth,
              child: widget.useExternalVScroll
                  ? MagicLeadingColumn(
                rowCount: ctrl.rowCount,
                rowHeight: widget.rowHeight,
                bottomScrollGap: widget.bottomScrollGap,
                leadingHeaderBuilder: widget.leadingHeaderBuilder,
                leadingCellBuilder: widget.leadingCellBuilder,
                rowStyleResolver: _rowStyleResolver,
              )
                  : Scrollbar( // Scrollbar apenas sobre o scroll vertical interno do leading
                controller: _vGridCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _vGridCtrl,
                  child: MagicLeadingColumn(
                    rowCount: ctrl.rowCount,
                    rowHeight: widget.rowHeight,
                    bottomScrollGap: widget.bottomScrollGap,
                    leadingHeaderBuilder: widget.leadingHeaderBuilder,
                    leadingCellBuilder: widget.leadingCellBuilder,
                    rowStyleResolver: _rowStyleResolver,
                  ),
                ),
              ),
            ),
          if (hasLeading) SizedBox(width: widget.gap),

          SizedBox(
            width: _mainGridWidth,
            child: Scrollbar( // Scrollbar vertical aplicada apenas ao grid (quando interno)
              controller: _vGridCtrl,
              thumbVisibility: true,
              child: MagicGridBody(
                ctrl: ctrl,
                vGridCtrl: _vGridCtrl,
                hGridCtrl: _hGridCtrl, // scroll H externo
                rowHeight: widget.rowHeight,
                cellPad: widget.cellPad,
                editRow: _editRow,
                editCol: _editCol,
                cellController: _cellController,
                cellFocus: _cellFocus,
                onStartEdit: _startEdit,
                onCommitEdit: _commitEdit,
                bottomScrollGap: widget.bottomScrollGap,
                rightScrollGap: 0,
                useExternalHScroll: true,
                useExternalVScroll: widget.useExternalVScroll,
                vPhysics: widget.useExternalVScroll
                    ? const NeverScrollableScrollPhysics()
                    : null,
              ),
            ),
          ),
        ],
      );

      final footerRow = Row(
        children: [
          GutterHeaderBox(
            width: widget.gutterWidth,
            height: _totalRowHeight,
          ),
          SizedBox(width: widget.gap),

          if (hasLeading)
            SizedBox(
              width: widget.leadingWidth,
              height: _totalRowHeight,
            ),
          if (hasLeading) SizedBox(width: widget.gap),

          SizedBox(
            width: _mainGridWidth + widget.rightScrollGap,
            child: widget.footerBarBuilder != null
                ? widget.footerBarBuilder!(context, ctrl)
                : MagicBandsFooter(
              ctrl: ctrl,
              height: _totalRowHeight,
              labelTotais: 'TOTAIS',
              rightScrollGap: widget.rightScrollGap,
              groupLabelForFirstCell: 'CONTRATO',
            ),
          ),
        ],
      );

      // Montagem vertical da tabela
      final tableColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerRow,
          SizedBox(height: widget.gap),
          // Se usamos scroll interno, limitamos a altura do BODY para evitar overflow
          if (!widget.useExternalVScroll)
            SizedBox(height: bodyHeight, child: bodyRow)
          else
            bodyRow,
          footerRow,
        ],
      );

      // Scroller horizontal único com Scrollbar horizontal
      final horizontal = Scrollbar(
        controller: _hGridCtrl,
        thumbVisibility: true,
        notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
        child: SingleChildScrollView(
          controller: _hGridCtrl,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalHorizontalWidth,
            child: tableColumn,
          ),
        ),
      );

      return horizontal;
    }

    // ===== retorno final com/sem Expanded e com FABs
    final mainContent = widget.useExternalVScroll
        ? LayoutBuilder(builder: (ctx, c) => buildTableContent(c))
        : Column(
      children: [
        Expanded(
          child: LayoutBuilder(builder: (ctx, c) => buildTableContent(c)),
        ),
      ],
    );

    return Stack(
      children: [
        mainContent,
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
