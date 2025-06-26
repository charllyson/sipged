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

  String? _lastSortedStatus;
  String Function(ContractData)? _lastSortField;
  final Map<String, List<ContractData>> _cachedContractsByStatus = {};

  final _contractTypesStatusCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  Future<List<ContractData>>? _futureContracts;

  bool _isEditable = false;
  int? _sortColumnIndex;
  bool _isAscending = true;

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
        setState(() {});
      }
    });
  }

  bool isDisabled(String module) {
    final perms = _currentUser?.modulePermissions[module] ?? {};
    return !(perms['create'] ?? false || (perms['edit'] ?? false));
  }

  void _applyFilters() {
    _cachedContractsByStatus.clear(); // força o recarregamento dos dados filtrados
    setState(() {});
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _contractTypesStatusCtrl.clear();
    _applyFilters();
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 80, bottom: 16.0),
                          child: _buildFilters(constraints),
                        ),
                        _getContractStatus(currentUser, constraints, '🚜 Em Andamento', 'EM ANDAMENTO'),
                        _getContractStatus(currentUser, constraints, '✅ Concluídos', 'CONCLUÍDO'),
                        _getContractStatus(currentUser, constraints, '⏳ A Iniciar', 'A INICIAR'),
                        _getContractStatus(currentUser, constraints, '🚫 Paralisados', 'PARALISADO'),
                        _getContractStatus(currentUser, constraints, '❌ Cancelados', 'CANCELADO'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextButton.icon(
                                onPressed: _isEditable ? () async {
                                  final result = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TabBarContractPage(),
                                    ),
                                  );

                                  if (result == true && _currentUser != null) {
                                    setState(() {
                                      _futureContracts = _contractsBloc.getFilteredContracts(currentUser: _currentUser!);
                                    });
                                  }
                                } : null,
                                icon: Icon(_isEditable ? Icons.add : Icons.lock),
                                label: Text('Adicionar novo contrato', style: TextStyle(color: _isEditable ? Colors.blue : Colors.grey)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildSortableHeader(String title, int columnIndex, String Function(ContractData) fieldGetter, String statusFilter) {
    _cachedContractsByStatus.remove(statusFilter);
    return Tooltip(
      message: 'Ordenar por $title',
      child: InkWell(
        onTap: () {
          setState(() {
            _sortColumnIndex = columnIndex;
            _isAscending = !_isAscending;
            _lastSortedStatus = statusFilter;
            _lastSortField = fieldGetter;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(width: 20),
              if (_sortColumnIndex == columnIndex && _lastSortedStatus == statusFilter)
                Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 16, color: Colors.indigoAccent),
              if (_lastSortedStatus != statusFilter)
              Icon(Icons.filter_list, size: 16, color: Colors.indigoAccent)
            ],
          ),
        ),
      ),
    );
  }

  Widget _getContractStatus(
      currentUser,
      BoxConstraints constraints,
      String? status,
      String? statusFilter,
      ) {
    return FutureBuilder<List<ContractData>>(
      future: _cachedContractsByStatus[statusFilter] != null
          ? Future.value(_cachedContractsByStatus[statusFilter])
          : _contractsBloc.getFilteredContracts(
        currentUser: currentUser,
        statusFilter: _contractTypesStatusCtrl.text.isNotEmpty
            ? _contractTypesStatusCtrl.text
            : statusFilter,
        searchQuery: _searchCtrl.text.trim(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        } else if (snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text('$status - (Nenhum)', style: const TextStyle(fontSize: 20)),
          );
        } else {
          final contracts = List<ContractData>.from(snapshot.data!);

          // Salva no cache se ainda não estiver
          _cachedContractsByStatus[statusFilter!] ??= contracts;

          // Ordena somente se a coluna correspondente for clicada
          if (_lastSortedStatus == statusFilter &&
              _sortColumnIndex != null &&
              _lastSortField != null) {
            contracts.sort((a, b) {
              final aValue = _lastSortField!(a).toLowerCase();
              final bValue = _lastSortField!(b).toLowerCase();
              return _isAscending ? aValue.compareTo(bValue) : bValue.compareTo(aValue);
            });
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
                  child: Text('$status - (${contracts.length}) Contratos', style: const TextStyle(fontSize: 20)),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Table(
                    border: TableBorder.all(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade300,
                    ),
                    columnWidths: const {
                      0: FixedColumnWidth(130),
                      1: FixedColumnWidth(350),
                      2: FixedColumnWidth(200),
                      3: FixedColumnWidth(150),
                      4: FixedColumnWidth(200),
                      5: FixedColumnWidth(100),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Colors.white),
                        children: [
                          _buildSortableHeader('CONTRATO', 0, (c) => c.contractNumber ?? '', statusFilter),
                          _buildSortableHeader('OBRA', 3, (c) => c.summarySubjectContract ?? '', statusFilter),
                          _buildSortableHeader('REGIÃO', 1, (c) => c.regionOfState ?? '', statusFilter),
                          _buildSortableHeader('SERVIÇOS', 2, (c) => c.contractServices ?? '', statusFilter),
                          _buildSortableHeader('Nº PROCESSO', 4, (c) => c.contractNumberProcess ?? '', statusFilter),
                          const Center(child: Padding(padding: EdgeInsets.all(8), child: Text('APAGAR', style: TextStyle(fontWeight: FontWeight.bold)))),
                        ],
                      ),
                      ...contracts.map((contractData) {
                        return TableRow(
                          decoration: const BoxDecoration(color: Colors.white),
                          children: [
                            _buildCell(contractData.contractNumber, contractData, Alignment.center),
                            _buildCell(contractData.summarySubjectContract, contractData, Alignment.centerLeft),
                            _buildCell(contractData.regionOfState, contractData, Alignment.center),
                            _buildCell(contractData.contractServices, contractData, Alignment.center),
                            _buildCell(contractData.contractNumberProcess, contractData, Alignment.center),
                            TableCell(
                              child: PermissionIconDeleteButton(
                                tooltip: 'Apagar contrato',
                                currentUser: currentUser,
                                showConfirmDialog: true,
                                confirmTitle: 'Confirmar exclusão',
                                confirmContent: 'Deseja apagar este contrato?',
                                hasPermission: (user) =>
                                    _contractsBloc.knowUserPermissionProfileAdm(userData: user, contract: contractData),
                                onConfirmed: () async {
                                  _deleteContract(contractData.id!);
                                },
                              ),
                            )
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildFilters(BoxConstraints constraints) {
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
                      if (event.isKeyPressed(LogicalKeyboardKey.enter)) _applyFilters();
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
                    onPressed: _applyFilters,
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
                    onChanged: (_) => _applyFilters(),
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
                            if (event.isKeyPressed(LogicalKeyboardKey.enter)) _applyFilters();
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
                          onPressed: _applyFilters,
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
                          onChanged: (_) => _applyFilters(),
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
      verticalAlignment: TableCellVerticalAlignment.middle,
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
              textAlign: alignment == Alignment.centerLeft ? TextAlign.left : TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}
