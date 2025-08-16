import 'package:flutter/material.dart';
import '../../../_blocs/documents/contracts/additives/additives_bloc.dart';
import '../../../_blocs/documents/contracts/apostilles/apostilles_bloc.dart';
import '../../../_blocs/documents/measurement/measurement_bloc.dart';
import '../../../_widgets/registers/register_class.dart';

class DebugNotificacoesPage extends StatefulWidget {
  const DebugNotificacoesPage({
    super.key,
  });


  @override
  State<DebugNotificacoesPage> createState() => _DebugNotificacoesPageState();
}

class _DebugNotificacoesPageState extends State<DebugNotificacoesPage> {
  late Future<List<Registro>> _futureRegistros;

  late final ReportsBloc measurementBloc = ReportsBloc();
  late final AdditivesBloc additivesBloc = AdditivesBloc();
  late final ApostillesBloc apostillesBloc = ApostillesBloc();

  @override
  void initState() {
    super.initState();
    _futureRegistros = _carregarNotificacoes();
  }

  Future<List<Registro>> _carregarNotificacoes() async {
    final registros = <Registro>[];


    registros.sort((a, b) => b.data.compareTo(a.data));
    return registros;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Notificações')),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<Registro>>(
        future: _futureRegistros,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final registros = snapshot.data ?? [];

          if (registros.isEmpty) {
            return const Center(child: Text('🔕 Nenhuma notificação encontrada.'));
          }

          return ListView.builder(
            itemCount: registros.length,
            itemBuilder: (context, index) {
              final r = registros[index];
              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(r.tipo),
                subtitle: Text(r.dataFormatada),
              );
            },
          );
        },
      ),
    );
  }
}
