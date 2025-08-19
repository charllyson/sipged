/*
import '../_blocs/measurementSection/report_measurement_bloc.dart';
import '../_blocs/additives/additives_bloc.dart';
import '../_blocs/apostilles/apostilles_bloc.dart';
import '../_class/registers/register_class.dart';

Future<List<Registro>> getNotificacoesRecentesDoSistema({
  required MeasurementBloc measurementBloc,
  required AdditivesBloc additivesBloc,
  required ApostillesBloc apostillesBloc,
}) async {
  final registros = <Registro>[
    ...await measurementBloc.getNotificacoesRecentes(),
    ...await additivesBloc.getNotificacoesRecentes(),
    ...await apostillesBloc.getNotificacoesRecentes(),
    ...await validityBloc.getNotificacoesRecentes(),
  ];

  registros.sort((a, b) => b.data.compareTo(a.data));
  return registros.take(10).toList();
}
*/
