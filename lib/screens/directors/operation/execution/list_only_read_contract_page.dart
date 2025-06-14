import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_widgets/background/background_cleaner.dart';
import 'package:sisgeo/screens/directors/operation/execution/tab_bar_work_execution_page.dart';

import '../../../../_widgets/input/custom_text_field.dart';
import '../../../../_widgets/input/drop_down_botton_change.dart';

class ListOnlyReadContractPage extends StatefulWidget {
  const ListOnlyReadContractPage({super.key});

  @override
  State<ListOnlyReadContractPage> createState() => _ListOnlyReadContractPageState();
}

class _ListOnlyReadContractPageState extends State<ListOnlyReadContractPage> {
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
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double maxWidth;
                if (constraints.maxWidth >= 1000) {
                  maxWidth = 500;
                } else if (constraints.maxWidth >= 600) {
                  maxWidth = 400;
                } else {
                  maxWidth = constraints.maxWidth * 0.75;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 80.0, top: 24, bottom: 6),
                      child: Text(
                        'Contratos cadastrados',
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
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              constraints.maxWidth < 600
                                  ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: RawKeyboardListener(
                                          focusNode: FocusNode(),
                                          onKey: (event) {
                                            if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                                              setState(() {});
                                            }
                                          },
                                          child: CustomTextField(
                                            labelText: 'Pesquisar...',
                                            controller: _searchCtrl,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 62,
                                        height: 48,
                                        child: IconButton(
                                          icon: const Icon(Icons.search),
                                          onPressed: () => setState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: DropDownButtonChange(
                                          labelText: 'Status',
                                          items: _tiposDeStatus,
                                          controller: _tipoStatusCtrl,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        height: 48,
                                        child: TextButton(
                                          onPressed: _limparFiltros,
                                          child: const Text('Limpar'),
                                        )
                                      )
                                    ],
                                  ),
                                ],
                              )
                                  : Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: RawKeyboardListener(
                                            focusNode: FocusNode(),
                                            onKey: (event) {
                                              if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                                                setState(() {});
                                              }
                                            },
                                            child: CustomTextField(
                                              labelText: 'Pesquisar...',
                                              controller: _searchCtrl,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 70,
                                          height: 48,
                                          child: IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: () => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: DropDownButtonChange(
                                            labelText: 'Status',
                                            items: _tiposDeStatus,
                                            controller: _tipoStatusCtrl,
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 70,
                                          height: 48,
                                          child: TextButton(
                                            onPressed: _limparFiltros,
                                            child: const Text('Limpar'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
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
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: Table(
                                  border: TableBorder.all(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey.shade300,
                                  ),
                                  columnWidths: const {
                                    0: FixedColumnWidth(120), // CONTRATO
                                    1: FixedColumnWidth(420), // OBRA
                                    2: FixedColumnWidth(200), // Nº PROCESSO
                                    3: FixedColumnWidth(80), // APAGAR
                                  },
                                  children: [
                                    const TableRow(
                                      decoration: BoxDecoration(color: Colors.white),
                                      children: [
                                        Center(child: Padding(padding: EdgeInsets.all(8), child: Text('CONTRATO', style: TextStyle(fontWeight: FontWeight.bold)))),
                                        Center(child: Padding(padding: EdgeInsets.all(8), child: Text('OBRA', style: TextStyle(fontWeight: FontWeight.bold)))),
                                        Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Nº PROCESSO', style: TextStyle(fontWeight: FontWeight.bold)))),
                                      ],
                                    ),
                                    ...contracts.map(
                                          (contractData) => TableRow(
                                        decoration: const BoxDecoration(color: Colors.white),
                                        children: [
                                          _buildCell(contractData.contractNumber, contractData, Alignment.center),
                                          _buildCell(contractData.summarySubjectContract, contractData, Alignment.centerLeft),
                                          _buildCell(contractData.contractBiddingProcessNumber, contractData, Alignment.center),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCell(
      String? text,
      ContractData contractData,
      Alignment alignment) {
    return TableCell(
      child: InkWell(
        onTap: (){
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarWorkExecutionPage(contractData: contractData),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: alignment,
            child: Text(
                text ?? '',
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}
