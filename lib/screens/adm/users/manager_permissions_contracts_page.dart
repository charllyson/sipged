import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/user/user_bloc.dart';
import 'package:sisgeo/_datas/user/user_data.dart';
import '../../commons/contracts/tab_bar_contract_page.dart';

class ManagerPermissionsContractsPage extends StatefulWidget {
  const ManagerPermissionsContractsPage({super.key});

  @override
  State<ManagerPermissionsContractsPage> createState() => _ManagerPermissionsContractsPageState();
}

class _ManagerPermissionsContractsPageState extends State<ManagerPermissionsContractsPage> {
  late final UserBloc _userBloc = UserBloc();


  /*void _savePermissions(String contractDocId, String permissionType, bool value) {
    // Atualiza a permissão no UserData localmente
    contractData.updateContractPermissions(contractDocId, permissionType, value);

    // Se a permissão de leitura for desmarcada, desmarque 'edit' e 'delete'
    if (permissionType == 'read' && !value) {
      contractData.updateContractPermissions(contractDocId, 'edit', false);
      contractData.updateContractPermissions(contractDocId, 'delete', false);
    }

    // Se a permissão de edição for desmarcada, desmarque 'read' também
    if (permissionType == 'edit' && !value) {
      contractData.updateContractPermissions(contractDocId, 'read', false);
      contractData.updateContractPermissions(contractDocId, 'delete', false);
    }

    // Se a permissão de apagar for desmarcada, desmarque 'edit' e 'read'
    if (permissionType == 'delete' && !value) {
      contractData.updateContractPermissions(contractDocId, 'edit', false);
      contractData.updateContractPermissions(contractDocId, 'read', false);
    }

    // Se a permissão de apagar for marcada, marque 'edit' e 'read'
    if (permissionType == 'delete' && value) {
      contractData.updateContractPermissions(contractDocId, 'edit', true);
      contractData.updateContractPermissions(contractDocId, 'read', true);
    }

    // Se a permissão de edição for marcada, marque 'read' também
    if (permissionType == 'edit' && value) {
      contractData.updateContractPermissions(contractDocId, 'read', true);
    }

    // Chama o UserBloc para atualizar as permissões no Firestore
    _contractsBloc.updateContractPermissions(
        contractData.id!,
        contractDocId, // Usando o ID do documento do contrato
        permissionType,
        value
    );

    // Sincroniza as permissões de leitura e edição automaticamente com base nas alterações
    if (permissionType == 'edit') {
      _contractsBloc.updateContractPermissions(
          contractData.id!,
          contractDocId,
          'read', // Se editar for marcado, automaticamente 'read' é marcado
          value
      );
    }

    if (permissionType == 'delete') {
      _contractsBloc.updateContractPermissions(
          contractData.id!,
          contractDocId,
          'edit', // Se apagar for marcado, automaticamente 'edit' é marcado
          value
      );
      _contractsBloc.updateContractPermissions(
          contractData.id!,
          contractDocId,
          'read', // Se apagar for marcado, automaticamente 'read' é marcado
          value
      );
    }
  }*/




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
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
                          'Gerenciar permissões do usuário no sistema',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FutureBuilder<List<UserData>>(
                          future: _userBloc.getAllUsers(context),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text('Erro: ${snapshot.error}'));
                            } else {
                              final users = snapshot.data!;
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
                                      0: FixedColumnWidth(150), // CONTRATO
                                      1: FixedColumnWidth(300), // OBRA
                                      2: FixedColumnWidth(80), // Nº PROCESSO
                                      3: FixedColumnWidth(80),
                                      4: FixedColumnWidth(80),
                                    },
                                    children: [
                                      const TableRow(
                                        decoration: BoxDecoration(color: Colors.white),
                                        children: [
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('FOTO', style: TextStyle(fontWeight: FontWeight.bold)))),
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('NOME', style: TextStyle(fontWeight: FontWeight.bold)))),
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('LER', style: TextStyle(fontWeight: FontWeight.bold)))),
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('EDITAR', style: TextStyle(fontWeight: FontWeight.bold)))),
                                          Center(child: Padding(padding: EdgeInsets.all(8), child: Text('APAGAR', style: TextStyle(fontWeight: FontWeight.bold)))),
                                        ],
                                      ),
                                      ...users.map(
                                            (users) => TableRow(
                                          decoration: const BoxDecoration(color: Colors.white),
                                          children: [
                                            _buildCell(users.urlPhoto, Alignment.center),
                                            _buildCell('${users.name} ${users.surname}', Alignment.centerLeft),
                                            _buildCheckboxCell(users.id!, 'read'),
                                            _buildCheckboxCell(users.id!, 'edit'),
                                            _buildCheckboxCell(users.id!, 'delete'),
                                          ],
                                        ),
                                      )
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
      ),
    );
  }

  Widget _buildCell(
      String? text,
      Alignment alignment) {
    return TableCell(
      child: InkWell(
        onTap: (){
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

  Widget _buildCheckboxCell(String contractDocId, String permissionType) {
    return TableCell(
      child: Align(
        alignment: Alignment.center,
        child: CheckboxListTile(
          value: false,
          onChanged: (value) {
            if (value != null) {
            }
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    );
  }

}
