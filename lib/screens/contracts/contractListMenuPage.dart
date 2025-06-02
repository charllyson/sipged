import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_widgets/background/backgroundCleaner.dart';
import '../../_widgets/background/background.dart';
import 'contractDetails.dart';

class ContractListMenuPage extends StatefulWidget {
  const ContractListMenuPage({super.key});

  @override
  State<ContractListMenuPage> createState() => _ContractListMenuPageState();
}

class _ContractListMenuPageState extends State<ContractListMenuPage> {
  late final ContractsBloc _contractsBloc = ContractsBloc();
  User? firebaseUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BackgroundCleaner(),
          Builder(
            builder:
                (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 60.0,
                        top: 16.0,
                        bottom: 12,
                      ),
                      child: Text(
                        'Contratos cadastrados no sistema',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FutureBuilder<List<ContractData>>(
                          future: _contractsBloc.getAllContracts(),
                          builder: (context, listContractsData) {
                            if (!listContractsData.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (listContractsData.hasError) {
                              return Center(
                                child: Text('Erro: ${listContractsData.error}'),
                              );
                            } else {
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
                                        ...listContractsData.data!.map(
                                          (contractData) => TableRow(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                            ),
                                            children: [
                                              _buildCell(
                                                contractData.contractnumber,
                                              ),
                                              TableCell(
                                                verticalAlignment:
                                                    TableCellVerticalAlignment
                                                        .middle,
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
                                                    onPressed: () {},
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
                                        onPressed: (){

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
          ),
        ],
      ),
    );
  }

  Widget _buildCell(String? text) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ContractDetailsPage()));
        },
        child: Center(child: Text(text ?? '')),
      ),
    );
  }
}
