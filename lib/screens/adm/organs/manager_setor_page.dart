import 'package:flutter/material.dart';
import 'package:sisgeo/_blocs/system/system_bloc.dart';
import 'package:sisgeo/_datas/system/system_data.dart';

class ManageSectorPage extends StatefulWidget {
  final String idOrgan;
  final String idDirectors;
  final String acronymDirectors;

  const ManageSectorPage({
    super.key,
    required this.idOrgan,
    required this.idDirectors,
    required this.acronymDirectors,
  });

  @override
  _ManageSectorPageState createState() => _ManageSectorPageState();
}

class _ManageSectorPageState extends State<ManageSectorPage> {
  final SystemBloc systemBloc = SystemBloc();
  late Future<List<SystemData>> _futureSectors;

  @override
  void initState() {
    super.initState();
    _futureSectors = systemBloc.loadSectors(
      idOrgan: widget.idOrgan,
      idDirectors: widget.idDirectors,
    );
  }

  void createSetor() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Criar Setor"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: "Sigla do Setor"),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final value = _controller.text.trim();
                if (value.isNotEmpty) {
                  await systemBloc.createSector(
                    idOrgan: widget.idOrgan,
                    idDirectors: widget.idDirectors,
                    acronymSectors: value,
                  );
                  Navigator.pop(context);
                  setState(() {
                    _futureSectors = systemBloc.loadSectors(
                      idOrgan: widget.idOrgan,
                      idDirectors: widget.idDirectors,
                    );
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
        title: Text('Setores da Diretoria: ${widget.acronymDirectors}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _futureSectors = systemBloc.loadSectors(
                  idOrgan: widget.idOrgan,
                  idDirectors: widget.idDirectors,
                );
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SystemData>>(
        future: _futureSectors,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar setores'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum setor encontrado'));
          }

          final setores = snapshot.data!;
          return ListView.builder(
            itemCount: setores.length,
            itemBuilder: (context, index) {
              final setor = setores[index];
              return Card(
                child: ListTile(
                  title: Text(setor.acronymSectors ?? ''),
                  leading: const Icon(Icons.apartment),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Pode adicionar ação para editar setor ou ver detalhes
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createSetor,
        label: const Text('Criar Setor'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
