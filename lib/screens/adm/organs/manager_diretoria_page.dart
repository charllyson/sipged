import 'package:flutter/material.dart';
import 'package:sisgeo/_datas/system/system_data.dart';
import 'package:sisgeo/_blocs/system/system_bloc.dart';
import 'manager_setor_page.dart';

class ManageDirectorsPage extends StatefulWidget {
  final String idOrgan;
  final String acronymOrgan;
  const ManageDirectorsPage({
    super.key,
    required this.idOrgan,
    required this.acronymOrgan,
  });

  @override
  _ManageDirectorsPageState createState() => _ManageDirectorsPageState();
}

class _ManageDirectorsPageState extends State<ManageDirectorsPage> {
  final SystemBloc systemBloc = SystemBloc();
  late Future<List<SystemData>> _futureDirectors;

  @override
  void initState() {
    super.initState();
    _futureDirectors = systemBloc.loadDirectors(widget.idOrgan);
  }

  void createDiretoria() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Criar Diretoria"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: "Sigla da Diretoria"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final value = _controller.text.trim();
                if (value.isNotEmpty) {
                  await systemBloc.createDirectors(
                    idOrgan: widget.idOrgan,
                    acronymDirectors: value,
                  );
                  Navigator.pop(context);
                  setState(() {
                    _futureDirectors = systemBloc.loadDirectors(widget.idOrgan);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Diretorias do Órgão: ${widget.acronymOrgan}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _futureDirectors = systemBloc.loadDirectors(widget.idOrgan);
              });
            },
          )
        ],
      ),
      body: FutureBuilder<List<SystemData>>(
        future: _futureDirectors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar diretorias'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma diretoria encontrada'));
          }

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              return Card(
                child: ListTile(
                  title: Text(item.acronymDirectors ?? ''),
                  leading: const Icon(Icons.account_tree),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageSectorPage(
                          idDirectors: item.idDirectors!,
                          acronymDirectors: item.acronymDirectors ?? '',
                          idOrgan: widget.idOrgan,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createDiretoria,
        label: const Text('Criar Diretoria'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
