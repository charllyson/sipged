import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/bands_header.dart';
import 'package:siged/_widgets/table/magic/body_row.dart';
import 'package:siged/_widgets/table/magic/gutter_header_box.dart';
import 'package:siged/_widgets/table/magic/trailing_col_meta.dart';
import 'magic_table_controller.dart' as bc;

// Já existentes no seu projeto
import 'header_row.dart';

typedef TrailingRowBuilder = List<Widget> Function(
    BuildContext context,
    int rowIndex, // 1..N (sem o header)
    );

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

    // painéis opcionais
    this.leadingWidth = 0,
    this.leadingHeaderBuilder,
    this.leadingCellBuilder,

    // painel direito (continuação)
    this.trailingCols = const <TrailingColMeta>[],
    this.trailingRowBuilder,

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

  final List<TrailingColMeta> trailingCols;
  final TrailingRowBuilder? trailingRowBuilder;

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

  @override
  State<MagicTableChanged> createState() => _MagicTableChangedState();
}

class _MagicTableChangedState extends State<MagicTableChanged> {
  // Scrollers sincronizados
  final _hHeaderCtrl = ScrollController();
  final _hGridCtrl = ScrollController();
  final _vGutterCtrl = ScrollController();
  final _vGridCtrl = ScrollController();

  int? _editRow;
  int? _editCol;
  final TextEditingController _cellController = TextEditingController();
  final FocusNode _cellFocus = FocusNode();

  bool _didInit = false;

  static const double _bandHeight = 28;

  @override
  void initState() {
    super.initState();

    // H: header <-> grid
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

    // V: gutter <-> grid
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

  double get _trailingTotalWidth =>
      widget.trailingCols.fold<double>(0.0, (s, e) => s + e.width);

  // ===== regras visuais por linha (compartilhadas pelos subwidgets)

  bool _isUpperCase(String v) {
    final only = v.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    return only.isNotEmpty && only == only.toUpperCase();
  }

  RowStyleResolver get _rowStyleResolver {
    return (int r) {
      final rows = widget.controller.tableData;
      final isFirst = r == 0;
      final firstCol  = (r < rows.length && rows[r].isNotEmpty) ? rows[r][0] : '';
      final secondCol = (r < rows.length && rows[r].length > 1) ? rows[r][1] : '';

      final isIntegerRow   = !isFirst && int.tryParse(firstCol) != null;
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

  // ===== util: somas de largura (usadas no header de bandas)
  double _sumMainCols(int from, int toInclusive) {
    final w = widget.controller.colWidths;
    double acc = 0;
    for (int i = from; i <= toInclusive && i < w.length; i++) acc += w[i];
    return acc;
  }

  double _sumTrailingCols(int start, int count) {
    double acc = 0;
    for (int i = 0; i < count && (start + i) < widget.trailingCols.length; i++) {
      acc += widget.trailingCols[start + i].width;
    }
    return acc;
  }

  @override
  Widget build(BuildContext context) {
    _ensureInitOnce();

    final ctrl = widget.controller;
    final hasLeading = widget.leadingWidth > 0 &&
        (widget.leadingHeaderBuilder != null ||
            widget.leadingCellBuilder != null);
    final hasTrailing = widget.trailingCols.isNotEmpty;
    final rowCountWithGhost = ctrl.rowCount + 1;

    final tableContent = !ctrl.hasData
        ? const Center(child: Text('Cole dados do Excel aqui (Ctrl+V).'))
        : Column(
      children: [
        // ====== HEADER: bandas + letras no MESMO scroller
        Row(
          children: [
            // gutter fixo (altura = bandas + letras)
            GutterHeaderBox(
              width: widget.gutterWidth,
              height: _bandHeight + widget.headerHeight,
            ),
            SizedBox(width: widget.gap),

            // leading fixo (se houver)
            if (hasLeading)
              SizedBox(
                width: widget.leadingWidth,
                height: _bandHeight + widget.headerHeight,
                child: widget.leadingHeaderBuilder?.call(context),
              ),
            if (hasLeading) SizedBox(width: widget.gap),

            // 🔹 scroller único (bandas + letras + trailing)
            Expanded(
              child: SingleChildScrollView(
                controller: _hHeaderCtrl,
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bandas (Contrato / Quantidade / Valor)
                    MagicBandsHeader(
                      bandHeight: _bandHeight,
                      mainGridWidth: _mainGridWidth,
                      trailingCols: widget.trailingCols,
                      contratoWidth: _sumMainCols(0, 5),
                      quantidadeWidth: _sumTrailingCols(0, 4),
                      valorWidth: _sumTrailingCols(4, 4),
                    ),
                    const SizedBox(height: 2),
                    MagicHeaderRow(
                      ctrl: ctrl,
                      hHeaderCtrl: _hHeaderCtrl,
                      headerHeight: widget.headerHeight,
                      ghostColWidth: 0,
                      rightScrollGap: 0,
                      onAddColumn: null,
                      onRemoveColumn: null,
                      allowAddColumn: false,
                      allowRemoveColumn: false,
                      showTypeBadge: true,
                      extraCount: widget.trailingCols.length,
                      extraWidth: (i) => widget.trailingCols[i].width,
                      extraLabel: (i) =>
                          ctrl.excelColName(ctrl.colCount + i),
                      useExternalHScroll: true,
                      addTopBorder: true, // ✅ resolve o “vazio” no topo
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: widget.gap),

        // ====== CORPO
        if (!widget.useExternalVScroll)
          Expanded(
            child: MagicBodyRow(
              ctrl: ctrl,
              rowCountWithGhost: rowCountWithGhost,
              hasLeading: hasLeading,
              hasTrailing: hasTrailing,
              gutterWidth: widget.gutterWidth,
              leadingWidth: widget.leadingWidth,
              mainGridWidth: _mainGridWidth,
              trailingTotalWidth: _trailingTotalWidth,
              trailingCols: widget.trailingCols,
              cellPad: widget.cellPad,
              rowHeight: widget.rowHeight,
              gap: widget.gap,
              bottomScrollGap: widget.bottomScrollGap,
              useExternalVScroll: widget.useExternalVScroll,
              vGutterCtrl: _vGutterCtrl,
              vGridCtrl: _vGridCtrl,
              hGridCtrl: _hGridCtrl,
              editRow: _editRow,
              editCol: _editCol,
              cellController: _cellController,
              cellFocus: _cellFocus,
              onStartEdit: _startEdit,
              onCommitEdit: _commitEdit,
              vPhysics: widget.useExternalVScroll
                  ? const NeverScrollableScrollPhysics()
                  : null,
              leadingHeaderBuilder: widget.leadingHeaderBuilder,
              leadingCellBuilder: widget.leadingCellBuilder,
              rowStyleResolver: _rowStyleResolver,
              trailingRowBuilder: widget.trailingRowBuilder,
            ),
          )
        else
          MagicBodyRow(
            ctrl: ctrl,
            rowCountWithGhost: rowCountWithGhost,
            hasLeading: hasLeading,
            hasTrailing: hasTrailing,
            gutterWidth: widget.gutterWidth,
            leadingWidth: widget.leadingWidth,
            mainGridWidth: _mainGridWidth,
            trailingTotalWidth: _trailingTotalWidth,
            trailingCols: widget.trailingCols,
            cellPad: widget.cellPad,
            rowHeight: widget.rowHeight,
            gap: widget.gap,
            bottomScrollGap: widget.bottomScrollGap,
            useExternalVScroll: widget.useExternalVScroll,
            vGutterCtrl: _vGutterCtrl,
            vGridCtrl: _vGridCtrl,
            hGridCtrl: _hGridCtrl,
            editRow: _editRow,
            editCol: _editCol,
            cellController: _cellController,
            cellFocus: _cellFocus,
            onStartEdit: _startEdit,
            onCommitEdit: _commitEdit,
            vPhysics: widget.useExternalVScroll
                ? const NeverScrollableScrollPhysics()
                : null,
            leadingHeaderBuilder: widget.leadingHeaderBuilder,
            leadingCellBuilder: widget.leadingCellBuilder,
            rowStyleResolver: _rowStyleResolver,
            trailingRowBuilder: widget.trailingRowBuilder,

          ),
      ],
    );

    return Stack(
      children: [
        if (!widget.useExternalVScroll)
          Column(children: [Expanded(child: tableContent)])
        else
          tableContent,

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
