import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/background/background_change.dart';
import 'package:sipged/_widgets/buttons/back_circle_button.dart';
import 'package:sipged/_widgets/menu/pop_up/pup_up_photo_menu.dart';

import 'package:sipged/_widgets/menu/tab/tab_blocked.dart';
import 'package:sipged/_widgets/menu/tab/tab_banner.dart';

/// Descriptor de cada aba (rótulo + builder da página)
class ContractTabDescriptor {
  final String label;
  final Widget Function(ProcessData? contract) builder;

  /// Se true, a aba mostra um bloqueio quando o contrato não foi salvo (id == null)
  final bool requireSavedContract;

  final String? textBanner;

  const ContractTabDescriptor({
    required this.label,
    required this.builder,
    this.textBanner,
    this.requireSavedContract = false,
  });
}

/// Config do selo por aba
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

/// Decide o selo por aba
typedef ResolveStampForTab = StampConfig Function({
required int tabIndex,
required ProcessData contract,
});

/// Scaffold reutilizável de abas para contratos com barra superior customizável.
class TabChangedWidget extends StatefulWidget {
  final UserData? userData;
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;
  final List<ContractTabDescriptor> tabs;
  final String Function(ProcessData c)? bannerTitleBuilder;
  final String blockedMessage;

  // ===== Estilo da barra superior =====
  final double topBarHeight;
  final List<Color>? topBarColors;
  final Color? topBarColor;
  final Alignment topBarBegin;
  final Alignment topBarEnd;
  final Color topBarBorderColor;

  // TabBar
  final Color labelColor;
  final Color unselectedLabelColor;
  final Color indicatorColor;
  final double indicatorWeight;
  final bool tabsIsScrollable;
  final TabAlignment tabAlignment;

  // Trailing (foto/menu)
  final Widget? trailing;

  // Resolver selo por aba
  final ResolveStampForTab? resolveStampForTab;

  final String? textBanner;

  const TabChangedWidget({
    super.key,
    this.userData,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
    required this.tabs,
    this.bannerTitleBuilder,
    this.blockedMessage = '⚠️ Para acessar esta aba, salve primeiro as informações principais do contrato.',
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
  State<TabChangedWidget> createState() => _TabChangedWidgetState();
}

class _TabChangedWidgetState extends State<TabChangedWidget> {
  late ProcessData? _contractData;

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;
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

            // Conteúdo abaixo da UpBar
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
                            final c = _contractData!;
                            final cfg = widget.resolveStampForTab?.call(
                              tabIndex: idx,
                              contract: c,
                            ) ??
                                StampConfig.hidden;

                            return TabBanner(
                              contract: c,
                              titleText: widget.textBanner,
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
                        for (final t in tabs)
                          t.requireSavedContract && (_contractData?.id == null)
                              ? TabBlocked(message: widget.blockedMessage)
                              : t.builder(_contractData),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // UpBar com Back + Tabs + Trailing
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
                    // === BackCircleButton (como antes) ===
                    BackCircleButton(),
                    const SizedBox(width: 12),
                    // Tabs
                    Expanded(
                      child: TabBar(
                        isScrollable: widget.tabsIsScrollable,
                        dividerHeight: 0,
                        tabAlignment: widget.tabAlignment,
                        labelColor: widget.labelColor,
                        indicatorColor: widget.indicatorColor,
                        unselectedLabelColor: widget.unselectedLabelColor,
                        indicatorWeight: widget.indicatorWeight,
                        tabs: [for (final l in labels) Tab(text: l)],
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
