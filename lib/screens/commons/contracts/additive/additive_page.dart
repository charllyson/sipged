import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/additive/additive_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';

import '../../../../_blocs/user/user_bloc.dart';
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
import '../../../../_widgets/input/drop_down_botton_change.dart';
import '../../../../_widgets/mask_class.dart';
import '../../../../_widgets/validates/form_validation_mixin.dart';

class AdditivePage extends StatefulWidget {
  const AdditivePage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<AdditivePage> createState() => _AdditivePageState();
}

class _AdditivePageState extends State<AdditivePage> with FormValidationMixin{
  late ContractsBloc _contractsBloc;
  late UserBloc _userBloc;
  late UserData _currentUser;
  late Future<List<AdditiveData>> _futureAdditives;
  bool _isSaving = false;
  int? _selectedLine;

  final _orderController = TextEditingController();
  final _dateController = TextEditingController();
  final _valueController = TextEditingController();
  final _processController = TextEditingController();
  final _validityContractController = TextEditingController();
  final _typeOfAdditiveCtrl = TextEditingController();

  String? _currentAdditiveId;
  bool _editingMode = false;
  bool _formValidated = false;
  bool _isEditable = false;

  final AdditiveData additiveData = AdditiveData();

  final List<String> _typeOfAdditive = [
    'VALOR',
    'PRAZO',
    'REEQUILÍBRIO'
  ];

  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    _userBloc = UserBloc();
    _futureAdditives = widget.contractData?.id != null
        ? _contractsBloc.getAllAdditivesOfContract(uidContract: widget.contractData!.id!)
        : Future.value([]);
    _setNextOrder();
    setupValidation([
      _dateController,
      _valueController,
      _processController,
      _validityContractController,
    ], _validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).userData;
      if (user != null) {
        _currentUser = user;
        _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
      }
      setState(() {});
    });
  }

  bool isDisabled(String module) {
    final perms = _currentUser.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  void _validateForm() {
    final valid = areFieldsFilled([
      _dateController,
      _valueController,
      _processController,
      _validityContractController,
    ], minLength: 5);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }

  void _fillFields(AdditiveData data) {
    setState(() {
      _editingMode = true;
      _currentAdditiveId = data.id;
      _typeOfAdditiveCtrl.text = data.typeOfAdditive ?? '';
      _orderController.text = data.additiveorder?.toString() ?? '';
      _dateController.text = data.additivedata != null ? convertDateTimeToDDMMYYYY(data.additivedata!) : '';
      _valueController.text = priceToString(data.additivevalue);
      _processController.text = data.additivenumberprocess ?? '';
      _validityContractController.text = data.additivevaliditycontractdata != null
          ? convertDateTimeToDDMMYYYY(data.additivevaliditycontractdata!)
          : '';
    });
  }

  Future<void> _setNextOrder() async {
    if (widget.contractData?.id == null) return;

    final list = await _contractsBloc.getAllAdditivesOfContract(
      uidContract: widget.contractData!.id!,
    );

    final lastOrder = list.map((e) => e.additiveorder ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _orderController.text = (lastOrder + 1).toString();
    });
  }

  void _createNewAdditive() async {
    if (widget.contractData?.id == null) return;

    final list = await _contractsBloc.getAllAdditivesOfContract(
      uidContract: widget.contractData!.id!,
    );

    final lastOrder = list.map((e) => e.additiveorder ?? 0).fold(0, (a, b) => a > b ? a : b);

    setState(() {
      _editingMode = false;
      _currentAdditiveId = null;
      _orderController.text = (lastOrder + 1).toString();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
      _validityContractController.clear();
      _typeOfAdditiveCtrl.clear();
    });
  }

  Future<void> _saveOrUpdateAdditive() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: Text(_editingMode
            ? 'Deseja atualizar este aditivo?'
            : 'Deseja salvar um novo aditivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isSaving = true);
    final novo = AdditiveData(
      id: _currentAdditiveId,
      additivenumberprocess: _processController.text,
      additiveorder: int.tryParse(_orderController.text),
      additivevaliditycontractdata: convertDDMMYYYYToDateTime(_validityContractController.text),
      additivedata: convertDDMMYYYYToDateTime(_dateController.text),
      additivevalue: stringToDouble(_valueController.text),
      typeOfAdditive: _typeOfAdditiveCtrl.text,
    );

    await _contractsBloc.salvarOuAtualizarAditivo(novo, widget.contractData!.id!);

    setState(() {
      _futureAdditives = _contractsBloc.getAllAdditivesOfContract(
        uidContract: widget.contractData!.id!,
      );
      _currentAdditiveId = null;
      _editingMode = false;
      _orderController.clear();
      _dateController.clear();
      _valueController.clear();
      _processController.clear();
      _validityContractController.clear();
      _typeOfAdditiveCtrl.clear();
      _isSaving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editingMode ? 'Aditivo atualizado com sucesso!' : 'Aditivo salvo com sucesso!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _deleteAdditive(String uidAditivo) async {
    if (widget.contractData?.id == null) return;
    await _contractsBloc.deleteAdditive(widget.contractData!.id!, uidAditivo);
    setState(() {
      _futureAdditives = _contractsBloc.getAllAdditivesOfContract(
        uidContract: widget.contractData!.id!,
      );
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aditivo deletado com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                _buildFormCampos(),
                FutureBuilder<List<AdditiveData>>(
                  future: _futureAdditives,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erro: ${snapshot.error}'));
                    }else if(!snapshot.hasData || snapshot.data!.isEmpty){
                      return Center(child: Text('Nenhum aditivo encontrado'));
                    }
                    final additives = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12),
                        const Text('Gráfico dos aditivos', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final double larguraDisponivel = constraints.maxWidth;
                            const double larguraGraficoPizza = 300;
                            const double espacamento = 100;

                            final double larguraGraficoBarras = math.max(
                              larguraDisponivel - larguraGraficoPizza - espacamento,
                              300, // largura mínima segura
                            );
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  PieChartSample(
                                    additives: additives,
                                    selectedIndex: _selectedLine,
                                    larguraGrafico: larguraGraficoPizza,
                                    onTouch: (index) {
                                      setState(() {
                                        _selectedLine = index;
                                        if (index != null && index >= 0 && index < additives.length) {
                                          _fillFields(additives[index]);
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  BarChartSample(
                                    additives: additives,
                                    selectedIndex: _selectedLine,
                                    larguraGrafico: larguraGraficoBarras,
                                    onBarTap: (index) {
                                      setState(() {
                                        _selectedLine = index;
                                        if (index >= 0 && index < additives.length) {
                                          _fillFields(additives[index]);
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
                        const Text('Aditivos cadastrados no sistema', style: TextStyle(fontSize: 20)),
                        const SizedBox(height: 12),
                        _buildTable(additives),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (_isSaving)
          Stack(
            children: [
              ModalBarrier(dismissible: false, color: Colors.black.withOpacity(0.4)),
              const Center(child: CircularProgressIndicator()),
            ],
          ),
      ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: responsiveInputsThreePerLine(context),
                  child: Tooltip(
                    message: 'Este campo é calculado automaticamente e não pode ser editado.',
                    child: CustomTextField(
                      labelText: 'Ordem do aditivo',
                      controller: _orderController,
                      enabled: false,
                    ),
                  ),
                ),
                SizedBox(
                    width: responsiveInputsThreePerLine(context),
                    child: CustomTextField(
                      enabled: _isEditable,
                      labelText: 'Data do aditivo',
                      controller: _dateController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputMask(mask: '99/99/9999'),
                      ],
                      keyboardType: TextInputType.datetime,
                    )),
                SizedBox(
                    width: responsiveInputsThreePerLine(context),
                    child: CustomTextField(
                      enabled: _isEditable,
                      labelText: 'Data da vigência do aditivo',
                      controller: _validityContractController,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputMask(mask: '99/99/9999'),
                      ],
                      keyboardType: TextInputType.datetime,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                      width: responsiveInputsThreePerLine(context),
                      child: CustomTextField(
                        enabled: _isEditable,
                        labelText: 'Processo do Aditivo',
                        controller: _processController,
                        inputFormatters: [processoMaskFormatter],
                        keyboardType: TextInputType.number,
                      )),
                  SizedBox(
                      width: responsiveInputsThreePerLine(context),
                      child: CustomTextField(
                        enabled: _isEditable,
                        labelText: 'Valor do aditivo',
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
                      )),
                  SizedBox(
                    width: responsiveInputsThreePerLine(context),
                    child: DropDownButtonChange(
                      enabled: _isEditable,
                      labelText: 'Tipo de Aditivo',
                      items: _typeOfAdditive,
                      controller: _typeOfAdditiveCtrl,
                      onChanged: (value) => additiveData.typeOfAdditive = value ?? '',
                    ),
                  ),
                ]
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _formValidated ? _isEditable ? _saveOrUpdateAdditive : null : null,
                  icon: Icon(Icons.save),
                  label: Text(_editingMode ? 'Atualizar' : 'Salvar'),
                ),
                const SizedBox(width: 12),
                if (_editingMode)
                  TextButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Limpar campos'),
                    onPressed: _createNewAdditive,
                  ),
              ],
            )

          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<AdditiveData> additives) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              columnWidths: const {
                0: FixedColumnWidth(70),
                1: FixedColumnWidth(200),
                2: FixedColumnWidth(140),
                3: FixedColumnWidth(120),
                4: FixedColumnWidth(120),
                5: FixedColumnWidth(120),
                6: FixedColumnWidth(120),
                7: FixedColumnWidth(80),
              },
              children: [
                _buildHeaderRow(),
                ...additives.map((data) => _buildDataRow(data, additives)),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildHeaderRow() {
    const headers = [
      'ORDEM',
      'Nº PROCESSO',
      'VALOR DO ADITIVO',
      'VIGÊNCIA INICIAL',
      'VIGÊNCIA PÓS ADITIVO',
      'DIAS DO ADITIVO',
      'DIAS DE VALIDADE',
      'APAGAR',
    ];
    return TableRow(
      decoration: const BoxDecoration(color: Color.fromRGBO(0, 200, 255, 0.3)),
      children: headers.map((title) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
              textAlign: TextAlign.center,
              title, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(AdditiveData data, List<AdditiveData> additives) {
    final index = additives.indexOf(data);
    final isSelected = index == _selectedLine;
    final currentUser = Provider.of<UserProvider>(context).userData;
    return TableRow(
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.shade50 : Colors.white,
      ),
      children: [
        _buildEditableCell(data.additiveorder.toString(), (){
          _selectedLine = index;
          _fillFields(data);
        }),
        _buildEditableCell(data.additivenumberprocess ?? '', (){
          _selectedLine = index;
          _fillFields(data);
        }),
        _buildEditableCell(priceToString(data.additivevalue), (){
          _selectedLine = index;
          _fillFields(data);
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivedata), (){
          _selectedLine = index;
          _fillFields(data);
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivevaliditycontractdata), (){
          _selectedLine = index;
          _fillFields(data);
        }),
        _buildEditableCell(convertDateTimeToDDMMYYYY(data.additivevalidityexecutiondata), (){
          _selectedLine = index;
          _fillFields(data);
        }),
        _buildEditableCell(data.additivevalidityexecutiondays.toString(), (){
          _selectedLine = index;
          _fillFields(data);
        }),
        TableCell(
          child: Stack(
            children: [
              if (currentUser == null)
                const Center(child: CircularProgressIndicator())
              else
                PermissionIconDeleteButton(
                  tooltip: 'Apagar aditivo?',
                  currentUser: currentUser,
                  showConfirmDialog: true,
                  confirmTitle: 'Confirmar exclusão',
                  confirmContent: 'Deseja apagar este aditivo?',
                  hasPermission: (user) => _contractsBloc.knowUserPermissionProfileAdm(
                    userData: user,
                    contract: widget.contractData!,
                  ),
                  onConfirmed: () async {
                    if (widget.contractData!.id != null) {
                      _deleteAdditive(data.id!);
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    removeValidation([
      _dateController,
      _valueController,
      _processController,
      _validityContractController,
    ], _validateForm);

    _orderController.dispose();
    _dateController.dispose();
    _valueController.dispose();
    _processController.dispose();
    _validityContractController.dispose();
    _typeOfAdditiveCtrl.dispose();
    super.dispose();
  }

}

