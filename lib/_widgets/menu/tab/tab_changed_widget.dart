import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/1Dfd/dfd_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/draw/background/background_change.dart';
import 'package:sipged/_widgets/buttons/circle_button_change.dart';
import 'package:sipged/_widgets/menu/pop_up/pup_up_photo_menu.dart';
import 'package:sipged/_widgets/menu/tab/tab_banner.dart';
import 'package:sipged/_widgets/menu/tab/tab_blocked.dart';

class ContractTabDescriptor {
  final String label;
  final Widget Function(ProcessData? contract) builder;
  final bool requireSavedContract;

  /// Mantido por compatibilidade.
  /// Não é usado no banner.
  final String? textBanner;

  const ContractTabDescriptor({
    required this.label,
    required this.builder,
    this.textBanner,
    this.requireSavedContract = false,
  });
}

class StampConfig {
  final bool show;
  final bool approved;
  final String? approvedLabel;
  final String? pendingLabel;
  final IconData? approvedIcon;
  final IconData? pendingIcon;
  final Color? approvedColor;
  final Color? pendingColor;
  final double scaleFactor;

  const StampConfig({
    required this.show,
    required this.approved,
    this.approvedLabel,
    this.pendingLabel,
    this.pendingIcon,
    this.approvedIcon,
    this.approvedColor,
    this.pendingColor,
    this.scaleFactor = 1.0,
  });

  static const hidden = StampConfig(
    show: false,
    approved: false,
  );
}

typedef ResolveStampForTab = StampConfig Function({
required int tabIndex,
required ProcessData contract,
});

class TabChanged extends StatefulWidget {
  final UserData? userData;
  final ProcessData? contractData;
  final ProcessCubit? contractsCubit;

  /// Cubit oficial da publicação.
  ///
  /// Se não for informado, tenta buscar no contexto:
  final PublicacaoExtratoCubit? publicacaoExtratoCubit;

  /// DFD já carregado, caso a tela pai possua.
  final DfdData? dfdData;

  /// Loader oficial para carregar DFD pelo contractId.
  ///
  /// Use assim na chamada:
  ///
  /// dfdLoader: (contractId) {
  /// },
  ///
  /// Se não for informado, este widget agora também tenta buscar automaticamente:
  final Future<DfdData?> Function(String contractId)? dfdLoader;

  final int initialTabIndex;
  final List<ContractTabDescriptor> tabs;

  /// Mantidos por compatibilidade.
  /// Não são usados no banner.
  final String Function(ProcessData c)? bannerTitleBuilder;
  final String Function(ProcessData c)? contractNumberBuilder;
  final String? textBanner;

  final String blockedMessage;

  final double topBarHeight;
  final List<Color>? topBarColors;
  final Color? topBarColor;
  final Alignment topBarBegin;
  final Alignment topBarEnd;
  final Color topBarBorderColor;

  final Color labelColor;
  final Color unselectedLabelColor;
  final Color indicatorColor;
  final double indicatorWeight;
  final bool tabsIsScrollable;
  final TabAlignment tabAlignment;

  final Widget? trailing;
  final ResolveStampForTab? resolveStampForTab;

  const TabChanged({
    super.key,
    this.userData,
    this.contractData,
    this.contractsCubit,
    this.publicacaoExtratoCubit,
    this.dfdData,
    this.dfdLoader,
    this.initialTabIndex = 0,
    required this.tabs,
    this.bannerTitleBuilder,
    this.contractNumberBuilder,
    this.blockedMessage =
    '⚠️ Para acessar esta aba, salve primeiro as informações principais do contrato.',
    this.topBarHeight = 72.0,
    this.topBarColors = const [Color(0xFF1B2031), Color(0xFF1B2039)],
    this.topBarColor,
    this.topBarBegin = Alignment.topCenter,
    this.topBarEnd = Alignment.bottomCenter,
    this.topBarBorderColor = Colors.white,
    this.labelColor = Colors.white,
    this.unselectedLabelColor = Colors.grey,
    this.indicatorColor = Colors.white,
    this.indicatorWeight = 2.0,
    this.tabsIsScrollable = true,
    this.tabAlignment = TabAlignment.start,
    this.trailing = const PopUpPhotoMenu(),
    this.resolveStampForTab,
    this.textBanner,
  });

  @override
  State<TabChanged> createState() => _TabChangedState();
}

class _TabChangedState extends State<TabChanged> {
  late ProcessData? _contractData;

  PublicacaoExtratoData? _resolvedPublicacaoExtrato;
  DfdData? _resolvedDfdData;

  String? _lastResolvedContractId;
  bool _resolvingDisplay = false;

  @override
  void initState() {
    super.initState();

    _contractData = widget.contractData;
    _resolvedDfdData = widget.dfdData;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveBannerData();
    });
  }

  @override
  void didUpdateWidget(covariant TabChanged oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldId = oldWidget.contractData?.id;
    final newId = widget.contractData?.id;

    final shouldReload = oldId != newId ||
        oldWidget.contractData != widget.contractData ||
        oldWidget.publicacaoExtratoCubit != widget.publicacaoExtratoCubit ||
        oldWidget.dfdData != widget.dfdData ||
        oldWidget.dfdLoader != widget.dfdLoader;

    if (shouldReload) {
      _contractData = widget.contractData;
      _resolvedPublicacaoExtrato = null;
      _resolvedDfdData = widget.dfdData;
      _lastResolvedContractId = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveBannerData();
      });
    }
  }

  bool _isBlocked(ContractTabDescriptor tab) {
    if (!tab.requireSavedContract) return false;

    final id = _contractData?.id?.trim();
    return id == null || id.isEmpty;
  }

  PublicacaoExtratoCubit? _getPublicacaoExtratoCubit() {
    if (widget.publicacaoExtratoCubit != null) {
      return widget.publicacaoExtratoCubit;
    }

    try {
      return context.read<PublicacaoExtratoCubit>();
    } catch (_) {
      return null;
    }
  }

  DfdCubit? _getDfdCubit() {
    try {
      return context.read<DfdCubit>();
    } catch (_) {
      return null;
    }
  }

  Future<DfdData?> _loadDfdForBanner(String contractId) async {
    if (widget.dfdData != null) {
      return widget.dfdData;
    }

    if (widget.dfdLoader != null) {
      return widget.dfdLoader!(contractId);
    }

    final dfdCubit = _getDfdCubit();

    if (dfdCubit == null) {
      return null;
    }

    return dfdCubit.getDataForContract(contractId);
  }

  Future<PublicacaoExtratoData?> _loadPublicacaoForBanner(
      String contractId,
      ) async {
    final publicacaoCubit = _getPublicacaoExtratoCubit();

    if (publicacaoCubit == null) {
      return null;
    }

    return publicacaoCubit.getDataForContract(contractId);
  }

  Future<void> _resolveBannerData() async {
    final contract = _contractData;
    final contractId = contract?.id?.trim();

    if (!mounted) return;
    if (contract == null) return;
    if (contractId == null || contractId.isEmpty) return;
    if (_resolvingDisplay) return;
    if (_lastResolvedContractId == contractId) return;

    setState(() {
      _resolvingDisplay = true;
    });

    try {
      final results = await Future.wait<dynamic>([
        _loadPublicacaoForBanner(contractId),
        _loadDfdForBanner(contractId),
      ]);

      final publicacao = results[0] as PublicacaoExtratoData?;
      final dfd = results[1] as DfdData?;

      if (!mounted) return;

      setState(() {
        _resolvedPublicacaoExtrato = publicacao;
        _resolvedDfdData = dfd;
        _lastResolvedContractId = contractId;
        _resolvingDisplay = false;
      });

      debugPrint(
        'TabChanged banner carregado: '
            'contractId=$contractId | '
            'numeroContrato=${publicacao?.numeroContrato} | '
            'processoPublicacao=${publicacao?.processo} | '
            'processoDfd=${dfd?.processoAdministrativo} | '
            'descricaoObjeto=${dfd?.descricaoObjeto}',
      );
    } catch (e, stack) {
      debugPrint('Falha ao carregar dados do banner: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      setState(() {
        _lastResolvedContractId = contractId;
        _resolvingDisplay = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double safeTop = MediaQuery.of(context).padding.top;
    final double topBarTotal = safeTop + widget.topBarHeight;

    final tabs = widget.tabs;
    final labels = tabs.map((t) => t.label).toList();

    return DefaultTabController(
      length: tabs.length,
      initialIndex: widget.initialTabIndex.clamp(0, tabs.length - 1).toInt(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            const BackgroundChange(),
            Padding(
              padding: EdgeInsets.only(top: topBarTotal),
              child: Column(
                children: [
                  if (_contractData != null)
                    Builder(
                      builder: (context) {
                        final tabController = DefaultTabController.of(context);

                        return AnimatedBuilder(
                          animation: tabController,
                          builder: (context, _) {
                            final idx = tabController.index;
                            final contract = _contractData!;

                            final cfg = widget.resolveStampForTab?.call(
                              tabIndex: idx,
                              contract: contract,
                            ) ??
                                StampConfig.hidden;

                            return TabBanner(
                              contract: contract,
                              contractsCubit: widget.contractsCubit,
                              publicacaoExtratoData:
                              _resolvedPublicacaoExtrato,
                              dfdData: _resolvedDfdData,
                              showStamp: cfg.show,
                              stampApproved: cfg.approved,
                              stampApprovedLabel:
                              cfg.approvedLabel ?? 'Aprovado',
                              stampPendingLabel:
                              cfg.pendingLabel ?? 'Pendente',
                              stampApprovedIcon: cfg.approvedIcon ??
                                  Icons.verified_outlined,
                              stampPendingIcon: cfg.pendingIcon ??
                                  Icons.verified_user_outlined,
                              stampApprovedColor: cfg.approvedColor,
                              stampPendingColor: cfg.pendingColor,
                              stampScaleFactor: cfg.scaleFactor,
                            );
                          },
                        );
                      },
                    ),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final tab in tabs)
                          _isBlocked(tab)
                              ? TabBlocked(message: widget.blockedMessage)
                              : tab.builder(_contractData),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: topBarTotal,
                decoration: BoxDecoration(
                  gradient: (widget.topBarColors != null &&
                      widget.topBarColors!.isNotEmpty)
                      ? LinearGradient(
                    colors: widget.topBarColors!,
                    begin: widget.topBarBegin,
                    end: widget.topBarEnd,
                  )
                      : null,
                  color: (widget.topBarColors == null ||
                      widget.topBarColors!.isEmpty)
                      ? (widget.topBarColor ?? const Color(0xFF1B2031))
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: widget.topBarBorderColor,
                      width: 1,
                    ),
                  ),
                ),
                padding: EdgeInsets.only(top: safeTop),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 8),
                    CircleButtonChange(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TabBar(
                        isScrollable: widget.tabsIsScrollable,
                        dividerHeight: 0,
                        tabAlignment: widget.tabAlignment,
                        labelColor: widget.labelColor,
                        indicatorColor: widget.indicatorColor,
                        unselectedLabelColor: widget.unselectedLabelColor,
                        indicatorWeight: widget.indicatorWeight,
                        tabs: [
                          for (final label in labels) Tab(text: label),
                        ],
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}