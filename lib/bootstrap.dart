import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '_blocs/system/permission/permission_cubit.dart';
import 'firebase_options_flavors.dart';
import 'gate_page.dart';

import 'package:sipged/_services/files/dxf/map_overlay_cubit.dart';

import 'package:sipged/_services/my_location/nominatim_cubit.dart';
import 'package:sipged/_services/my_location/nominatim_geocoder.dart';
import 'package:sipged/_services/my_location/nominatim_repository.dart';

import 'package:sipged/_blocs/system/notification/notification_push.dart';
import 'package:sipged/_blocs/system/notification/bell/notification_bell_cubit.dart';
import 'package:sipged/_blocs/system/notification/local/notification_local_cubit.dart';
import 'package:sipged/_blocs/system/notification/preferences/notification_preferences_cubit.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_cubit.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_repository.dart';

import 'package:sipged/_blocs/system/tenant/tenant_cubit.dart';

import 'package:sipged/_blocs/system/setup/setup_cubit.dart';
import 'package:sipged/_blocs/system/login/login_cubit.dart';
import 'package:sipged/_blocs/system/login/login_repository.dart';
import 'package:sipged/_blocs/system/user/user_cubit.dart';
import 'package:sipged/_blocs/system/user/user_repository.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_cubit.dart';

import 'package:sipged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_repository.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_repository.dart';
import 'package:sipged/_blocs/modules/contracts/apostilles/apostilles_repository.dart';

import 'package:sipged/_blocs/modules/contracts/budget/budget_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/budget/budget_repository.dart';

import 'package:sipged/_blocs/modules/contracts/measurement/adjustment/adjustment_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/report/report_measurement_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/measurement/revision/revision_measurement_cubit.dart';

import 'package:sipged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/2Etp/etp_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/3Tr/tr_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/4Cotacao/cotacao_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/5Edital/edital_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/7Dotacao/dotacao_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/9Juridico/parecer_juridico_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_repository.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/11Arquivamento/termo_arquivamento_repository.dart';

import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_cubit.dart';
import 'package:sipged/_blocs/modules/operation/schedule/horizontal/schedule_road_repository.dart';

import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/infractions/infractions_cubit.dart';
import 'package:sipged/_blocs/modules/transit/infractions/infractions_repository.dart';

Future<void> _loadEnvIfNeeded() async {
  final shouldLoadEnv = !kIsWeb || !kReleaseMode;

  if (!shouldLoadEnv) return;

  try {
    await dotenv.load(fileName: '.env');
  } catch (e, s) {
    debugPrint('[Bootstrap] Falha ao carregar .env: $e');
    debugPrintStack(stackTrace: s);
  }
}

Future<void> _initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptionsFlavors.forWeb(),
    );
  } else {
    await Firebase.initializeApp();
  }
}

Future<void> _connectToEmulatorsIfNeeded() async {
  const useEmu = bool.fromEnvironment(
    'USE_EMULATOR',
    defaultValue: false,
  );

  if (!useEmu) return;

  const host = 'localhost';

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

Future<void> bootstrapAndRunApp() async {
  await runZonedGuarded<Future<void>>(
        () async {
      WidgetsFlutterBinding.ensureInitialized();

      Intl.defaultLocale = 'pt_BR';

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);

        if (details.stack != null) {
          debugPrintStack(
            label: details.exceptionAsString(),
            stackTrace: details.stack,
          );
        }
      };

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrint('[PlatformDispatcher] $error');
        debugPrintStack(stackTrace: stack);
        return true;
      };

      await _loadEnvIfNeeded();
      await initializeDateFormatting('pt_BR');
      await _initFirebase();

      if (!kIsWeb) {
        FirebaseMessaging.onBackgroundMessage(
          sipgedFirebaseMessagingBackgroundHandler,
        );
      }

      await _connectToEmulatorsIfNeeded();

      Provider.debugCheckInvalidValueType = null;

      runApp(
        MultiProvider(
          providers: [
            BlocProvider(
              create: (_) => PermissionCubit(),
            ),
            BlocProvider<MapOverlayCubit>(
              create: (_) => MapOverlayCubit(),
            ),

            BlocProvider<TenantCubit>(
              create: (_) => TenantCubit(),
            ),

            BlocProvider<SetupCubit>(
              create: (_) => SetupCubit(),
            ),

            RepositoryProvider<LoginRepository>(
              create: (_) => LoginRepository(),
            ),
            BlocProvider<LoginCubit>(
              create: (ctx) => LoginCubit(
                repository: ctx.read<LoginRepository>(),
              ),
            ),

            BlocProvider<NotificationPreferencesCubit>(
              create: (_) => NotificationPreferencesCubit(),
            ),

            BlocProvider<NotificationLocalCubit>(
              create: (_) => NotificationLocalCubit(
                maxVisible: 4,
              ),
            ),

            RepositoryProvider<NotificationRemoteRepository>(
              create: (_) => NotificationRemoteRepository(),
            ),
            BlocProvider<NotificationRemoteCubit>(
              create: (ctx) => NotificationRemoteCubit(
                repository: ctx.read<NotificationRemoteRepository>(),
              ),
            ),

            BlocProvider<NotificationBellCubit>(
              create: (ctx) => NotificationBellCubit(
                repository: ctx.read<NotificationRemoteRepository>(),
              ),
            ),

            RepositoryProvider<NominatimRepository>(
              create: (_) {
                const userAgent = 'sipged/1.0';

                return NominatimRepository(
                  userAgent: userAgent,
                  service: const NominatimGeocoder(
                    userAgent: userAgent,
                    acceptLanguage: 'pt-BR',
                    countryCodes: 'br',
                    defaultLimit: 8,
                  ),
                );
              },
            ),
            BlocProvider<NominatimCubit>(
              create: (ctx) => NominatimCubit(
                repository: ctx.read<NominatimRepository>(),
              ),
            ),

            RepositoryProvider<UserRepository>(
              create: (_) => UserRepository(),
            ),
            BlocProvider<UserCubit>(
              create: (ctx) => UserCubit(
                ctx.read<UserRepository>(),
              )..warmup(
                listenRealtime: true,
                bindCurrentUser: true,
              ),
            ),

            BlocProvider<ActiveOaesCubit>(
              create: (_) => ActiveOaesCubit()..warmup(),
            ),
            BlocProvider<ActiveRoadsCubit>(
              create: (_) => ActiveRoadsCubit()..warmup(),
            ),
            BlocProvider<AccidentsCubit>(
              create: (_) => AccidentsCubit(),
            ),

            RepositoryProvider<InfractionsRepository>(
              create: (_) => InfractionsRepository(),
            ),
            BlocProvider<InfractionsCubit>(
              create: (ctx) => InfractionsCubit(
                repository: ctx.read<InfractionsRepository>(),
              ),
            ),

            BlocProvider<ReportMeasurementCubit>(
              create: (_) => ReportMeasurementCubit(),
            ),

            BlocProvider<ValidityCubit>(
              create: (_) => ValidityCubit(
                repository: ValidityRepository(),
              ),
            ),

            RepositoryProvider<BudgetRepository>(
              create: (_) => BudgetRepository(),
            ),
            BlocProvider<BudgetCubit>(
              create: (ctx) => BudgetCubit(
                repository: ctx.read<BudgetRepository>(),
              ),
            ),

            BlocProvider<AdjustmentMeasurementCubit>(
              create: (_) => AdjustmentMeasurementCubit(),
            ),

            BlocProvider<RevisionMeasurementCubit>(
              create: (_) => RevisionMeasurementCubit(),
            ),

            RepositoryProvider<AdditivesRepository>(
              create: (_) => AdditivesRepository(),
            ),

            RepositoryProvider<ApostillesRepository>(
              create: (_) => ApostillesRepository(),
            ),

            RepositoryProvider<DfdRepository>(
              create: (_) => DfdRepository(),
            ),
            BlocProvider<DfdCubit>(
              create: (ctx) => DfdCubit(
                repository: ctx.read<DfdRepository>(),
              ),
            ),

            RepositoryProvider<PublicacaoExtratoRepository>(
              create: (_) => PublicacaoExtratoRepository(),
            ),
            BlocProvider<PublicacaoExtratoCubit>(
              create: (ctx) => PublicacaoExtratoCubit(
                ctx.read<PublicacaoExtratoRepository>(),
              ),
            ),

            RepositoryProvider<EditalRepository>(
              create: (_) => EditalRepository(),
            ),
            BlocProvider<EditalCubit>(
              create: (ctx) => EditalCubit(
                ctx.read<EditalRepository>(),
              ),
            ),

            RepositoryProvider<ProcessRepository>(
              create: (_) => ProcessRepository(),
            ),
            BlocProvider<ProcessCubit>(
              create: (ctx) => ProcessCubit(
                repository: ctx.read<ProcessRepository>(),
              ),
            ),

            BlocProvider<GeneralDashboardCubit>(
              create: (ctx) => GeneralDashboardCubit(
                processCubit: ctx.read<ProcessCubit>(),
                additivesRepository: ctx.read<AdditivesRepository>(),
                apostillesRepository: ctx.read<ApostillesRepository>(),
                reportMeasurementCubit: ctx.read<ReportMeasurementCubit>(),
                adjustmentMeasurementCubit:
                ctx.read<AdjustmentMeasurementCubit>(),
                revisionMeasurementCubit: ctx.read<RevisionMeasurementCubit>(),
                dfdCubit: ctx.read<DfdCubit>(),
                editalCubit: ctx.read<EditalCubit>(),
              )..initialize(),
            ),

            RepositoryProvider<ScheduleRoadRepository>(
              create: (_) => ScheduleRoadRepository(),
            ),
            BlocProvider<ScheduleRoadCubit>(
              create: (ctx) => ScheduleRoadCubit(
                repository: ctx.read<ScheduleRoadRepository>(),
              ),
            ),

            RepositoryProvider<EtpRepository>(
              create: (_) => EtpRepository(),
            ),
            BlocProvider<EtpCubit>(
              create: (ctx) => EtpCubit(
                ctx.read<EtpRepository>(),
              ),
            ),

            RepositoryProvider<TrRepository>(
              create: (_) => TrRepository(),
            ),
            BlocProvider<TrCubit>(
              create: (ctx) => TrCubit(
                ctx.read<TrRepository>(),
              ),
            ),

            RepositoryProvider<CotacaoRepository>(
              create: (_) => CotacaoRepository(),
            ),
            BlocProvider<CotacaoCubit>(
              create: (ctx) => CotacaoCubit(
                ctx.read<CotacaoRepository>(),
              ),
            ),

            RepositoryProvider<HabilitacaoRepository>(
              create: (_) => HabilitacaoRepository(),
            ),
            BlocProvider<HabilitacaoCubit>(
              create: (ctx) => HabilitacaoCubit(
                ctx.read<HabilitacaoRepository>(),
              ),
            ),

            RepositoryProvider<DotacaoRepository>(
              create: (_) => DotacaoRepository(),
            ),
            BlocProvider<DotacaoCubit>(
              create: (ctx) => DotacaoCubit(
                ctx.read<DotacaoRepository>(),
              ),
            ),

            RepositoryProvider<MinutaContratoRepository>(
              create: (_) => MinutaContratoRepository(),
            ),
            BlocProvider<MinutaContratoCubit>(
              create: (ctx) => MinutaContratoCubit(
                ctx.read<MinutaContratoRepository>(),
              ),
            ),

            RepositoryProvider<ParecerJuridicoRepository>(
              create: (_) => ParecerJuridicoRepository(),
            ),
            BlocProvider<ParecerJuridicoCubit>(
              create: (ctx) => ParecerJuridicoCubit(
                ctx.read<ParecerJuridicoRepository>(),
              ),
            ),

            RepositoryProvider<TermoArquivamentoRepository>(
              create: (_) => TermoArquivamentoRepository(),
            ),
            BlocProvider<TermoArquivamentoCubit>(
              create: (ctx) => TermoArquivamentoCubit(
                ctx.read<TermoArquivamentoRepository>(),
              ),
            ),
          ],
          builder: (context, _) {
            return const GatePage();
          },
        ),
      );
    },
        (Object error, StackTrace stack) {
      debugPrint('[ZoneGuarded] $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}