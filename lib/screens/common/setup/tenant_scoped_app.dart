import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';
import 'package:sipged/screens/modules/contracts/measurement/gallery/photo_gallery_page.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';
import 'package:sipged/screens/menus/menu_list_page.dart';

class TenantScopedApp extends StatelessWidget {
  const TenantScopedApp({super.key,
    required this.tenantId,
  });

  final String tenantId;

  @override
  Widget build(BuildContext context) {
    final cleanTenantId = tenantId.trim();

    if (cleanTenantId.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: LoadingTreeDots(
          message: Text('Empresa não selecionada...'),
        ),
      );
    }

    return MultiRepositoryProvider(
      key: ValueKey<String>('tenant-repositories-$cleanTenantId'),
      providers: [
        RepositoryProvider<DfdRepository>(
          create: (_) => DfdRepository(
            tenantId: cleanTenantId,
          ),
        ),
      ],
      child: MultiBlocProvider(
        key: ValueKey<String>('tenant-blocs-$cleanTenantId'),
        providers: [
          BlocProvider<DfdCubit>(
            create: (ctx) => DfdCubit(
              tenantId: cleanTenantId,
              repository: ctx.read<DfdRepository>(),
            ),
          ),
        ],
        child: const MenuListPage(),
      ),
    );
  }
}
