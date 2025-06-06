import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_widgets/background/background_cleaner.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../../../_widgets/input/drop_down_botton_change.dart';
import 'contract_details.dart';

class ContractListMenuPage extends StatefulWidget {
  const ContractListMenuPage({super.key});

  @override
  State<ContractListMenuPage> createState() => _ContractListMenuPageState();
}

class _ContractListMenuPageState extends State<ContractListMenuPage> {
  late final ContractsBloc _contractsBloc = ContractsBloc();
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  final List<String> _tiposDeStatus = [
    'A INICIAR',
    'EM ANDAMENTO',
    'CONCLUÍDO',
    'PARALIZADO',
    'CANCELADO',
  ];
  final _tipoStatusCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  Future<List<ContractData>> _getFilteredContracts() {
    return _contractsBloc.getAllContracts(
      statusFilter:
          _tipoStatusCtrl.text.isNotEmpty ? _tipoStatusCtrl.text : null,
      searchQuery: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
    );
  }

  void _limparFiltros() {
    _searchCtrl.clear();
    _tipoStatusCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BackgroundCleaner(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 60.0, top: 16.0, bottom: 12),
                child: Text(
                  'Contratos cadastrados no sistema',
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: RawKeyboardListener(
                                      focusNode: FocusNode(),
                                      onKey: (event) {
                                        if (event.isKeyPressed(
                                          LogicalKeyboardKey.enter,
                                        )) {
                                          setState(() {});
                                        }
                                      },
                                      child: CustomTextField(
                                        labelText: 'Pesquisar...',
                                        controller: _searchCtrl,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () {
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropDownButtonChange(
                                labelText: 'Status',
                                items: _tiposDeStatus,
                                controller: _tipoStatusCtrl,
                                // Atualiza a lista ao selecionar um novo status
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: _limparFiltros,
                              child: const Text('Limpar filtros'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: FutureBuilder<List<ContractData>>(
                    future: _getFilteredContracts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Erro: ${snapshot.error}'));
                      } else {
                        final contracts = snapshot.data!;
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Table(
                                columnWidths: const {
                                  0: FractionColumnWidth(0.10),
                                  1: FractionColumnWidth(0.45),
                                  2: FractionColumnWidth(0.35),
                                  3: FractionColumnWidth(0.10),
                                },
                                border: TableBorder.all(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey.shade300,
                                ),
                                children: [
                                  const TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                    ),
                                    children: [
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'CONTRATO',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'OBRA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'Nº PROCESSO',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            'APAGAR',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  ...contracts.map(
                                    (contractData) => TableRow(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                      ),
                                      children: [
                                        _buildCell(contractData.contractnumber),
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          ContractDetailsPage(
                                                            contractData:
                                                                contractData,
                                                          ),
                                                ),
                                              );
                                            },
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                              child: Text(
                                                contractData
                                                        .summarysubjectcontract ??
                                                    '',
                                              ),
                                            ),
                                          ),
                                        ),
                                        _buildCell(
                                          contractData
                                              .contractbiddingprocessnumber,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () async {
                                                final confirm = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (_) => AlertDialog(
                                                        title: Text(
                                                          'Confirmar exclusão',
                                                        ),
                                                        content: Text(
                                                          'Deseja apagar este contrato?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            child: Text(
                                                              'Cancelar',
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                          ),
                                                          ElevatedButton(
                                                            child: Text(
                                                              'Apagar',
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                                if (confirm == true &&
                                                    contractData.uid != null) {
                                                  // Certifique-se de que esse método exista no ContractsBloc
                                                  await _contractsBloc
                                                      .deleteContract(
                                                        contractData.uid!,
                                                      );
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ContractDetailsPage(),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Adicionar novo contrato'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String? text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Center(child: Text(text ?? '')),
    );
  }
}
