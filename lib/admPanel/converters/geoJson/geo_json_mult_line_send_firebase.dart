import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'geo_json_mult_line_import.dart';
import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';

Future<void> GeoJsonSendFirebase(BuildContext context) async {
  final TextEditingController pathController = TextEditingController();

  final path = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Informe o caminho da coleção'),
      content: TextField(
        controller: pathController,
        decoration: const InputDecoration(
          labelText: 'Ex: actives_railways',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final p = pathController.text.trim();
            if (p.isNotEmpty) Navigator.pop(context, p);
          },
          child: const Text('Importar GeoJSON'),
        ),
      ],
    ),
  );

  if (!context.mounted || path == null || path.isEmpty) return;

  await GeoJsonImport.geoJsonImport(
    context: context,
    path: path,
    onSalvar: (linhasPrincipais, geometrias) async {
      // Despacha no BLoC da TELA (mesmo usado no Map/Panel)
      context.read<ActiveRailwaysBloc>().add(
        ActiveRailwaysImportBatchRequested(
          linhasPrincipais: linhasPrincipais,
          geometrias: geometrias,
        ),
      );
    },
    onFinished: () {
      if (!context.mounted) return;
      context.read<ActiveRailwaysBloc>().add(const ActiveRailwaysRefreshRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importação concluída. Atualizando ferrovias...')),
      );
    },
    maxJumpKm: 2.0, // mesmo threshold do verificador
  );
}
