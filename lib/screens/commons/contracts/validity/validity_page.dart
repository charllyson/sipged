import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import 'package:sisgeo/_widgets/input/drop_down_botton_change.dart';
import 'package:sisgeo/_widgets/loading/loading_progress.dart';
import 'package:sisgeo/_widgets/timeline/timeline_class.dart';

import '../../../../_blocs/user/user_bloc.dart';
import '../../../../_class/archives/pdf/pdf_icon_action.dart';
import '../../../../_datas/user/user_data.dart';
import '../../../../_provider/user/user_provider.dart';
import '../../../../_utils/date_utils.dart';
import '../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/buttons/deleteButtonPermission.dart';
import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/mask_class.dart';
import '../../../../_widgets/validates/form_validation_mixin.dart';

class ValidityPage extends StatefulWidget {
  const ValidityPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ValidityPage> createState() => _ValidityPageState();
}

class _ValidityPageState extends State<ValidityPage> with FormValidationMixin {
  late ContractsBloc _contractsBloc;
  late UserBloc _userBloc;
  late UserData _currentUser;
  late Future<List<ValidityData>> _futureValidity;

  final _orderCtrl = TextEditingController();
  final _orderTypeCtrl = TextEditingController();
  final _orderDateCtrl = TextEditingController();

  String? _currentValidityId;
  bool _isSaving = false;
  bool _formValidated = false;
  bool _isEditable = false;

  final List<String> _typeOfOrder = [
    'ORDEM DE INÍCIO',
    'ORDEM DE PARALIZAÇÃO',
    'ORDEM DE REINÍCIO',
    'ORDEM DE FINALIZAÇÃO',
  ];

  ValidityData? _selectedValidity;


  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    _userBloc = UserBloc();
    setupValidation([
      _orderTypeCtrl,
      _orderDateCtrl]
        , _validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).userData;
      if (user != null) {
        _currentUser = user;
        _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
      }
      setState(() {});
    });
    if (widget.contractData?.id != null) {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.id!,
      ).then((list) {
        if (list.isNotEmpty) {
          final lastOrder = list.map((e) => e.orderNumber ?? 0).reduce((a, b) => a > b ? a : b);
          _orderCtrl.text = (lastOrder + 1).toString();
        } else {
          _orderCtrl.text = '1';
        }
        return list;
      });
    } else {
      _futureValidity = Future.value([]);
      _orderCtrl.text = '1';
    }
  }

  bool isDisabled(String module) {
    final perms = _currentUser.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  Future<void> _refreshValidityList() async {
    setState(() {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.id!,
      );
    });
  }

  void _validateForm() {
    final valid = areFieldsFilled([_orderTypeCtrl, _orderDateCtrl], minLength: 5) && _orderDateCtrl.text.length == 10;
    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }

  void _fillFields(ValidityData data) {
    setState(() {
      _currentValidityId = data.id;
      _orderTypeCtrl.text = data.ordertype ?? '';
      _orderCtrl.text = data.orderNumber.toString();
      final type = data.ordertype ?? '';
      if (_typeOfOrder.contains(type)) {
        _orderTypeCtrl.text = type;
      } else {
        _orderTypeCtrl.clear();
      }

      _orderDateCtrl.text = convertDateTimeToDDMMYYYY(data.orderdate!);
    });
  }

  void _saveOrUpdateValidity() async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja realmente salvar ou atualizar esta ordem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    final newValidity = ValidityData(
      id: _currentValidityId,
      uidContract: widget.contractData!.id,
      orderNumber: int.tryParse(_orderCtrl.text),
      ordertype: _orderTypeCtrl.text,
      orderdate: convertDDMMYYYYToDateTime(_orderDateCtrl.text),
    );

    await _contractsBloc.salvarOuAtualizarValidade(newValidity);

    setState(() {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.id!,
      ).then((list) {
        if (_currentValidityId == null && list.isNotEmpty) {
          final lastOrder = list.map((e) => e.orderNumber ?? 0).reduce((a, b) => a > b ? a : b);
          _orderCtrl.text = (lastOrder + 1).toString();
        }
        return list;
      });
      _currentValidityId = null;
      _orderTypeCtrl.clear();
      _orderDateCtrl.clear();
      _isSaving = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ordem salva com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _deleteValidity(String validityId) async {
    if (widget.contractData?.id == null) return;
    await _contractsBloc.deletarValidade(widget.contractData!.id!, validityId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ordem apagada com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    await _refreshValidityList();
  }

  void _createNewOrder() async {
    if (widget.contractData?.id == null) return;

    final list = await _contractsBloc.getAllValidityOfContract(
      uidContract: widget.contractData!.id!,
    );
    final lastOder = list.map((e) => e.orderNumber ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _currentValidityId = null;
      _orderCtrl.text = (lastOder + 1).toString();
      _orderTypeCtrl.clear();
      _orderDateCtrl.clear();
    });
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
                TimelineClass(
                  futureValidity: _futureValidity,
                  futureContractList: Future.value([widget.contractData!]),
                  futureAdditiveList: _contractsBloc.getAllAdditivesOfContract(uidContract: widget.contractData!.id!),
                ),                SizedBox(height: 12),
                _buildFieldsForm(),
                FutureBuilder<List<ValidityData>>(
                  future: _futureValidity,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const LoadingProgress();
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
                    } else if (!snapshot.hasData || (snapshot.data is Iterable && (snapshot.data as Iterable).isEmpty)) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Nenhuma ordem encontrada'),
                      );
                    }
                    final list = snapshot.data ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Ordens cadastradas no sistema', style: TextStyle(fontSize: 20)),
                        ),
                        _buildTable(list),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildFieldsForm() {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: 6),
            if (_currentValidityId != null)
              PdfFileIconActionGeneric(
                key: Key(_currentValidityId!),
                tipo: TipoArquivoPDF.aditivo,
                bloc: _contractsBloc,
                contrato: widget.contractData!,
                dataEspecifica: _selectedValidity, // do tipo AdditiveData
                onUploadSaveToFirestore: (url) async {
                  await _contractsBloc.salvarUrlPdfDoAditivo(
                    contractId: widget.contractData!.id!,
                    additiveId: _selectedValidity!.id!,
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
                      width: responsiveInputsThreePerLineWithPDF(context),
                      child: Tooltip(
                        message: 'Este campo é calculado automaticamente e não pode ser editado.',
                        child: CustomTextField(
                          labelText: 'Ordem',
                          controller: _orderCtrl,
                          enabled: false,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: responsiveInputsThreePerLineWithPDF(context),
                        child: DropDownButtonChange(
                          enabled: _isEditable,
                          labelText: 'Tipo da ordem',
                          items: _typeOfOrder,
                          controller: _orderTypeCtrl,
                        ),
                    ),
                    SizedBox(
                      width: responsiveInputsThreePerLineWithPDF(context),
                      child: CustomTextField(
                        enabled: _isEditable,
                        labelText: 'Data da ordem',
                        controller: _orderDateCtrl,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          TextInputMask(mask: '99/99/9999'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_currentValidityId != null)
                      Tooltip(
                        message: 'Limpar formulário',
                        child: TextButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Limpar'),
                          onPressed: _createNewOrder,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Tooltip(
                      message: _formValidated ? 'Salvar ordem' : 'Preencha os campos obrigatórios',
                      child: TextButton.icon(
                        onPressed: _formValidated && !_isSaving ? _saveOrUpdateValidity : null,
                        icon: Icon(Icons.save),
                        label: Text(_currentValidityId != null ? 'Atualizar' : 'Salvar'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<ValidityData> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Table(
              border: TableBorder.all(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade300,
              ),
              columnWidths: const {
                0: FixedColumnWidth(80),
                1: FixedColumnWidth(150),
                2: FixedColumnWidth(100),
                3: FixedColumnWidth(80),
              },
              children: [
                _buildHeaderRow(),
                ...list.map((data) => _buildDataRow(data)),
              ],
            ),
          ),
        );
      },
    );
  }
  
  TableRow _buildHeaderRow() {
    const headers = ['ORDEM', 'TIPO DA ORDEM', 'DATA DA ORDEM', 'APAGAR'];
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

  TableRow _buildDataRow(ValidityData data) {
    final currentUser = Provider.of<UserProvider>(context).userData;
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildCell(data.orderNumber.toString(), () => _fillFields(data), Alignment.center),
        _buildCell(data.ordertype ?? '', () => _fillFields(data), Alignment.bottomLeft),
        _buildCell(convertDateTimeToDDMMYYYY(data.orderdate!), () => _fillFields(data), Alignment.center),
        TableCell(
          child: Stack(
            children: [
              if (currentUser == null)
                const Center(child: CircularProgressIndicator())
              else
              PermissionIconDeleteButton(
                tooltip: 'Apagar ordem?',
                currentUser: currentUser,
                showConfirmDialog: true,
                confirmTitle: 'Confirmar exclusão',
                confirmContent: 'Deseja apagar esta ordem?',
                hasPermission: (user) => _contractsBloc.knowUserPermissionProfileAdm(
                  userData: user,
                  contract: widget.contractData!,
                ),
                onConfirmed: () async {
                  if (widget.contractData!.id != null) {
                    _deleteValidity(data.id!);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCell(String? text, VoidCallback onTap, Alignment alignment) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: onTap,
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              text ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    removeValidation([_orderTypeCtrl, _orderDateCtrl], _validateForm);
    _orderCtrl.dispose();
    _orderTypeCtrl.dispose();
    _orderDateCtrl.dispose();
    super.dispose();
  }
}
