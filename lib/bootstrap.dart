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

import 'firebase_options_flavors.dart';

// ===== Cubits / BLoCs de mapa / ativos =====
import 'package:siged/_services/dxf/map_overlay_cubit.dart';

import 'package:siged/_blocs/actives/roads/active_road_bloc.dart';
import 'package:siged/_blocs/actives/roads/active_roads_event.dart';
import 'package:siged/_blocs/actives/railway/active_railways_bloc.dart';
import 'package:siged/_blocs/actives/railway/active_railways_event.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_bloc.dart';
import 'package:siged/_blocs/actives/oaes/active_oaes_event.dart';

// ===== Painéis / Dashboards =====
import 'package:siged/_blocs/panels/overview-dashboard/demands_dashboard_controller.dart';

// ===== Processos: ajustes, revisões, relatórios =====
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_bloc.dart';
import 'package:siged/_blocs/process/adjustment/adjustment_measurement_store.dart';

import 'package:siged/_blocs/process/revision/revision_measurement_bloc.dart';
import 'package:siged/_blocs/process/revision/revision_measurement_store.dart';

import 'package:siged/_blocs/process/report/report_measurement_bloc.dart';
import 'package:siged/_blocs/process/report/report_measurement_storage_bloc.dart';
import 'package:siged/_blocs/process/report/report_measurement_store.dart';

// ===== Processos: validades =====
import 'package:siged/_blocs/process/validity/validity_bloc.dart';
import 'package:siged/_blocs/process/validity/validity_storage_bloc.dart';
import 'package:siged/_blocs/process/validity/validity_store.dart';

// ===== Processos: aditivos / apostilas =====
import 'package:siged/_blocs/process/additives/additives_bloc.dart';
import 'package:siged/_blocs/process/additives/additives_storage_bloc.dart';
import 'package:siged/_blocs/process/additives/additive_store.dart';

import 'package:siged/_blocs/process/apostilles/apostilles_bloc.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_storage_bloc.dart';
import 'package:siged/_blocs/process/apostilles/apostilles_store.dart';

// ===== Processos: base de contratos =====
import 'package:siged/_blocs/_process/process_bloc.dart';
import 'package:siged/_blocs/_process/process_storage_bloc.dart';
import 'package:siged/_blocs/_process/process_store.dart';
import 'package:siged/_blocs/_process/process_controller.dart';

// ===== Processos: cronograma =====
import 'package:siged/_blocs/sectors/operation/road/schedule_road_bloc.dart';
import 'package:siged/_blocs/sectors/operation/road/schedule_road_repository.dart';

// ===== Processos: física / financeira =====
import 'package:siged/_blocs/process/phys_fin/physics_finance_store.dart';

// ===== Setores financeiros: pagamentos =====
import 'package:siged/_blocs/sectors/financial/payments/adjustment/payment_adjustment_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payment_reports_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/report/payments_report_storage_bloc.dart';
import 'package:siged/_blocs/sectors/financial/payments/revision/payment_revision_bloc.dart';

// ===== Setor trânsito: acidentes / infrações =====
import 'package:siged/_blocs/sectors/transit/accidents/accidents_bloc.dart';
import 'package:siged/_blocs/sectors/transit/infractions/infractions_bloc.dart';
import 'package:siged/_blocs/sectors/transit/infractions/infractions_controller.dart';

// ===== Sistema / Usuário / Login =====
import 'package:siged/_blocs/system/login/login_bloc.dart';
import 'package:siged/_blocs/system/info/system_bloc.dart';
import 'package:siged/_blocs/system/user/user_repository.dart';
import 'package:siged/_blocs/system/user/user_bloc.dart';
import 'package:siged/_blocs/system/user/user_event.dart';
import 'package:siged/_blocs/system/user/user_state.dart';

// ===== Módulo de orçamento =====
import 'package:siged/_blocs/process/hiring/5Edital/budget/budget_bloc.dart';
import 'package:siged/_blocs/process/hiring/5Edital/budget/budget_store.dart';

// ===== Módulos de contratação (DFD, ETP, TR, etc.) =====
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_bloc.dart';
import 'package:siged/_blocs/process/hiring/1Dfd/dfd_repository.dart';

import 'package:siged/_blocs/process/hiring/2Etp/etp_bloc.dart';
import 'package:siged/_blocs/process/hiring/2Etp/etp_repository.dart';

import 'package:siged/_blocs/process/hiring/3Tr/tr_bloc.dart';
import 'package:siged/_blocs/process/hiring/3Tr/tr_repository.dart';

import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_bloc.dart';
import 'package:siged/_blocs/process/hiring/4Cotacao/cotacao_repository.dart';

import 'package:siged/_blocs/process/hiring/5Edital/edital_bloc.dart';
import 'package:siged/_blocs/process/hiring/5Edital/edital_repository.dart';

import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_bloc.dart';
import 'package:siged/_blocs/process/hiring/6Habilitacao/habilitacao_repository.dart';

import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_bloc.dart';
import 'package:siged/_blocs/process/hiring/7Dotacao/dotacao_repository.dart';

import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_bloc.dart';
import 'package:siged/_blocs/process/hiring/8Minuta/minuta_contrato_repository.dart';

import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_bloc.dart';
import 'package:siged/_blocs/process/hiring/9Juridico/parecer_juridico_repository.dart';

import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_bloc.dart';
import 'package:siged/_blocs/process/hiring/10Publicacao/publicacao_extrato_repository.dart';

import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_bloc.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_repository.dart';

// ===== GatePage / raiz da aplicação =====
import 'package:siged/gate_page.dart';

Future<void> _initFirebase() async {
  if (kIsWeb) {
    // Web precisa de options explícitas -> seleciona pelo flavor
    await Firebase.initializeApp(options: FirebaseOptionsFlavors.forWeb());
  } else {
    // Mobile/Desktop: usa configs nativas (google-services / GoogleService-Info)
    await Firebase.initializeApp();
  }
}

/// Conecta nos Emuladores quando compilado com --dart-define=USE_EMULATOR=true
Future<void> _connectToEmulatorsIfNeeded() async {
  const useEmu = bool.fromEnvironment('USE_EMULATOR', defaultValue: false);
  if (!useEmu) return;

  // Observação: use '10.0.2.2' se rodar no Android Emulator.
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
        final s = details.stack;
        if (s is StackTrace) debugPrint(s.toString());
        return;
      }
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      // Poderia logar aqui
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

          // --------- BLoCs / services básicos ---------
          Provider<LoginBloc>(create: (_) => LoginBloc(), dispose: (_, b) => b.dispose()),
          Provider<SystemBloc>(create: (_) => SystemBloc(), dispose: (_, b) => b.dispose()),

          /// ======= User =======
          Provider<UserRepository>(create: (_) => UserRepository()),
          Provider<UserBloc>(
            create: (ctx) => UserBloc(ctx.read<UserRepository>())
              ..add(const UserWarmupRequested(
                listenRealtime: true,
                bindCurrentUser: true,
              )),
            dispose: (_, b) => b.close(),
          ),

          /// ======= OAEs / Rodovias / Ferrovias =======
          BlocProvider<ActiveOaesBloc>(
            create: (_) => ActiveOaesBloc()
              ..add(const ActiveOaesWarmupRequested()),
          ),
          BlocProvider<ActiveRoadsBloc>(
            create: (_) => ActiveRoadsBloc()
              ..add(const ActiveRoadsWarmupRequested()),
          ),
          BlocProvider<ActiveRailwaysBloc>(
            create: (_) => ActiveRailwaysBloc()
              ..add(const ActiveRailwaysWarmupRequested()),
          ),

          // ======= Acidentes / Infrações =======
          BlocProvider<AccidentsBloc>(create: (_) => AccidentsBloc()),
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

          /// ======= REPORT MEASUREMENT =======
          Provider<ReportMeasurementStorageBloc>(
            create: (_) => ReportMeasurementStorageBloc(),
          ),
          Provider<ReportMeasurementBloc>(
            create: (_) => ReportMeasurementBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProvider<ReportsMeasurementStore>(
            create: (ctx) => ReportsMeasurementStore(
              ctx.read<ReportMeasurementBloc>(),
            ),
          ),

          /// ======= VALIDITY =======
          Provider<ValidityStorageBloc>(create: (_) => ValidityStorageBloc()),
          Provider<ValidityBloc>(
            create: (_) => ValidityBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProvider<ValidityStore>(
            create: (ctx) => ValidityStore(
              bloc: ctx.read<ValidityBloc>(),
              storage: ctx.read<ValidityStorageBloc>(),
            ),
          ),

          /// ======= BUDGET =======
          Provider<BudgetBloc>(create: (_) => BudgetBloc()),
          ChangeNotifierProvider<BudgetStore>(
            create: (ctx) => BudgetStore(
              bloc: ctx.read<BudgetBloc>(),
            ),
          ),

          /// ======= ADJUSTMENT MEASUREMENT =======
          Provider<AdjustmentMeasurementBloc>(
            create: (_) => AdjustmentMeasurementBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProvider<AdjustmentsMeasurementStore>(
            create: (ctx) => AdjustmentsMeasurementStore(
              ctx.read<AdjustmentMeasurementBloc>(),
            ),
          ),

          /// ======= REVISION MEASUREMENT =======
          Provider<RevisionMeasurementBloc>(
            create: (_) => RevisionMeasurementBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProvider<RevisionsMeasurementStore>(
            create: (ctx) => RevisionsMeasurementStore(
              ctx.read<RevisionMeasurementBloc>(),
            ),
          ),

          /// ======= ADDITIVES =======
          Provider<AdditivesBloc>(
            create: (_) => AdditivesBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          Provider<AdditivesStorageBloc>(
            create: (_) => AdditivesStorageBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProvider<AdditivesStore>(
            create: (ctx) => AdditivesStore(
              bloc: ctx.read<AdditivesBloc>(),
              storage: ctx.read<AdditivesStorageBloc>(),
            ),
          ),

          /// ======= APOSTILLES =======
          Provider<ApostillesBloc>(
            create: (_) => ApostillesBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          Provider<ApostillesStorageBloc>(
            create: (_) => ApostillesStorageBloc(),
            dispose: (_, b) => b.dispose(),
          ),
          ChangeNotifierProvider<ApostillesStore>(
            create: (ctx) => ApostillesStore(
              bloc: ctx.read<ApostillesBloc>(),
              storage: ctx.read<ApostillesStorageBloc>(),
            ),
          ),

          // ======= DFD (repositório + bloc) – ANTES de ProcessBloc/ProcessStore =======
          RepositoryProvider<DfdRepository>(create: (_) => DfdRepository()),
          BlocProvider<DfdBloc>(
            create: (ctx) => DfdBloc(ctx.read<DfdRepository>()),
          ),

          // ======= Publicação (repositório + bloc) – também ANTES de ProcessStore =======
          RepositoryProvider<PublicacaoExtratoRepository>(
            create: (_) => PublicacaoExtratoRepository(),
          ),
          BlocProvider<PublicacaoExtratoBloc>(
            create: (ctx) =>
                PublicacaoExtratoBloc(ctx.read<PublicacaoExtratoRepository>()),
          ),

          // ======= Edital (repositório + bloc) – antes de DemandsDashboardController =======
          RepositoryProvider<EditalRepository>(
            create: (_) => EditalRepository(),
          ),
          BlocProvider<EditalBloc>(
            create: (ctx) => EditalBloc(ctx.read<EditalRepository>()),
          ),

          /// ======= CONTRACT base (Store/Storage/Bloc) =======
          Provider<ProcessBloc>(
            create: (ctx) => ProcessBloc(
              dfdBloc: ctx.read<DfdBloc>(),
            ),
            dispose: (_, b) => b.dispose(),
          ),
          Provider<ProcessStorageBloc>(
            create: (_) => ProcessStorageBloc(),
          ),
          ChangeNotifierProvider<ProcessStore>(
            create: (ctx) => ProcessStore(),
          ),

          /// ======= ContractsController (depois de TODOS os stores acima) =======
          ChangeNotifierProvider<ProcessController>(
            create: (ctx) => ProcessController(
              store: ctx.read<ProcessStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
              adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(),
              revisionsStore: ctx.read<RevisionsMeasurementStore>(),
              processStorageBloc: ctx.read<ProcessStorageBloc>(),
            )..initialize(),
          ),

          ChangeNotifierProvider<DemandsDashboardController>(
            create: (ctx) => DemandsDashboardController(
              store: ctx.read<ProcessStore>(),
              additivesStore: ctx.read<AdditivesStore>(),
              apostillesStore: ctx.read<ApostillesStore>(),
              reportsMeasurementStore: ctx.read<ReportsMeasurementStore>(),
              adjustmentsStore: ctx.read<AdjustmentsMeasurementStore>(),
              revisionsStore: ctx.read<RevisionsMeasurementStore>(),
              dfdBloc: ctx.read<DfdBloc>(),
              editalBloc: ctx.read<EditalBloc>(),
            )..initialize(),
          ),

          // ======= Schedule (cronograma) =======
          RepositoryProvider<ScheduleRoadRepository>(
            create: (_) => ScheduleRoadRepository(),
          ),
          BlocProvider<ScheduleRoadBloc>(
            create: (ctx) => ScheduleRoadBloc(),
          ),

          /// ======= Payments =======
          Provider<PaymentReportBloc>(create: (_) => PaymentReportBloc()),
          Provider<PaymentsReportStorageBloc>(
            create: (_) => PaymentsReportStorageBloc(),
          ),
          Provider<PaymentRevisionBloc>(create: (_) => PaymentRevisionBloc()),
          Provider<PaymentAdjustmentBloc>(create: (_) => PaymentAdjustmentBloc()),

          // ======= ETP (repositório + bloc) =======
          RepositoryProvider<EtpRepository>(create: (_) => EtpRepository()),
          BlocProvider<EtpBloc>(
            create: (ctx) => EtpBloc(ctx.read<EtpRepository>()),
          ),

          // ======= TR (repositório + bloc) =======
          RepositoryProvider<TrRepository>(create: (_) => TrRepository()),
          BlocProvider<TrBloc>(
            create: (ctx) => TrBloc(ctx.read<TrRepository>()),
          ),

          // ======= Cotação (repositório + bloc) =======
          RepositoryProvider<CotacaoRepository>(
            create: (_) => CotacaoRepository(),
          ),
          BlocProvider<CotacaoBloc>(
            create: (ctx) => CotacaoBloc(ctx.read<CotacaoRepository>()),
          ),

          // ======= Habilitacao (repositório + bloc) =======
          RepositoryProvider<HabilitacaoRepository>(
            create: (_) => HabilitacaoRepository(),
          ),
          BlocProvider<HabilitacaoBloc>(
            create: (ctx) =>
                HabilitacaoBloc(ctx.read<HabilitacaoRepository>()),
          ),

          // ======= Dotação (repositório + bloc) =======
          RepositoryProvider<DotacaoRepository>(
            create: (_) => DotacaoRepository(),
          ),
          BlocProvider<DotacaoBloc>(
            create: (ctx) => DotacaoBloc(ctx.read<DotacaoRepository>()),
          ),

          // ======= Minuta (repositório + bloc) =======
          RepositoryProvider<MinutaContratoRepository>(
            create: (_) => MinutaContratoRepository(),
          ),
          BlocProvider<MinutaContratoBloc>(
            create: (ctx) =>
                MinutaContratoBloc(ctx.read<MinutaContratoRepository>()),
          ),

          // ======= Parecer (repositório + bloc) =======
          RepositoryProvider<ParecerJuridicoRepository>(
            create: (_) => ParecerJuridicoRepository(),
          ),
          BlocProvider<ParecerJuridicoBloc>(
            create: (ctx) =>
                ParecerJuridicoBloc(ctx.read<ParecerJuridicoRepository>()),
          ),

          // ======= Arquivamento (repositório + bloc) =======
          RepositoryProvider<TermoArquivamentoRepository>(
            create: (_) => TermoArquivamentoRepository(),
          ),
          BlocProvider<TermoArquivamentoBloc>(
            create: (ctx) => TermoArquivamentoBloc(
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
              final app = const GatePage();

              if (userState.current == null) {
                // sem user: não injeta OAEs extras
                return app;
              }

              // Se quiser manter o wrapper extra de OAEs aqui, beleza.
              return BlocProvider<ActiveOaesBloc>(
                create: (_) =>
                ActiveOaesBloc()..add(const ActiveOaesWarmupRequested()),
                child: app,
              );
            },
          );
        },
      ),
    );
  }, (error, stack) {
    // Aqui você pode logar erros globais (Sentry, Crashlytics, etc.)
  });
}
