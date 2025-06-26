import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import '../../../../_blocs/contracts/contracts_bloc.dart';
import '../../../../_blocs/user/user_bloc.dart';
import '../../../../_class/archives/pdf/pdf_icon_action.dart';
import '../../../../_datas/apostilles/apostilles_data.dart';
import '../../../../_datas/contracts/contracts_data.dart';
import '../../../../_datas/user/user_data.dart';
import '../../../../_provider/user/user_provider.dart';
import '../../../../_utils/date_utils.dart';
import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/buttons/deleteButtonPermission.dart';
import '../../../../_widgets/charts/bar_chart_sample.dart';
import '../../../../_widgets/charts/pie_chart_sample.dart';
import '../../../../_widgets/formats/input_formatters.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/mask_class.dart';
import '../../../../_widgets/validates/form_validation_mixin.dart';

class ApostillesPage extends StatefulWidget {
  const ApostillesPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ApostillesPage> createState() => _ApostillesPageState();
}

class _ApostillesPageState extends State<ApostillesPage> with FormValidationMixin  {
  late ContractsBloc _contractsBloc;
  late UserBloc _userBloc;
  late Future<List<ApostillesData>> _futureApostilles;
  int? _selectedLine;
  late UserData _currentUser;

  final _orderController = TextEditingController();
  final _dateController = TextEditingController();
  final _valueController = TextEditingController();
  final _processController = TextEditingController();
  String? _currentApostillesId;
  bool _editingMode = false;
  bool _formValidated = false;
  bool _isEditable = false;

  ApostillesData? _selectedApostille;

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    _isEditable = widget.contractData?.id != null;
    _userBloc = UserBloc();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).userData;
      if (user != null) {
        _currentUser = user;
        _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
      }
      setState(() {});
    });
    _loadApostilles();
    setupValidation([_dateController, _valueController, _processController], _validateForm);
    _orderController.text = '1';
  }

  bool isDisabled(String module) {
    final perms = _currentUser.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  void _deleteApostille(String uid) async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmação'),
            content: const Text('Deseja realmente apagar este apostilamento?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    await _contractsBloc.deletarApostille(widget.contractData!.id!, uid);

    setState(() => _loadApostilles());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apostilamento apagado com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _fillFields(ApostillesData data) {
    setState(() {
      _selectedApostille = data;
      _editingMode = true;
      _currentApostillesId = data.id;
      _orderController.text = data.apostilleOrder?.toString() ?? '';
      _dateController.text = convertDateTimeToDDMMYYYY(data.apostilleData);
      _valueController.text = priceToString(data.apostilleValue);
      _processController.text = data.apostilleNumberProcess ?? '';
    });
  }

  void _createNewApostilles() async {
    if (widget.contractData?.id == null) return;

    final list = await _contractsBloc.getAllApostillesOfContract(
      uidContract: widget.contractData!.id!,
    );
    final lastOrder = list
        .map((e) => e.apostilleOrder ?? 0)
        .fold(0, (a, b) => a > b ? a : b);

    setState(() {
      _editingMode = false;
      _currentApostillesId = null;
      _orderController.text = (lastOrder + 1).toString();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
    });
  }

  void _loadApostilles() {
    if (widget.contractData?.id != null) {
      _futureApostilles = _contractsBloc
          .getAllApostillesOfContract(uidContract: widget.contractData!.id!)
          .then((list) {
            if (!_editingMode) {
              final lastOrder = list
                  .map((e) => e.apostilleOrder ?? 0)
                  .fold(0, (a, b) => a > b ? a : b);
              _orderController.text = (lastOrder + 1).toString();
            }
            return list;
          });
    } else {
      _futureApostilles = Future.value([]);
    }
  }

  void _validateForm() {
    final valid =
        _dateController.text.isNotEmpty &&
        _valueController.text.isNotEmpty &&
        _processController.text.isNotEmpty;
    setState(() => _formValidated = valid);
  }

  Future<void> _saveOrUpdateApostilles() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmação'),
            content: Text(
              _editingMode
                  ? 'Deseja atualizar este apostilamento?'
                  : 'Deseja salvar um novo apostilamento?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final novo = ApostillesData(
      id: _currentApostillesId,
      apostilleNumberProcess: _processController.text,
      apostilleOrder: int.tryParse(_orderController.text),
      apostilleData: convertDDMMYYYYToDateTime(_dateController.text),
      apostilleValue: stringToDouble(_valueController.text),
    );

    await _contractsBloc.saveOrUpdateApostille(novo, widget.contractData!.id!);

    setState(() {
      _loadApostilles();
      _currentApostillesId = null;
      _editingMode = false;
      _orderController.clear();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _editingMode
              ? 'Apostilamento atualizado com sucesso!'
              : 'Apostilamento salvo com sucesso!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildFormCampos(),
            FutureBuilder<List<ApostillesData>>(
              future: _futureApostilles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erro: \${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Nenhum apostilamento encontrado'));
                }
                final apostilles = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12),
                    const Text(
                      'Gráfico dos apostilamentos cadastradas no sistema',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double larguraDisponivel = constraints.maxWidth;
                        const double larguraGraficoPizza = 300;
                        const double espacamento = 100;

                        final double larguraGraficoBarra = math.max(
                          larguraDisponivel - larguraGraficoPizza - espacamento,
                          300,
                        );

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              PieChartSample(
                                apostilles: apostilles,
                                selectedIndex: _selectedLine,
                                larguraGrafico: larguraGraficoPizza,
                                onTouch: (index) {
                                  setState(() {
                                    _selectedLine = index;
                                    if (index != null &&
                                        index >= 0 &&
                                        index < apostilles.length) {
                                      _fillFields(apostilles[index]);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              BarChartSample(
                                apostilles: apostilles,
                                selectedIndex: _selectedLine,
                                larguraGrafico: larguraGraficoBarra,
                                onBarTap: (index) {
                                  setState(() {
                                    _selectedLine = index;
                                    if (index >= 0 && index < apostilles.length) {
                                      _fillFields(apostilles[index]);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Apostilamentos cadastrados no sistema',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    _buildTable(apostilles),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCampos() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 6),
            if (_currentApostillesId != null)
              PdfFileIconActionGeneric(
                key: Key(_currentApostillesId!),
                tipo: TipoArquivoPDF.apostila,
                bloc: _contractsBloc,
                contrato: widget.contractData!,
                dataEspecifica: _selectedApostille, // do tipo ApostillesData
                onUploadSaveToFirestore: (url) async {
                  await _contractsBloc.salvarUrlPdfDaApostila(
                    contractId: widget.contractData!.id!,
                    apostilleId: _selectedApostille!.id!,
                    url: url,
                  );
                },
              ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: responsiveInputsFourPerLineWithPDF(context),
                      child: Tooltip(
                        message: 'Este campo é gerado automaticamente.',
                        child: CustomTextField(
                          labelText: 'Ordem do apostilamento',
                          controller: _orderController,
                          enabled: false,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: responsiveInputsFourPerLineWithPDF(context),
                      child: CustomTextField(
                        enabled: _isEditable,
                        labelText: 'Nº do processo',
                        controller: _processController,
                        inputFormatters: [processoMaskFormatter],
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: responsiveInputsFourPerLineWithPDF(context),
                      child: CustomTextField(
                        enabled: _isEditable,
                        labelText: 'Valor do apostilamento',
                        controller: _valueController,
                        inputFormatters: [
                          CurrencyInputFormatter(
                            leadingSymbol: 'R\$',
                            useSymbolPadding: true,
                            thousandSeparator: ThousandSeparator.Period,
                            mantissaLength: 2,
                          ),
                        ],
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    SizedBox(
                      width: responsiveInputsFourPerLineWithPDF(context),
                      child: CustomTextField(
                        enabled: _isEditable,
                        labelText: 'Data do apostilamento',
                        controller: _dateController,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputMask(mask: '99/99/9999'),
                        ],
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed:
                          _formValidated
                              ? _isEditable
                                  ? _saveOrUpdateApostilles
                                  : null
                              : null,
                      icon: Icon(Icons.save),
                      label: Text(_editingMode ? 'Atualizar' : 'Salvar'),
                    ),
                    const SizedBox(width: 12),
                    if (_editingMode)
                      TextButton.icon(
                        icon: const Icon(Icons.update),
                        label: const Text('Limpar'),
                        onPressed: _createNewApostilles,
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<ApostillesData> apostilles) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(80),
                1: FixedColumnWidth(200),
                2: FixedColumnWidth(140),
                3: FixedColumnWidth(120),
                4: FixedColumnWidth(80),
              },
              children: [
                _buildHeaderRow(),
                ...apostilles.map((data) => _buildDataRow(data, apostilles)),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildHeaderRow() {
    const headers = ['ORDEM', 'Nº PROCESSO', 'VALOR', 'DATA', 'APAGAR'];
    return TableRow(
      decoration: const BoxDecoration(color: Color.fromRGBO(0, 200, 255, 0.3)),
      children:
          headers.map((title) {
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
    );
  }

  TableRow _buildDataRow(ApostillesData data, List<ApostillesData> apostilles) {
    final index = apostilles.indexOf(data);
    final isSelected = index == _selectedLine;
    final currentUser = Provider.of<UserProvider>(context).userData;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
      ),
      children: [
        _buildEditableCell(data.apostilleOrder.toString(), () {
          setState(() {
            _selectedLine = index;
            _fillFields(data);
          });
        }),
        _buildEditableCell(data.apostilleNumberProcess ?? '', () {
          setState(() {
            _selectedLine = index;
            _fillFields(data);
          });
        }),
        _buildEditableCell(priceToString(data.apostilleValue), () {
          setState(() {
            _selectedLine = index;
            _fillFields(data);
          });
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.apostilleData!), () {
          setState(() {
            _selectedLine = index;
            _fillFields(data);
          });
        }),
        TableCell(
          child: Stack(
            children: [
              if (currentUser == null)
                const Center(child: CircularProgressIndicator())
              else
                PermissionIconDeleteButton(
                  tooltip: 'Apagar apostilamento?',
                  currentUser: currentUser,
                  showConfirmDialog: true,
                  confirmTitle: 'Confirmar exclusão',
                  confirmContent: 'Deseja apagar este apostilamento?',
                  hasPermission:
                      (user) => _contractsBloc.knowUserPermissionProfileAdm(
                        userData: user,
                        contract: widget.contractData!,
                      ),
                  onConfirmed: () async {
                    if (widget.contractData!.id != null) {
                      _deleteApostille(data.id!);
                    }
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableCell(String? text, VoidCallback onTap) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            text ?? '',
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    removeValidation([_dateController, _valueController, _processController], _validateForm);
    _orderController.dispose();
    _dateController.dispose();
    _valueController.dispose();
    _processController.dispose();
    super.dispose();
  }
}
