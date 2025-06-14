import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sisgeo/_blocs/contracts/contracts_bloc.dart';
import 'package:sisgeo/_blocs/system/system_bloc.dart';
import 'package:sisgeo/_datas/system/system_data.dart';
import 'package:sisgeo/_datas/user/user_data.dart';
import '../../../_blocs/user/user_bloc.dart';
import '../../../_models/user/user_model.dart';

class ManagePermissionsPage extends StatefulWidget {
  const ManagePermissionsPage({super.key});

  @override
  _ManagePermissionsPageState createState() => _ManagePermissionsPageState();
}

class _ManagePermissionsPageState extends State<ManagePermissionsPage> {
  final _systemBloc = SystemBloc();
  final _userBloc = UserBloc();
  late UserData userData = UserData();

  late Future<List<SystemData>> _futurePermissions;
  List<SystemData> _currentOrgans = [];

  @override
  void initState() {
    super.initState();
    _futurePermissions = _loadAllWithPermissions();
    userData = Provider.of<UserProvider>(context, listen: false).userData!;
  }


  Future<List<SystemData>> _loadAllWithPermissions() async {
    final permissions = await _userBloc.getUserPermissions(userId: userData.id!);
    final permissionOrg = List<String>.from(permissions['permissionOrgan'] ?? []);
    final permissionDir = List<String>.from(permissions['permissionDirector'] ?? []);
    final permissionSec = List<String>.from(permissions['permissionSector'] ?? []);

    final organs = await _systemBloc.loadOrgans();

    for (final organ in organs) {
      organ.isSelectedOrgan = permissionOrg.contains(organ.idOrgan);
      organ.directors = await _systemBloc.loadDirectors(organ.idOrgan ?? '');
      for (final dir in organ.directors!) {
        dir.isSelectedDirector = permissionDir.contains(dir.idDirectors);
        dir.sectors = await _systemBloc.loadSectors(
          idOrgan: organ.idOrgan ?? '',
          idDirectors: dir.idDirectors ?? '',
        );
        for (final sec in dir.sectors!) {
          sec.isSelectedSector = permissionSec.contains(sec.idSector);
        }
      }
    }

    return organs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Permissões: ${userData.name}'),
      ),
      body: FutureBuilder<List<SystemData>>(
        future: _futurePermissions,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          _currentOrgans = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: _currentOrgans.map((organ) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    title: Text("Órgão: ${organ.acronymOrgan ?? ''}"),
                    value: organ.isSelectedOrgan,
                    onChanged: (value) {
                      setState(() => organ.isSelectedOrgan = value ?? false);
                    },
                  ),
                  ...?organ.directors?.map((dir) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: CheckboxListTile(
                          title: Text("Diretoria: ${dir.acronymDirectors ?? ''}"),
                          value: dir.isSelectedDirector,
                          onChanged: (value) {
                            setState(() => dir.isSelectedDirector = value ?? false);
                          },
                        ),
                      ),
                      ...?dir.sectors?.map((sec) => Padding(
                        padding: const EdgeInsets.only(left: 32.0),
                        child: CheckboxListTile(
                          title: Text("Setor: ${sec.acronymSectors ?? ''}"),
                          value: sec.isSelectedSector,
                          onChanged: (value) {
                            setState(() => sec.isSelectedSector = value ?? false);
                          },
                        ),
                      )),
                    ],
                  )),
                ],
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final List<String> selectedOrgans = [];
          final List<String> selectedDirectors = [];
          final List<String> selectedSectors = [];

          for (final organ in _currentOrgans) {
            if (organ.isSelectedOrgan && organ.idOrgan != null) {
              selectedOrgans.add(organ.idOrgan!);
            }

            for (final dir in organ.directors ?? []) {
              if (dir.isSelectedDirector && dir.idDirectors != null) {
                selectedDirectors.add(dir.idDirectors!);
              }

              for (final sec in dir.sectors ?? []) {
                if (sec.isSelectedSector && sec.idSector != null) {
                  selectedSectors.add(sec.idSector!);
                }
              }
            }
          }

          await _userBloc.savePermissions(
            userId: userData.id!,
            permissionOrgan: selectedOrgans,
            permissionDirector: selectedDirectors,
            permissionSector: selectedSectors,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissões salvas com sucesso')),
          );
        },
        label: const Text('Salvar Permissões'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
