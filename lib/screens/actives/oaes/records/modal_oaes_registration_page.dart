import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:provider/provider.dart';
import 'package:sisged/_widgets/formats/format_field.dart';

import '../../../../_blocs/actives/oaes_bloc.dart';
import '../../../../_blocs/system/user_bloc.dart';
import '../../../../_datas/actives/oaes/oaesData.dart';
import '../../../../_datas/documents/contracts/additive/additive_data.dart';
import '../../../../_datas/documents/contracts/contracts/contracts_data.dart';
import '../../../../_datas/system/user_data.dart';
import '../../../../../_provider/user/user_provider.dart';
import '../../../../../_utils/date_utils.dart';
import '../../../../../_utils/responsive_utils.dart';
import '../../../../_widgets/charts/barGraph/bar_chart_changed.dart';
import '../../../../_widgets/charts/pieGraph/pie_chart_changed.dart';
import '../../../../../_widgets/input/custom_text_field.dart';
import '../../../../../_widgets/mask_class.dart';
import '../../../../../_widgets/texts/divider_text.dart';
import '../../../../../_widgets/validates/form_validation_mixin.dart';
import '../../../commons/footBar/foot_bar.dart';
import 'modal_oaes_registration_table_section.dart';

class ModalOaesRegistrationPage extends StatefulWidget {
  const ModalOaesRegistrationPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ModalOaesRegistrationPage> createState() => _ModalOaesRegistrationPageState();
}

class _ModalOaesRegistrationPageState extends State<ModalOaesRegistrationPage> with FormValidationMixin{
  late OaesBloc _oaesBloc;
  late UserBloc _userBloc;
  late UserData _currentUser;
  late Future<List<OaesData>> _futureOaes;
  bool _isSaving = false;
  int? _selectedLine;


  final _orderCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _roadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _extensionCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _structureCtrl = TextEditingController();
  final _contractsCtrl = TextEditingController();
  final _interventionValueCtrl = TextEditingController();
  final _linearCostCtrl = TextEditingController();
  final _estimateCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _altitudeCtrl = TextEditingController();

  String? _currentOaesId;
  bool _editingMode = false;
  bool _formValidated = false;
  bool _isEditable = false;

  final AdditiveData additiveData = AdditiveData();


  @override
  void initState() {
    super.initState();
    _oaesBloc = OaesBloc();
    _userBloc = UserBloc();
    _futureOaes = _oaesBloc.getAllOAEs();
    _setNextOrder();
    setupValidation([
      _orderCtrl,
      _nameCtrl,
      _latitudeCtrl,
      _longitudeCtrl,
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
    List<TextEditingController> camposObrigatorios = [
      _orderCtrl,
      _nameCtrl,
      _latitudeCtrl,
      _longitudeCtrl,
    ];
      camposObrigatorios.addAll([
        _orderCtrl,
        _nameCtrl,
        _latitudeCtrl,
        _longitudeCtrl,
      ]);


    final valid = areFieldsFilled(camposObrigatorios, minLength: 1);

    if (_formValidated != valid) {
      setState(() => _formValidated = valid);
    }
  }



  void _fillFields(OaesData data) {
    setState(() {
      _editingMode = true;
      _currentOaesId = data.id;
      _orderCtrl.text = data.order.toString();
      _nameCtrl.text = data.identificationName ?? '';
      _latitudeCtrl.text = data.latitude.toString();
      _longitudeCtrl.text = data.longitude.toString();
      _scoreCtrl.text = data.score.toString();
      _stateCtrl.text = data.state ?? '';
      _roadCtrl.text = data.road ?? '';
      _regionCtrl.text = data.region ?? '';
      _extensionCtrl.text = convertDoubletoString(data.extension);
      _widthCtrl.text = data.width.toString();
      _areaCtrl.text = data.area.toString();
      _structureCtrl.text = data.structureType ?? '';
      _contractsCtrl.text = data.relatedContracts.toString();
      _interventionValueCtrl.text = convertDoubletoString(data.valueIntervention);
      _linearCostCtrl.text = data.linearCostMedia.toString();
      _estimateCtrl.text = data.costEstimate.toString();
      _companyCtrl.text = data.companyBuild ?? '';
      _dateCtrl.text = data.lastDateIntervention != null ? convertDateTimeToDDMMYYYY(data.lastDateIntervention!) : '';
      _latitudeCtrl.text = data.latitude.toString();
      _longitudeCtrl.text = data.longitude.toString();
      _altitudeCtrl.text = data.altitude.toString();
    });
  }

  Future<void> _setNextOrder() async {
    if (widget.contractData?.id == null) return;

    final list = await _oaesBloc.getAllOAEs();

    final lastOrder = list.map((e) => e.order ?? 0).fold(0, (a, b) => a > b ? a : b);
    setState(() {
      _orderCtrl.text = (lastOrder + 1).toString();
    });
  }

  void _createNewAdditive() async {
    if (widget.contractData?.id == null) return;

    final list = await _oaesBloc.getAllOAEs();

    final lastOrder = list.map((e) => e.order ?? 0).fold(0, (a, b) => a > b ? a : b);

    setState(() {
      _editingMode = false;
      _currentOaesId = null;
      _orderCtrl.text = (lastOrder + 1).toString();
      _nameCtrl.clear();
      _latitudeCtrl.clear();
      _longitudeCtrl.clear();
      _scoreCtrl.clear();
      _stateCtrl.clear();
      _roadCtrl.clear();
      _regionCtrl.clear();
      _extensionCtrl.clear();
      _widthCtrl.clear();
      _areaCtrl.clear();
      _structureCtrl.clear();
      _contractsCtrl.clear();
      _interventionValueCtrl.clear();
      _linearCostCtrl.clear();
      _estimateCtrl.clear();
      _companyCtrl.clear();
      _dateCtrl.clear();
      _latitudeCtrl.clear();
      _longitudeCtrl.clear();
      _altitudeCtrl.clear();
    });
  }

  String limparNumero(String input) {
    return input.replaceAll(RegExp(r'[^\d]'), '');
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
    final novo = OaesData(
      id: _currentOaesId,
      order: _orderCtrl.text.isNotEmpty ? int.tryParse(_orderCtrl.text) : null,
      identificationName: _nameCtrl.text,
      latitude: _latitudeCtrl.text.isNotEmpty ? double.tryParse(_latitudeCtrl.text) : null,
      longitude: _longitudeCtrl.text.isNotEmpty ? double.tryParse(_longitudeCtrl.text) : null,
      score: _scoreCtrl.text.isNotEmpty ? double.tryParse(_scoreCtrl.text) : null,
      state: _stateCtrl.text,
      road: _roadCtrl.text,
      region: _regionCtrl.text,
      extension: _extensionCtrl.text.isNotEmpty ? double.tryParse(_extensionCtrl.text) : null,
      width: _widthCtrl.text.isNotEmpty ? double.tryParse(_widthCtrl.text) : null,
      area: _areaCtrl.text.isNotEmpty ? double.tryParse(_areaCtrl.text) : null,
      structureType: _structureCtrl.text,
      relatedContracts: _contractsCtrl.text,
      linearCostMedia: _linearCostCtrl.text.isNotEmpty ? double.tryParse(_linearCostCtrl.text) : null,
      costEstimate: _estimateCtrl.text.isNotEmpty ? double.tryParse(_estimateCtrl.text) : null,
      companyBuild: _companyCtrl.text,
      lastDateIntervention: _dateCtrl.text.isNotEmpty ? convertDDMMYYYYToDateTime(_dateCtrl.text) : null,
      altitude: _altitudeCtrl.text.isNotEmpty ? double.tryParse(_altitudeCtrl.text) : null,
    );

    await _oaesBloc.saveOrUpdateOAE(novo);
    if (!_editingMode) {
      _setNextOrder();
    }
    setState(() {
      _futureOaes = _oaesBloc.getAllOAEs();
      _currentOaesId = null;
      _editingMode = false;
      _isSaving = false;

      if (!_editingMode) {
        _orderCtrl.clear();
      }
      _nameCtrl.clear();
      _latitudeCtrl.clear();
      _longitudeCtrl.clear();
      _scoreCtrl.clear();
      _stateCtrl.clear();
      _roadCtrl.clear();
      _regionCtrl.clear();
      _extensionCtrl.clear();
      _widthCtrl.clear();
      _areaCtrl.clear();
      _structureCtrl.clear();
      _contractsCtrl.clear();
      _interventionValueCtrl.clear();
      _linearCostCtrl.clear();
      _estimateCtrl.clear();
      _companyCtrl.clear();
      _dateCtrl.clear();
      _altitudeCtrl.clear();
    });


    final wasEditing = _editingMode;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasEditing ? 'Aditivo atualizado com sucesso!' : 'Aditivo salvo com sucesso!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _deleteData(String idOaes) async {
    await _oaesBloc.deletarOAE(idOaes);
    setState(() {
      _futureOaes = _oaesBloc.getAllOAEs();
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OAEs deletado com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 12),
            Expanded(
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            DividerText(title: 'Cadastrar OAE no sistema'),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: _buildFormCampos(),
                            ),
                            FutureBuilder<List<OaesData>>(
                              future: _futureOaes,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                } else if (snapshot.hasError) {
                                  return Center(child: Text('Erro: ${snapshot.error}'));
                                }else if(!snapshot.hasData || snapshot.data!.isEmpty){
                                  return Center(child: Text('Nenhuma OAE encontrada'));
                                }

                                final additives = snapshot.data ?? [];
                                final List<double>? oaesValue = snapshot.data?.map((data) => data.valueIntervention ?? 0).toList();
                                final List<String>? oaesOrder = snapshot.data?.map((data) => data.order.toString()).toList();

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 12),
                                    DividerText(title: 'Gráfico das OAEs cadastradas'),
                                    const SizedBox(height: 12),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        const double larguraGraficoPizza = 300;

                                        return SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 12),
                                              PieChartChanged(
                                                labels: oaesOrder!,
                                                values: oaesValue!,
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
                                              BarChartChanged(
                                                selectedIndex: _selectedLine,
                                                labels: oaesOrder,
                                                values: oaesValue,
                                                onBarTap: (label) {
                                                  final index = additives.indexWhere((e) => e.order.toString() == label);
                                                  if (index != -1) {
                                                    setState(() {
                                                      _selectedLine = index;
                                                      _fillFields(additives[index]);
                                                    });
                                                  }
                                                },

                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    DividerText(title: 'OAEs cadastradas no sistema'),
                                    const SizedBox(height: 12),
                                    ModalOaesRegistrationTableSection(
                                        onTapItem: _fillFields,
                                        onDelete: _deleteData,
                                        futureOaes: _futureOaes)
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
              ),
            ),
            const FootBar(),
          ],
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

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      reservedWidth: 100.0,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      spaceBetweenReserved: 12.0,
    );
  }

  Widget _buildFormCampos() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 700;

        final camposWrap = Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _input(_orderCtrl, 'ORDEM', enabled: false),
            _input(_nameCtrl, 'IDENTIFICAÇÃO', tooltip: true),
            _input(_latitudeCtrl, 'LATITUDE', tooltip: true),
            _input(_longitudeCtrl, 'LONGITUDE', tooltip: true),
            _input(_scoreCtrl, 'SCORE', tooltip: true),
            _input(_stateCtrl, 'STATUS', tooltip: true),
            _input(_roadCtrl, 'REGIÃO', tooltip: true),
            _input(_regionCtrl, 'REGIÃO', tooltip: true),
            _input(_extensionCtrl, 'EXTENSÃO', tooltip: true),
            _input(_widthCtrl, 'LARGURA', tooltip: true),
            _input(_areaCtrl, 'ÁREA', tooltip: true),
            _input(_structureCtrl, 'TIPO DE ESTRUTURA', tooltip: true),
            _input(_contractsCtrl, 'CONTRATOS RELACIONADOS', tooltip: true),
            _input(_interventionValueCtrl, 'VALOR INTERVENÇÃO', tooltip: true),
            _input(_linearCostCtrl, 'CUSTO MÉDIO', tooltip: true),
            _input(_estimateCtrl, 'CUSTO ESTIMADO', tooltip: true),
            _input(_companyCtrl, 'EMPRESA QUE CONSTRUIU', tooltip: true),
            _input(_dateCtrl, 'ÚLTIMA DATA DE INTERVENÇÃO', tooltip: true),
            _input(_altitudeCtrl, 'ALTITUDE', tooltip: true),
          ],
        );

        final botoes = Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _formValidated ? (_isEditable ? _saveOrUpdateAdditive : null) : null,
              icon: const Icon(Icons.save),
              label: Text(_editingMode ? 'Atualizar' : 'Salvar'),
            ),
            const SizedBox(width: 12),
            if (_editingMode)
              TextButton.icon(
                icon: const Icon(Icons.update),
                label: const Text('Limpar'),
                onPressed: _createNewAdditive,
              ),
          ],
        );

        final corpo = Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            camposWrap,
            const SizedBox(height: 12),
            botoes,
          ],
        );

        final container = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(8),
          child: isSmallScreen
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentOaesId != null) Container(),
              const SizedBox(height: 12),
              corpo,
            ],
          )
              : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentOaesId != null) Container(),
              const SizedBox(width: 12),
              Expanded(child: corpo),
            ],
          ),
        );

        return container;
      },
    );
  }

  Widget _input(
      TextEditingController ctrl,
      String label, {
        bool enabled = true,
        bool date = false,
        bool money = false,
        bool tooltip = false,
        TextInputFormatter? mask,
      }) {
    return Tooltip(
      message: tooltip ? 'Este campo é calculado automaticamente e não pode ser editado.' : '',
      child: CustomTextField(
        width: getInputWidth(context),
        controller: ctrl,
        enabled: enabled && _isEditable,
        labelText: label,
        keyboardType: date
            ? TextInputType.datetime
            : money
            ? TextInputType.number
            : null,
        inputFormatters: [
          if (date)
            FilteringTextInputFormatter.digitsOnly,
          if (date)
            TextInputMask(mask: '99/99/9999'),
          if (money)
            CurrencyInputFormatter(
              leadingSymbol: 'R\$',
              useSymbolPadding: true,
              thousandSeparator: ThousandSeparator.Period,
              mantissaLength: 2,
            ),
          if (mask != null) mask,
        ],
      ),
    );
  }


  @override
  void dispose() {
    removeValidation([
      _orderCtrl,
      _nameCtrl,
      _latitudeCtrl,
      _longitudeCtrl,
    ], _validateForm);
    _orderCtrl.dispose();
    _nameCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _scoreCtrl.dispose();
    _stateCtrl.dispose();
    _roadCtrl.dispose();
    _regionCtrl.dispose();
    _extensionCtrl.dispose();
    _widthCtrl.dispose();
    _areaCtrl.dispose();
    _structureCtrl.dispose();
    _contractsCtrl.dispose();
    _interventionValueCtrl.dispose();
    _linearCostCtrl.dispose();
    _estimateCtrl.dispose();
    _companyCtrl.dispose();
    _dateCtrl.dispose();
    _altitudeCtrl.dispose();
    super.dispose();
  }
}

