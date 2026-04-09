import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/map/map_cubit.dart';
import 'package:sipged/_blocs/modules/planning/geo/toolbox/toolbox_cubit.dart';
import 'package:sipged/screens/modules/planning/geo/geo_network_view.dart';

class GeoNetworkPage extends StatelessWidget {
  const GeoNetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final geoLayersRepository = LayerRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ToolboxCubit()),
        BlocProvider(
          create: (_) => LayerCubit(
            repository: geoLayersRepository,
          )..load(),
        ),
        BlocProvider(
          create: (_) => FeatureCubit(
            repository: FeatureRepository(),
          ),
        ),
        BlocProvider(
          create: (context) => MapCubit(
            layersCubit: context.read<LayerCubit>(),
            featureCubit: context.read<FeatureCubit>(),
            toolboxCubit: context.read<ToolboxCubit>(),
          ),
        ),
      ],
      child: const GeoNetworkView(),
    );
  }
}