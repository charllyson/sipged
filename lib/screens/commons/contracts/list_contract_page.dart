import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_datas/contracts/contracts_data.dart';
import 'package:sisgeo/_widgets/background/background_cleaner.dart';
import 'package:sisgeo/_widgets/buttons/deleteButtonPermission.dart';
import '../../../_blocs/user/user_bloc.dart';
import '../../../_datas/user/user_data.dart';
import '../../../_provider/user/user_provider.dart';
import '../../../_widgets/input/custom_text_field.dart';
import '../../../_widgets/input/drop_down_botton_change.dart';
import 'tab_bar_contract_page.dart';

class ListContractPage extends StatefulWidget {
  const ListContractPage({super.key});

  @override
  State<ListContractPage> createState() => _ListContractPageState();
}

class _ListContractPageState extends State<ListContractPage> {
  late UserBloc _userBloc;
  UserData? _currentUser;
  late ContractsBloc _contractsBloc;

  final _contractTypesStatusCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  Future<List<ContractData>>? _futureContracts;

  bool _isEditable = false;

  final List<String> _contractTypesStatus = [
    'A INICIAR',
    'EM ANDAMENTO',
    'CONCLUÍDO',
    'PARALIZADO',
    'CANCELADO',
  ];

  @override
  void initState() {
    super.initState();
    _userBloc = UserBloc();
    _contractsBloc = ContractsBloc();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).userData;
      if (user != null) {
        _currentUser = user;
        _isEditable = _userBloc.getUserCreateEditPermissions(userData: user);
        _futureContracts = _contractsBloc.getFilteredContracts(currentUser: user);
        setState(() {});
      }
    });
  }

  bool isDisabled(String module) {
    final perms = _currentUser?.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _contractTypesStatusCtrl.clear();
    setState(() {});
  }

  void _deleteContract(String idContract) async {
    if (idContract == null) return;
    await _contractsBloc.deleteContract(idContract);
    setState(() {
      if (_currentUser != null) {
        _futureContracts = _contractsBloc.getFilteredContracts(currentUser: _currentUser!);
      }
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contrato deletado com sucesso!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
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
                          future: _futureContracts,
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
                                              return TableRow(
                                                decoration: const BoxDecoration(color: Colors.white),
                                                children: [
                                                  _buildCell(contractData.contractNumber, contractData, Alignment.center),
                                                  _buildCell(contractData.summarySubjectContract, contractData, Alignment.centerLeft),
                                                  _buildCell(contractData.contractBiddingProcessNumber, contractData, Alignment.center),
                                                  TableCell(
                                                    child: PermissionIconDeleteButton(
                                                      tooltip: 'Apagar contrato',
                                                      currentUser: currentUser,
                                                      showConfirmDialog: true,
                                                      confirmTitle: 'Confirmar exclusão',
                                                      confirmContent: 'Deseja apagar este contrato?',
                                                      hasPermission: (user) => _contractsBloc.knowUserPermissionProfileAdm(
                                                        userData: user,
                                                        contract: contractData,
                                                      ),
                                                      onConfirmed: () async {
                                                        _deleteContract(contractData.id!);
                                                      },
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
                              onPressed: _isEditable ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => TabBarContractPage(),
                                  ),
                                );
                              } : null,
                              icon: Icon(_isEditable ? Icons.add : Icons.lock),
                              label: Text('Adicionar novo contrato', style: TextStyle(color: _isEditable ? Colors.blue : Colors.grey)),
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
                    items: _contractTypesStatus,
                    controller: _contractTypesStatusCtrl,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  width: 70,
                  height: 48,
                  child: TextButton(
                    onPressed: _clearFilters,
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
                          items: _contractTypesStatus,
                          controller: _contractTypesStatusCtrl,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        height: 48,
                        child: TextButton(
                          onPressed: _clearFilters,
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
