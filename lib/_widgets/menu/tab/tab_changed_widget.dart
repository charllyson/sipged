import 'package:flutter/material.dart';

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
    this.approvedIcon,
    this.pendingIcon,
    this.approvedColor,
    this.pendingColor,
    this.scaleFactor = 1.0,
  });

  static const hidden = StampConfig(show: false, approved: false);
}

typedef ResolveStampForTab = StampConfig Function({
required int tabIndex,
required ProcessData contract,
});

class TabChanged extends StatefulWidget {
  final UserData? userData;
  final ProcessData? contractData;
  final ProcessCubit? contractsCubit;
  final int initialTabIndex;
  final List<ContractTabDescriptor> tabs;
  final String Function(ProcessData c)? bannerTitleBuilder;

  /// Monta o texto do número exibido antes do resumo no banner.
  ///
  /// Exemplo:
  /// Contrato nº 012/2026
  /// Processo nº E:05500.000000/2026
  final String Function(ProcessData c)? contractNumberBuilder;

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
  final String? textBanner;

  const TabChanged({
    super.key,
    this.userData,
    this.contractData,
    this.contractsCubit,
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

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;
  }

  @override
  void didUpdateWidget(covariant TabChanged oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.contractData?.id != widget.contractData?.id ||
        oldWidget.contractData != widget.contractData) {
      _contractData = widget.contractData;
    }
  }

  bool _isBlocked(ContractTabDescriptor tab) {
    if (!tab.requireSavedContract) return false;

    final id = _contractData?.id?.trim();
    return id == null || id.isEmpty;
  }

  String? _resolveBannerTitle(ProcessData contract) {
    final customTitle = widget.bannerTitleBuilder?.call(contract).trim();

    if (customTitle != null && customTitle.isNotEmpty) {
      return customTitle;
    }

    final textBanner = widget.textBanner?.trim();
    if (textBanner != null && textBanner.isNotEmpty) {
      return textBanner;
    }

    final summary = contract.displaySummary.trim();
    if (summary.isNotEmpty) return summary;

    return null;
  }

  String? _resolveContractNumber(ProcessData contract) {
    final customNumber = widget.contractNumberBuilder?.call(contract).trim();

    if (customNumber != null && customNumber.isNotEmpty) {
      return customNumber;
    }

    final number = contract.displayNumber.trim();
    if (number.isEmpty) return null;

    final hasContractNumber =
        (contract.contractNumber ?? '').trim().isNotEmpty;
    final hasProcessNumber = (contract.processNumber ?? '').trim().isNotEmpty;

    if (hasContractNumber) {
      return 'Contrato nº $number';
    }

    if (hasProcessNumber) {
      return 'Processo nº $number';
    }

    return number;
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
                              titleText: _resolveBannerTitle(contract),
                              contractNumberText:
                              _resolveContractNumber(contract),
                              showStamp: cfg.show,
                              stampApproved: cfg.approved,
                              stampApprovedLabel:
                              cfg.approvedLabel ?? 'Aprovado',
                              stampPendingLabel:
                              cfg.pendingLabel ?? 'Pendente',
                              stampApprovedIcon:
                              cfg.approvedIcon ?? Icons.verified_outlined,
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