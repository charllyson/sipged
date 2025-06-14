import 'package:flutter/material.dart';
import '../../../_blocs/system/system_bloc.dart';
import '../../../_datas/system/system_data.dart';
import 'manager_diretoria_page.dart';

class ManageOrgansPage extends StatefulWidget {
  const ManageOrgansPage({super.key});

  @override
  _ManageOrgansPageState createState() => _ManageOrgansPageState();
}

class _ManageOrgansPageState extends State<ManageOrgansPage> {
  final SystemBloc systemBloc = SystemBloc();
  late Future<List<SystemData>> _futureOrgans;

  @override
  void initState() {
    super.initState();
    _futureOrgans = systemBloc.loadOrgans();
  }

  void createOrgao() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Criar Órgão"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: "Sigla do Órgão"),
            autofocus: true,
            onSubmitted: (_) async {
              final value = _controller.text.trim();
              if (value.isNotEmpty) {
                await systemBloc.createOrgan(value);
                Navigator.pop(context);
                setState(() {
                  _futureOrgans = systemBloc.loadOrgans();
                });
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final value = _controller.text.trim();
                if (value.isNotEmpty) {
                  await systemBloc.createOrgan(value);
                  Navigator.pop(context);
                  setState(() {
                    _futureOrgans = systemBloc.loadOrgans();
                  });
                }
              },
              child: const Text('Criar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Gerenciar Órgãos'),
        ),
        body: FutureBuilder<List<SystemData>>(
          future: _futureOrgans,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Erro ao carregar órgãos'));
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Órgãos",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      SystemData systemData = snapshot.data![index];
                      return ListTile(
                        title: Text(snapshot.data![index].acronymOrgan ?? ''),
                        leading: const Icon(Icons.business),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageDirectorsPage(
                                idOrgan: systemData.idOrgan!,
                                acronymOrgan: systemData.acronymOrgan!,
                              ),
                            ),
                          );
                        },
                        trailing: const Icon(Icons.arrow_forward),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: createOrgao,
          label: const Text('Criar Órgão'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
