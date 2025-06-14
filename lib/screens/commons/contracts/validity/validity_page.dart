import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import 'package:sisgeo/_widgets/input/drop_down_botton_change.dart';

import '../../../../_widgets/input/custom_text_field.dart';

class ValidityPage extends StatefulWidget {
  const ValidityPage({super.key, this.contractData});
  final ContractData? contractData;

  @override
  State<ValidityPage> createState() => _ValidityPageState();
}

class _ValidityPageState extends State<ValidityPage> {
  late ContractsBloc _contractsBloc;
  late Future<List<ValidityData>> _futureValidity;

  final _ordemCtrl = TextEditingController();
  final _tipoOrdemCtrl = TextEditingController();
  final _dataOrdemCtrl = TextEditingController();

  String? _currentValidityId;
  bool _isSaving = false;

  final List<String> _tiposDeOrdem = [
    'ORDEM DE INÍCIO',
    'ORDEM DE PARALIZAÇÃO',
    'ORDEM DE REINÍCIO',
    'ORDEM DE FINALIZAÇÃO',
  ];


  @override
  void initState() {
    super.initState();
    _contractsBloc = ContractsBloc();
    if (widget.contractData?.id != null) {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.id!,
      ).then((list) {
        if (list.isNotEmpty) {
          final ultimaOrdem = list.map((e) => e.ordernumber ?? 0).reduce((a, b) => a > b ? a : b);
          _ordemCtrl.text = (ultimaOrdem + 1).toString();
        } else {
          _ordemCtrl.text = '1';
        }
        return list;
      });
    } else {
      _futureValidity = Future.value([]);
    }

    if (_ordemCtrl.text.isEmpty) {
      _ordemCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _ordemCtrl.dispose();
    _tipoOrdemCtrl.dispose();
    _dataOrdemCtrl.dispose();
    super.dispose();
  }

  void preencherCampos(ValidityData data) {
    setState(() {
      _currentValidityId = data.uid;
      _tipoOrdemCtrl.text = data.ordertype ?? '';
      _ordemCtrl.text = data.ordernumber.toString(); // <- aqui está o valor visível
      final tipo = data.ordertype ?? '';
      if (_tiposDeOrdem.contains(tipo)) {
        _tipoOrdemCtrl.text = tipo;
      } else {
        _tipoOrdemCtrl.clear(); // evita erro se o tipo não existir mais
      }

      _dataOrdemCtrl.text = convertDateTimeToDDMMYYYY(data.orderdate!);
    });
  }

  void _salvarOuAtualizarValidade() async {
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

    final novaValidade = ValidityData(
      uid: _currentValidityId,
      uidContract: widget.contractData!.id,
      ordernumber: int.tryParse(_ordemCtrl.text),
      ordertype: _tipoOrdemCtrl.text,
      orderdate: convertDDMMYYYYToDateTime(_dataOrdemCtrl.text),
    );

    await _contractsBloc.salvarOuAtualizarValidade(novaValidade);

    setState(() {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.id!,
      ).then((list) {
        if (_currentValidityId == null && list.isNotEmpty) {
          final ultimaOrdem = list.map((e) => e.ordernumber ?? 0).reduce((a, b) => a > b ? a : b);
          _ordemCtrl.text = (ultimaOrdem + 1).toString();
        }
        return list;
      });
      _currentValidityId = null;
      _tipoOrdemCtrl.clear();
      _dataOrdemCtrl.clear();
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

  void _deletarValidade(String validadeId) async {
    if (widget.contractData?.id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja realmente apagar esta ordem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm != true) return;
    await _contractsBloc.deletarValidade(widget.contractData!.id!, validadeId);
    setState(() {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.id!,
      );
    });
  }


  double getResponsiveWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const spacing = 12; // mesmo valor usado no Wrap
    const margin = 12;

    if (screenWidth < 600) {
      return screenWidth - margin - 32; // 1 por linha
    } else if (screenWidth < 1000) {
      return (screenWidth - spacing - margin * 1 - 32) / 2; // 2 por linha
    } else {
      return (screenWidth - spacing - margin * 2 - 32) / 3; // 3 por linha
    }
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
                _buildCamposFormulario(),
                FutureBuilder<List<ValidityData>>(
                  future: _futureValidity,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhuma ordem encontrada'),
                      );
                    }

                    final list = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Ordens cadastradas no sistema', style: TextStyle(fontSize: 20)),
                        ),
                        _buildTabela(list),
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
            color: Colors.black.withValues(alpha: 255 * 0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildCamposFormulario() {
    final camposPreenchidos = _ordemCtrl.text.isNotEmpty && _tipoOrdemCtrl.text.isNotEmpty && _dataOrdemCtrl.text.length == 10;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: getResponsiveWidth(context),
                    child: Tooltip(
                      message: 'Este campo é calculado automaticamente e não pode ser editado.',
                      child: CustomTextField(
                        labelText: 'Ordem',
                        controller: _ordemCtrl,
                        enabled: false,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: getResponsiveWidth(context),
                      child: DropDownButtonChange(
                        labelText: 'Tipo da ordem',
                        items: _tiposDeOrdem,
                        controller: _tipoOrdemCtrl,
                      ),
                  ),
                  SizedBox(
                    width: getResponsiveWidth(context),
                    child: CustomTextField(
                      labelText: 'Data da ordem',
                      controller: _dataOrdemCtrl,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputMask(mask: '99/99/9999'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentValidityId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.restore_sharp),
                    label: const Text('Limpar'),
                    onPressed: _criarNovaOrdem,
                  ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: camposPreenchidos && !_isSaving ? _salvarOuAtualizarValidade : null,
                  icon: const Icon(Icons.save),
                  label: Text(_currentValidityId != null ? 'Atualizar' : 'Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _criarNovaOrdem() async {
    if (widget.contractData?.id == null) return;

    final list = await _contractsBloc.getAllValidityOfContract(
      uidContract: widget.contractData!.id!,
    );

    final ultimaOrdem = list.map((e) => e.ordernumber ?? 0).fold(0, (a, b) => a > b ? a : b);

    setState(() {
      _currentValidityId = null;
      _ordemCtrl.text = (ultimaOrdem + 1).toString();
      _tipoOrdemCtrl.clear();
      _dataOrdemCtrl.clear();
    });
  }


  Widget _buildTabela(List<ValidityData> list) {
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
                0: FixedColumnWidth(80), // ORDEM
                1: FixedColumnWidth(150), // TIPO
                2: FixedColumnWidth(100), // DATA
                3: FixedColumnWidth(80),  // APAGAR
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
              textAlign: TextAlign.center, // Alinhamento horizontal
              title, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(ValidityData data) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildCell(data.ordernumber.toString(), () => preencherCampos(data), Alignment.center),
        _buildCell(data.ordertype ?? '', () => preencherCampos(data), Alignment.bottomLeft),
        _buildCell(convertDateTimeToDDMMYYYY(data.orderdate!), () => preencherCampos(data), Alignment.center),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deletarValidade(data.uid!),
            ),
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
}

class TextInputMask extends TextInputFormatter {
  final String mask;
  TextInputMask({required this.mask});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String newText = '';
    int digitIndex = 0;

    for (int i = 0; i < mask.length && digitIndex < digits.length; i++) {
      if (mask[i] == '9') {
        newText += digits[digitIndex];
        digitIndex++;
      } else {
        newText += mask[i];
      }
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
