import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_datas/user/user_data.dart';
import 'package:sisgeo/_widgets/background/background_cleaner.dart';
import '../../../_models/user/user_model.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../../../_widgets/input/drop_down_botton_change.dart';
import 'tab_bar_contract_page.dart';

class ListContractPage extends StatefulWidget {
  const ListContractPage({super.key});

  @override
  State<ListContractPage> createState() => _ListContractPageState();
}

class _ListContractPageState extends State<ListContractPage> {
  late final ContractsBloc _contractsBloc = ContractsBloc();
  final _tipoStatusCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();

  final List<String> _tiposDeStatus = [
    'A INICIAR',
    'EM ANDAMENTO',
    'CONCLUÍDO',
    'PARALIZADO',
    'CANCELADO',
  ];


  void _limparFiltros() {
    _searchCtrl.clear();
    _tipoStatusCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final currentUser = Provider.of<UserProvider>(context).userData;

    return Scaffold(
      body: Stack(
        children: [
          BackgroundCleaner(),
          if (currentUser == null)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: LayoutBuilder(
                builder: (context, constraints) {
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
                        child: _buildFiltros(constraints),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FutureBuilder<List<ContractData>>(
                          future: _contractsBloc.getFilteredContracts(currentUser: currentUser),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Erro: \${snapshot.error}'));
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
                                      0: FixedColumnWidth(120),
                                      1: FixedColumnWidth(420),
                                      2: FixedColumnWidth(200),
                                      3: FixedColumnWidth(80),
                                    },
                                    children: [
                                      const TableRow(
                                        decoration: BoxDecoration(color: Colors.white),
                                        children: [
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('CONTRATO', style: TextStyle(fontWeight: FontWeight.bold)))),
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('OBRA', style: TextStyle(fontWeight: FontWeight.bold)))),
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('Nº PROCESSO', style: TextStyle(fontWeight: FontWeight.bold)))),
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('APAGAR', style: TextStyle(fontWeight: FontWeight.bold)))),
                                        ],
                                      ),
                                      ...contracts.map(
                                            (contractData) {

                                              final canDelete = _contractsBloc.canDeleteContract(
                                                userData: currentUser,
                                                contract: contractData,
                                              );
                                              return TableRow(
                                                decoration: const BoxDecoration(color: Colors.white),
                                                children: [
                                                  _buildCell(contractData.contractNumber, contractData, Alignment.center),
                                                  _buildCell(contractData.summarySubjectContract, contractData, Alignment.centerLeft),
                                                  _buildCell(contractData.contractBiddingProcessNumber, contractData, Alignment.center),

                                                  TableCell(
                                                    child: Center(
                                                      child: IconButton(
                                                        icon: Icon(
                                                          Icons.delete,
                                                          color: canDelete ? Colors.red : Colors.grey,
                                                        ),
                                                        onPressed: canDelete
                                                            ? () async {
                                                          final confirm = await showDialog<bool>(
                                                            context: context,
                                                            builder: (_) => AlertDialog(
                                                              title: const Text('Confirmar exclusão'),
                                                              content: const Text('Deseja apagar este contrato?'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () => Navigator.pop(context, false),
                                                                  child: const Text('Cancelar'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () => Navigator.pop(context, true),
                                                                  child: const Text('Apagar'),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                          if (confirm == true && contractData.id != null) {
                                                            await _contractsBloc.deleteContract(contractData.id!);
                                                            setState(() {});
                                                          }
                                                        }
                                                            : null,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              );
                                            },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TabBarContractPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar novo contrato'),
                            ),
                          ),
                        ],
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

  Widget _buildFiltros(BoxConstraints constraints) {
    final isMobile = constraints.maxWidth < 600;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: isMobile ? [
            Row(
              children: [
                Expanded(
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      if (event.isKeyPressed(LogicalKeyboardKey.enter)) setState(() {});
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
                  ),
                )
              ],
            ),
          ] : [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (event) {
                            if (event.isKeyPressed(LogicalKeyboardKey.enter)) setState(() {});
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
    );
  }

  Widget _buildCell(String? text, ContractData contractData, Alignment alignment) {
    return TableCell(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TabBarContractPage(contractData: contractData),
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
