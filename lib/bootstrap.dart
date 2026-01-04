// lib/bootstrap.dart
import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Firestore/Auth/Storage (emuladores)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:siged/_blocs/actives/oacs/active_oacs_cubit.dart';

import '_blocs/process/budget/budget_cubit.dart';
import '_blocs/process/budget/budget_repository.dart';
import '_blocs/process/measurement/adjustment/adjustments_measurement_cubit.dart';
import 'firebase_options_flavors.dart';

// ===== Cubits / BLoCs de mapa / ativos =====
import 'package:siged/_services/dxf/map_overlay_cubit.dart';

import 'package:siged/_blocs/actives/roads/active_roads_cubit.dart';
import 'package:siged/_blocs/actives/railway/active_railways_cubit.dart';

// ✅ OAEs em Cubit
import 'package:siged/_blocs/actives/oaes/active_oaes_cubit.dart';

// ===== Painéis / Dashboards =====
import 'package:siged/_blocs/panels/general_dashboard/general_dashboard_cubit.dart';

// ===== Processos: ajustes, revisões, relatórios (NOVOS CUBITS) =====
import 'package:siged/_blocs/process/measurement/revision/revision_measurement_cubit.dart';
import 'package:siged/_blocs/process/measurement/report/report_measurement_cubit.dart';

// ===== Processos: validades =====
import 'package:siged/_blocs/process/validity/validity_cubit.dart';
import 'package:siged/_blocs/process/validity/validity_repository.dart';

// ===== Processos: aditivos =====
import 'package:siged/_blocs/process/additives/additives_repository.dart';

// ✅ Apostilamentos (NOVO PADRÃO: Repository; Cubit é criado na página)
import 'package:siged/_blocs/process/apostilles/apostilles_repository.dart';

// ===== Processos: base de contratos =====
import 'package:siged/_blocs/_process/process_bloc.dart';
import 'package:siged/_blocs/_process/process_store.dart';

// ===== Processos: cronograma =====
import 'package:siged/_blocs/sectors/operation/road/schedule_road_cubit.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';

// ===== Processos: física / financeira =====
import 'package:siged/_blocs/process/phys_fin/physics_finance_store.dart';

// ===== Setores financeiros: pagamentos =====
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payment_reports_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';

// ===== Setor trânsito: acidentes / infrações =====
import 'package:siged/_blocs/sectors/transit/accidents/accidents_cubit.dart';
import 'package:siged/_blocs/sectors/transit/infractions/infractions_bloc.dart';
import 'package:siged/_blocs/sectors/transit/infractions/infractions_controller.dart';

// ===== Sistema / Usuário / Login =====
import 'package:siged/_blocs/system/login/login_bloc.dart';
import 'package:siged/_services/nominatim/nominatim_bloc.dart';
import 'package:siged/_blocs/system/user/user_repository.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

// ===== Módulos de contratação (DFD, ETP, TR, etc.) =====
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_cubit.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

import 'package:siged/_blocs/process/hiring/2Etp/etp_cubit.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_repository.dart';

import 'package:siged/_blocs/process/hiring/3Tr/tr_cubit.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_repository.dart';

import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_cubit.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_repository.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_cubit.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_repository.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_cubit.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_repository.dart';

import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_cubit.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_repository.dart';

import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_cubit.dart';
import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_repository.dart';

import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_cubit.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_repository.dart';

import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_repository.dart';

import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_cubit.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_repository.dart';

// ===== Setup =====
import 'package:siged/_blocs/system/setup/setup_cubit.dart';

// ===== GatePage / raiz da aplicação =====
import 'package:siged/gate_page.dart';

Future<void> _initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(options: FirebaseOptionsFlavors.forWeb());
  } else {
    await Firebase.initializeApp();
  }
}

/// Conecta nos Emuladores quando compilado com --dart-define=USE_EMULATOR=true
Future<void> _connectToEmulatorsIfNeeded() async {
  const useEmu = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
  if (!useEmu) return;

  const host = 'localhost';
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseStorage.instance.useStorageEmulator(host, 9199);
}

Future<void> bootstrapAndRunApp() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      if (kIsWeb) {
        // ignore: unused_local_variable
        final s = details.stack;
        return;
      }
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      // Log global opcional
      return true;
    };

    await initializeDateFormatting('pt_BR');
    await _initFirebase();
    await _connectToEmulatorsIfNeeded();

    Provider.debugCheckInvalidValueType = null;

    runApp(
      MultiProvider(
        providers: [
          // ========= Cubits/BLoCs auxiliares =========
          BlocProvider<MapOverlayCubit>(create: (_) => MapOverlayCubit()),

          BlocProvider<SetupCubit>(
            create: (_) => SetupCubit()..loadCompanies(),
          ),

          // --------- BLoCs / services básicos ---------
          Provider<LoginBloc>(
            create: (_) => LoginBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          Provider<NominatimBloc>(
            create: (_) => NominatimBloc(),
            dispose: (_, b) => b.dispose(),
          ),

          /// ======= User =======
          Provider<UserRepository>(create: (_) => UserRepository()),
          BlocProvider<UserBloc>(
            create: (ctx) => UserBloc(ctx.read<UserRepository>())
              ..add(const UserWarmupRequested(
                listenRealtime: true,
                bindCurrentUser: true,
              )),
          ),

          /// ======= OAEs / Rodovias / Ferrovias =======
          BlocProvider<ActiveOaesCubit>(
            create: (_) => ActiveOaesCubit()..warmup(),
          ),
          BlocProvider<ActiveOacsCubit>(
            create: (_) => ActiveOacsCubit()..warmup(),
          ),
          BlocProvider<ActiveRoadsCubit>(
            create: (_) => ActiveRoadsCubit()..warmup(),
          ),
          BlocProvider<ActiveRailwaysCubit>(
            create: (_) => ActiveRailwaysCubit()..warmup(),
          ),

          // ======= Acidentes / Infrações =======
          BlocProvider<AccidentsCubit>(
            create: (_) => AccidentsCubit(),
          ),
          Provider<InfractionsBloc>(
            create: (_) => InfractionsBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProxyProvider<InfractionsBloc, InfractionsController>(
            create: (ctx) => InfractionsController(
              bloc: ctx.read<InfractionsBloc>(),
            ),
            update: (_, iBloc, ctrl) => ctrl!..updateDeps(iBloc),
          ),

          /// ======= REPORT MEASUREMENT (CUBIT) =======
          BlocProvider<ReportMeasurementCubit>(
            create: (_) => ReportMeasurementCubit(),
          ),

          /// ======= VALIDITY =======
          BlocProvider<ValidityCubit>(
            create: (_) => ValidityCubit(
              repository: ValidityRepository(),
            ),
          ),

          /// ======= BUDGET (NOVO PADRÃO: Repository + Cubit) =======
          RepositoryProvider<BudgetRepository>(
            create: (_) => BudgetRepository(),
          ),
          BlocProvider<BudgetCubit>(
            create: (ctx) => BudgetCubit(
              repository: ctx.read<BudgetRepository>(),
            ),
          ),


          /// ======= ADJUSTMENT MEASUREMENT (CUBIT) =======
          BlocProvider<AdjustmentMeasurementCubit>(
            create: (_) => AdjustmentMeasurementCubit(),
          ),

          /// ======= REVISION MEASUREMENT (CUBIT) =======
          BlocProvider<RevisionMeasurementCubit>(
            create: (_) => RevisionMeasurementCubit(),
          ),

          /// ======= ADDITIVES (Repository global) =======
          RepositoryProvider<AdditivesRepository>(
            create: (_) => AdditivesRepository(),
          ),

          /// ======= APOSTILLES (NOVO: Repository global; Cubit é local na página) =======
          RepositoryProvider<ApostillesRepository>(
            create: (_) => ApostillesRepository(),
          ),

          // ======= DFD (repositório + cubit) – antes do Dashboard =======
          RepositoryProvider<DfdRepository>(create: (_) => DfdRepository()),
          BlocProvider<DfdCubit>(
            create: (ctx) => DfdCubit(
              repository: ctx.read<DfdRepository>(),
            ),
          ),

          // ======= Publicação (repositório + cubit) =======
          RepositoryProvider<PublicacaoExtratoRepository>(
            create: (_) => PublicacaoExtratoRepository(),
          ),
          BlocProvider<PublicacaoExtratoCubit>(
            create: (ctx) => PublicacaoExtratoCubit(
              ctx.read<PublicacaoExtratoRepository>(),
            ),
          ),

          // ======= Edital (repositório + cubit) =======
          RepositoryProvider<EditalRepository>(
            create: (_) => EditalRepository(),
          ),
          BlocProvider<EditalCubit>(
            create: (ctx) => EditalCubit(ctx.read<EditalRepository>()),
          ),

          /// ======= CONTRACT base (Store/Bloc) =======
          Provider<ProcessBloc>(
            create: (_) => ProcessBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProvider<ProcessStore>(
            create: (_) => ProcessStore(),
          ),

          /// ======= DemandsDashboard (Cubit, global) =======
          BlocProvider<GeneralDashboardCubit>(
            create: (ctx) => GeneralDashboardCubit(
              store: ctx.read<ProcessStore>(),
              additivesRepository: ctx.read<AdditivesRepository>(),

              // ✅ Ajuste: antes era ctx.read<ApostillesStore>()
              // Agora é repository (novo padrão)
              apostillesRepository: ctx.read<ApostillesRepository>(),

              reportMeasurementCubit: ctx.read<ReportMeasurementCubit>(),
              adjustmentMeasurementCubit: ctx.read<AdjustmentMeasurementCubit>(),
              revisionMeasurementCubit: ctx.read<RevisionMeasurementCubit>(),
              dfdCubit: ctx.read<DfdCubit>(),
              editalCubit: ctx.read<EditalCubit>(),
            )..initialize(),
          ),

          // ======= Schedule (cronograma) =======
          RepositoryProvider<ScheduleRoadRepository>(
            create: (_) => ScheduleRoadRepository(),
          ),
          BlocProvider<ScheduleRoadCubit>(
            // ✅ corrige criação sem repository
            create: (ctx) => ScheduleRoadCubit(
              repository: ctx.read<ScheduleRoadRepository>(),
            ),
          ),

          /// ======= Payments =======
          Provider<PaymentReportBloc>(create: (_) => PaymentReportBloc()),
          Provider<PaymentsReportStorageBloc>(
            create: (_) => PaymentsReportStorageBloc(),
          ),
          Provider<PaymentRevisionBloc>(create: (_) => PaymentRevisionBloc()),
          Provider<PaymentAdjustmentBloc>(create: (_) => PaymentAdjustmentBloc()),

          // ======= ETP (repositório + cubit) =======
          RepositoryProvider<EtpRepository>(create: (_) => EtpRepository()),
          BlocProvider<EtpCubit>(
            create: (ctx) => EtpCubit(ctx.read<EtpRepository>()),
          ),

          // ======= TR (repositório + cubit) =======
          RepositoryProvider<TrRepository>(create: (_) => TrRepository()),
          BlocProvider<TrCubit>(
            create: (ctx) => TrCubit(ctx.read<TrRepository>()),
          ),

          // ======= Cotação (repositório + cubit) =======
          RepositoryProvider<CotacaoRepository>(
            create: (_) => CotacaoRepository(),
          ),
          BlocProvider<CotacaoCubit>(
            create: (ctx) => CotacaoCubit(ctx.read<CotacaoRepository>()),
          ),

          // ======= Habilitação (repositório + cubit) =======
          RepositoryProvider<HabilitacaoRepository>(
            create: (_) => HabilitacaoRepository(),
          ),
          BlocProvider<HabilitacaoCubit>(
            create: (ctx) => HabilitacaoCubit(
              ctx.read<HabilitacaoRepository>(),
            ),
          ),

          // ======= Dotação (repositório + cubit) =======
          RepositoryProvider<DotacaoRepository>(
            create: (_) => DotacaoRepository(),
          ),
          BlocProvider<DotacaoCubit>(
            create: (ctx) => DotacaoCubit(ctx.read<DotacaoRepository>()),
          ),

          // ======= Minuta (repositório + cubit) =======
          RepositoryProvider<MinutaContratoRepository>(
            create: (_) => MinutaContratoRepository(),
          ),
          BlocProvider<MinutaContratoCubit>(
            create: (ctx) => MinutaContratoCubit(
              ctx.read<MinutaContratoRepository>(),
            ),
          ),

          // ======= Parecer (repositório + cubit) =======
          RepositoryProvider<ParecerJuridicoRepository>(
            create: (_) => ParecerJuridicoRepository(),
          ),
          BlocProvider<ParecerJuridicoCubit>(
            create: (ctx) => ParecerJuridicoCubit(
              ctx.read<ParecerJuridicoRepository>(),
            ),
          ),

          // ======= Arquivamento (repositório + cubit) =======
          RepositoryProvider<TermoArquivamentoRepository>(
            create: (_) => TermoArquivamentoRepository(),
          ),
          BlocProvider<TermoArquivamentoCubit>(
            create: (ctx) => TermoArquivamentoCubit(
              ctx.read<TermoArquivamentoRepository>(),
            ),
          ),

          /// ======= Physics / Finance =======
          ChangeNotifierProvider<PhysicsFinanceStore>(
            create: (_) => PhysicsFinanceStore(),
          ),
        ],
        builder: (context, _) {
          return BlocBuilder<UserBloc, UserState>(
            buildWhen: (a, b) => a.current != b.current,
            builder: (context, userState) {
              return const GatePage();
            },
          );
        },
      ),
    );
  }, (error, stack) {
    // Log global opcional (Sentry/Crashlytics)
  });
}
