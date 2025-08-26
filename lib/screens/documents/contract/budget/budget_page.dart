import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:sisged/_blocs/documents/contracts/contracts/contract_data.dart';
import 'package:sisged/_widgets/background/background_cleaner.dart';
import 'package:sisged/_widgets/footBar/foot_bar.dart';

import 'package:sisged/_blocs/documents/contracts/budget/budget_store.dart';
import 'budget_controller.dart' as bc;

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, required this.contractData});
  final ContractData contractData;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  // Scrolls sincronizados
  final _hHeaderCtrl = ScrollController(); // header A..Z
  final _hGridCtrl = ScrollController();   // grade principal
  final _vGutterCtrl = ScrollController(); // gutter 1..N
  final _vGridCtrl = ScrollController();   // grade principal

  // Layout
  static const double _rowHeight = 44;
  static const double _headerHeight = 40;
  static const double _gutterWidth = 56;
  static const double _gap = 3;
  static const EdgeInsets _cellPad = EdgeInsets.symmetric(horizontal: 12);

  // Resize
  static const double _resizeHandleWidth = 8;

  // Âncoras do cabeçalho A..Z (para abrir o balão)
  List<GlobalKey> _headerKeysAZ = [];

  // Edição inline (um editor por vez)
  int? _editRow;
  int? _editCol;
  final TextEditingController _cellController = TextEditingController();
  final FocusNode _cellFocus = FocusNode();

  // Auto-load
  bool _didAutoLoad = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // sync horizontal
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

    // sync vertical
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

    // Salva quando perde o foco
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

  // --------- Ações (Salvar/Carregar) ----------
  Future<void> _onSaveBudget(bc.BudgetController ctrl) async {
    if (!ctrl.hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nada para salvar. Cole dados do Excel primeiro.')),
      );
      return;
    }
    final store = context.read<BudgetStore>();
    try {
      await store.saveBudget(
        contractId: widget.contractData.id!,
        headers: ctrl.headers,
        colTypes: ctrl.colTypesAsString,
        colWidths: ctrl.colWidths,
        rows: ctrl.tableData,
        rowsIncludesHeader: true,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento salvo com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar: $e')),
      );
    }
  }

  Future<void> _autoLoadIfNeeded(bc.BudgetController ctrl) async {
    if (_didAutoLoad) return;
    _didAutoLoad = true;

    final store = context.read<BudgetStore>();
    setState(() => _isLoading = true);
    try {
      final id = widget.contractData.id!;
      await store.ensureFor(id);
      final snap = store.cacheFor(id);
      if (!mounted) return;

      if (snap != null && !snap.isEmpty) {
        ctrl.loadFromSnapshot(
          table: snap.tableData,
          colTypesAsString: snap.colTypes,
          widths: snap.colWidths,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------- Edição inline --------
  void _startEdit(int r, int c, bc.BudgetController ctrl) {
    _editRow = r;
    _editCol = c;
    final cell = (c < ctrl.tableData[r].length) ? ctrl.tableData[r][c] : '';
    _cellController.text = cell;
    setState(() {});
    Future.delayed(Duration.zero, () => _cellFocus.requestFocus());
  }

  void _commitEdit() {
    final ctrl = context.read<bc.BudgetController>();
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

  bool _isUpperCase(String v) {
    final only = v.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    return only.isNotEmpty && only == only.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<bc.BudgetController>(
      create: (_) => bc.BudgetController(cellPadHorizontal: _cellPad.horizontal),
      builder: (context, _) {
        final ctrl = context.watch<bc.BudgetController>();

        // Auto-load assim que tivermos um BuildContext sob o Provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _autoLoadIfNeeded(ctrl);
        });

        // Ajusta âncoras A..Z conforme dataset
        if (ctrl.hasData && _headerKeysAZ.length != ctrl.colCount) {
          _headerKeysAZ = List<GlobalKey>.generate(ctrl.colCount, (_) => GlobalKey());
        }

        return Scaffold(
          body: Stack(
            children: [
              const BackgroundClean(),
              Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : !ctrl.hasData
                        ? const Center(child: Text('Cole dados do Excel aqui (Ctrl+V ou botão flutuante).'))
                        : Column(
                      children: [
                        // TOPO: canto + gap + cabeçalho A..Z
                        Row(
                          children: [
                            Container(
                              width: _gutterWidth,
                              height: _headerHeight,
                              color: Colors.grey.shade100,
                            ),
                            const SizedBox(width: _gap),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _hHeaderCtrl,
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(ctrl.colCount, (c) {
                                    final w = (c < ctrl.colWidths.length) ? ctrl.colWidths[c] : 120.0;
                                    final keyAZ = _headerKeysAZ[c];
                                    final hasType = (c < ctrl.colTypes.length) &&
                                        ctrl.colTypes[c] != bc.ColumnType.auto;

                                    return Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // célula A..Z
                                        Container(
                                          key: keyAZ,
                                          width: w,
                                          height: _headerHeight,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            border: Border(
                                              right: BorderSide(color: Colors.grey.shade300, width: 1),
                                            ),
                                          ),
                                          child: Text(
                                            ctrl.excelColName(c),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),

                                        // selo de tipo
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: InkWell(
                                            onTap: () async {
                                              final ctx = keyAZ.currentContext;
                                              if (ctx == null) return;
                                              final box = ctx.findRenderObject() as RenderBox;
                                              final overlay =
                                              Overlay.of(context).context.findRenderObject() as RenderBox;

                                              final selected = await showMenu<bc.ColumnType>(
                                                color: Colors.white,
                                                context: context,
                                                position: RelativeRect.fromRect(
                                                  box.localToGlobal(Offset.zero) & box.size,
                                                  Offset.zero & overlay.size,
                                                ),
                                                items: const [
                                                  PopupMenuItem(value: bc.ColumnType.text,     child: Text('Texto')),
                                                  PopupMenuItem(value: bc.ColumnType.number,   child: Text('Número')),
                                                  PopupMenuItem(value: bc.ColumnType.money,    child: Text('Monetário (R\$)')),
                                                  PopupMenuItem(value: bc.ColumnType.boolean_, child: Text('Booleano')),
                                                  PopupMenuItem(value: bc.ColumnType.date,     child: Text('Data (DD/MM/YYYY)')),
                                                  PopupMenuDivider(),
                                                  PopupMenuItem(value: bc.ColumnType.auto,     child: Text('Detectar automaticamente')),
                                                ],
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              );

                                              if (selected != null) {
                                                ctrl.setColumnType(c, selected);
                                              }
                                            },
                                            child: Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: hasType ? Colors.blueAccent.shade100 : Colors.white,
                                                borderRadius: BorderRadius.circular(3),
                                                border: Border.all(color: Colors.grey.shade400, width: 1),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                ctrl.typeBadge(ctrl.colTypes[c]),
                                                style: TextStyle(
                                                  color: hasType ? Colors.white : Colors.black,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // handle de resize + auto-fit
                                        Positioned(
                                          right: -_resizeHandleWidth / 2,
                                          top: 0,
                                          bottom: 0,
                                          width: _resizeHandleWidth,
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.resizeColumn,
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.translucent,
                                              onHorizontalDragUpdate: (details) {
                                                final numeric = ctrl.isNumericEffective(c);
                                                final maxW = numeric
                                                    ? double.infinity
                                                    : bc.BudgetController.maxColWidthNonNumeric;
                                                final next = (ctrl.colWidths[c] + details.delta.dx)
                                                    .clamp(bc.BudgetController.minColWidth, maxW);
                                                ctrl.colWidths[c] = next.toDouble();
                                                ctrl.notifyListeners();
                                              },
                                              onDoubleTap: () {
                                                ctrl.colWidths[c] = ctrl.autoFitColWidth(c);
                                                ctrl.notifyListeners();
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: _gap),

                        // CORPO: gutter 1..N + gap + grade
                        Expanded(
                          child: Row(
                            children: [
                              // Gutter de linhas
                              SizedBox(
                                width: _gutterWidth,
                                child: SingleChildScrollView(
                                  controller: _vGutterCtrl,
                                  child: Column(
                                    children: List.generate(ctrl.rowCount, (r) {
                                      final isEditingRow = (_editRow != null && _editRow == r);
                                      return Container(
                                        height: _rowHeight,
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: isEditingRow && r != 0
                                              ? Colors.yellow.shade100
                                              : (r == 0 ? Colors.grey.shade200 : Colors.grey.shade50),
                                          border: Border(
                                            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                                          ),
                                        ),
                                        child: Text(
                                          '${r + 1}',
                                          style: TextStyle(
                                            fontWeight: r == 0 ? FontWeight.w700 : FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: _gap),

                              // Grade principal
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _vGridCtrl,
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    controller: _hGridCtrl,
                                    scrollDirection: Axis.horizontal,
                                    child: Column(
                                      children: List.generate(ctrl.rowCount, (r) {
                                        final isFirstRow = r == 0;
                                        final firstCol = ctrl.tableData[r].isNotEmpty ? ctrl.tableData[r][0] : '';
                                        final secondCol = ctrl.tableData[r].length > 1 ? ctrl.tableData[r][1] : '';
                                        final isIntegerRow = !isFirstRow && int.tryParse(firstCol) != null;
                                        final isUpperCaseRow = !isFirstRow && _isUpperCase(secondCol);

                                        final isEditingRow = (_editRow != null && _editRow == r);

                                        final baseBg = isFirstRow
                                            ? const Color(0xFF091D68)
                                            : isIntegerRow
                                            ? Colors.grey.shade200
                                            : isUpperCaseRow
                                            ? Colors.grey.shade100
                                            : Colors.white;

                                        final bg = (!isFirstRow && isEditingRow) ? Colors.yellow.shade100 : baseBg;

                                        final baseText = isFirstRow
                                            ? const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                                            : isIntegerRow
                                            ? const TextStyle(fontWeight: FontWeight.bold)
                                            : isUpperCaseRow
                                            ? const TextStyle(fontStyle: FontStyle.italic)
                                            : const TextStyle();

                                        return Row(
                                          children: List.generate(ctrl.colCount, (c) {
                                            final cell = (c < ctrl.tableData[r].length) ? ctrl.tableData[r][c] : '';
                                            final w = (c < ctrl.colWidths.length) ? ctrl.colWidths[c] : 120.0;
                                            final isHeaderCell = isFirstRow;
                                            final isNumericCol = ctrl.isNumericEffective(c);
                                            final isEditing = (_editRow == r && _editCol == c);

                                            Widget content;
                                            if (isEditing) {
                                              content = TextField(
                                                controller: _cellController,
                                                focusNode: _cellFocus,
                                                autofocus: true,
                                                decoration: const InputDecoration(
                                                  isCollapsed: true,
                                                  border: InputBorder.none,
                                                  contentPadding: EdgeInsets.zero,
                                                ),
                                                textAlign: isHeaderCell
                                                    ? TextAlign.center
                                                    : (isNumericCol ? TextAlign.right : TextAlign.left),
                                                maxLines: 1,
                                                keyboardType: isNumericCol
                                                    ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                                                    : TextInputType.text,
                                                inputFormatters: isNumericCol
                                                    ? <TextInputFormatter>[
                                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\,\-\sRr\$]')),
                                                ]
                                                    : null,
                                                onSubmitted: (_) => _commitEdit(),
                                                onTapOutside: (_) => _commitEdit(),
                                                style: baseText,
                                              );
                                            } else {
                                              content = Text(
                                                cell,
                                                textAlign: isHeaderCell
                                                    ? TextAlign.center
                                                    : (isNumericCol ? TextAlign.right : TextAlign.left),
                                                style: baseText,
                                              );
                                            }

                                            return GestureDetector(
                                              onDoubleTap: () => _startEdit(r, c, ctrl),
                                              child: Container(
                                                width: w,
                                                height: _rowHeight,
                                                alignment: isHeaderCell ? Alignment.center : Alignment.centerLeft,
                                                padding: _cellPad,
                                                decoration: BoxDecoration(
                                                  color: bg,
                                                  border: Border(
                                                    right: BorderSide(color: Colors.grey.shade300, width: 1),
                                                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                                                  ),
                                                ),
                                                child: content,
                                              ),
                                            );
                                          }),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const FootBar()
                ],
              ),

              // TOPO DIREITO: colar / salvar
              Positioned(
                top: 72,
                right: 16,
                child: Consumer<bc.BudgetController>(
                  builder: (_, ctrl, __) {
                    return Column(
                      children: [
                        FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          heroTag: 'pasteExcel',
                          tooltip: 'Colar do Excel (Ctrl+V)',
                          onPressed: () => ctrl.pasteFromClipboard(),
                          child: const Icon(Icons.paste),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton.small(
                          backgroundColor: Colors.white,
                          heroTag: 'saveBudget',
                          tooltip: 'Salvar orçamento no Firestore',
                          onPressed: () => _onSaveBudget(ctrl),
                          child: const Icon(Icons.save),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
