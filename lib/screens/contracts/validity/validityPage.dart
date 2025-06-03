import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_datas/validity/validity_data.dart';
import 'package:sisgeo/_widgets/formats/format_field.dart';
import 'package:sisgeo/_widgets/input/drop_down_botton_change.dart';

import '../../../_widgets/input/custom_text_field.dart';

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
  bool _ordemBloqueada = true;
  bool _forcarEdicaoOrdem = false;

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
    if (widget.contractData?.uid != null) {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.uid!,
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
    if (widget.contractData?.uid == null) return;

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
      uidContract: widget.contractData!.uid,
      ordernumber: int.tryParse(_ordemCtrl.text),
      ordertype: _tipoOrdemCtrl.text,
      orderdate: convertDDMMYYYYToDateTime(_dataOrdemCtrl.text),
    );

    await _contractsBloc.salvarOuAtualizarValidade(novaValidade);

    setState(() {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.uid!,
      ).then((list) {
        if (_currentValidityId == null && list.isNotEmpty) {
          final ultimaOrdem = list.map((e) => e.ordernumber ?? 0).reduce((a, b) => a > b ? a : b);
          _ordemCtrl.text = (ultimaOrdem + 1).toString();
        }
        return list;
      });
      _currentValidityId = null;
      _ordemBloqueada = true;
      _tipoOrdemCtrl.clear();
      _dataOrdemCtrl.clear();
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ordem salva com sucesso!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _deletarValidade(String validadeId) async {
    if (widget.contractData?.uid == null) return;

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

    await _contractsBloc.deletarValidade(widget.contractData!.uid!, validadeId);
    setState(() {
      _futureValidity = _contractsBloc.getAllValidityOfContract(
        uidContract: widget.contractData!.uid!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<List<ValidityData>>(
              future: _futureValidity,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }else if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar dados: \${snapshot.error}'));
                }else if(!snapshot.hasData || snapshot.data!.isEmpty){
                  return Center(child: Text('Nenhuma ordem encontrada'));
                }

                final list = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCamposFormulario(),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Ordens cadastradas no sistema', style: TextStyle(fontSize: 20)),
                    ),
                    _buildTabela(list),
                  ],
                );
              },
            ),
          ),
        ),
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildCamposFormulario() {
    final camposPreenchidos =
        _ordemCtrl.text.isNotEmpty && _tipoOrdemCtrl.text.isNotEmpty && _dataOrdemCtrl.text.length == 10;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: 'Este campo é calculado automaticamente e não pode ser editado.',
                    child: CustomTextField(
                      labelText: 'Ordem',
                      controller: _ordemCtrl,
                      enabled: false,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: DropDownButtonChange(
                        labelText: 'Tipo da ordem',
                        items: _tiposDeOrdem,
                        controller: _tipoOrdemCtrl,
                      ),
                    ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentValidityId != null)
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar nova ordem'),
                    onPressed: _criarNovaOrdem,
                  ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: camposPreenchidos && !_isSaving ? _salvarOuAtualizarValidade : null,
                  icon: const Icon(Icons.save),
                  label: Text(_currentValidityId != null ? 'Atualizar ordem' : 'Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _criarNovaOrdem() async {
    if (widget.contractData?.uid == null) return;

    final list = await _contractsBloc.getAllValidityOfContract(
      uidContract: widget.contractData!.uid!,
    );

    final ultimaOrdem = list.map((e) => e.ordernumber ?? 0).fold(0, (a, b) => a > b ? a : b);

    setState(() {
      _currentValidityId = null;
      _ordemCtrl.text = (ultimaOrdem + 1).toString();
      _tipoOrdemCtrl.clear();
      _dataOrdemCtrl.clear();
      _ordemBloqueada = true;
    });
  }


  Widget _buildTabela(List<ValidityData> list) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final larguraTotal = constraints.maxWidth;
        final col0 = larguraTotal * 0.3;
        final col1 = larguraTotal * 0.3;
        final col2 = larguraTotal * 0.3;
        final col3 = larguraTotal * 0.09;

        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              columnWidths: {
                0: FixedColumnWidth(col0),
                1: FixedColumnWidth(col1),
                2: FixedColumnWidth(col2),
                3: FixedColumnWidth(col3),
              },
              border: TableBorder.all(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade300,
              ),
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
          child: Center(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        );
      }).toList(),
    );
  }

  TableRow _buildDataRow(ValidityData data) {
    return TableRow(
      decoration: const BoxDecoration(color: Colors.white),
      children: [
        _buildCell(data.ordernumber.toString(), () => preencherCampos(data)),
        _buildCell(data.ordertype ?? '', () => preencherCampos(data)),
        _buildCell(convertDateTimeToDDMMYYYY(data.orderdate!), () => preencherCampos(data)),
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

  Widget _buildCell(String? text, VoidCallback onTap) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: onTap,
        child: Center(
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

DateTime convertDDMMYYYYToDateTime(String input) {
  final parts = input.split('/');
  if (parts.length != 3) throw FormatException("Formato inválido. Use dd/MM/yyyy");
  final day = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final year = int.parse(parts[2]);
  return DateTime(year, month, day);
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
