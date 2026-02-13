import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_widgets/menu/tab/tab_split.dart';
import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';
import 'package:sipged/screens/modules/planning/rightWay/lane_regularization_assessment_form.dart';
import 'package:sipged/screens/modules/planning/rightWay/lane_regularization_notification_form.dart';
import 'package:sipged/screens/modules/planning/rightWay/lane_regularization_owner_form.dart';
import 'package:sipged/screens/modules/planning/rightWay/lane_regularization_payment_form.dart';
import 'package:sipged/screens/modules/planning/rightWay/lane_regularization_property_form.dart';

import 'package:sipged/_blocs/modules/planning/lane_regularization/lane_regularization_controller.dart';
import 'package:sipged/_blocs/modules/planning/lane_regularization/lane_regularization_store.dart';
import 'package:sipged/screens/modules/planning/rightWay/lane_regularization_table.dart';

class TabLaneRegularizationPage extends StatefulWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const TabLaneRegularizationPage({
    super.key,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
  });

  @override
  State<TabLaneRegularizationPage> createState() => _TabLaneRegularizationPageState();
}

class _TabLaneRegularizationPageState extends State<TabLaneRegularizationPage> {
  late ProcessData? _contractData;

  // Store e Controller do Right Way
  late final LaneRegularizationStore _store;
  LaneRegularizationController? _propCtrl;

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;

    _store = LaneRegularizationStore();
    if (_contractData != null) {
      _propCtrl = LaneRegularizationController(
        contract: _contractData!,
        store: _store,
      );
    }
  }

  @override
  void dispose() {
    _propCtrl?.dispose();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabChangedWidget(
      contractData: _contractData,
      contractsBloc: widget.contractsBloc,
      initialTabIndex: widget.initialTabIndex,
      tabs: [
        ContractTabDescriptor(
          label: 'Imóvel',
          requireSavedContract: true,
          builder: (_) => (_propCtrl == null)
              ? const SizedBox.shrink()
              : TabSplit(
            topChild: LaneRegularizationPropertyForm(controller: _propCtrl!),
            bottomChild: LaneRegularizationTable(
              controller: _propCtrl!,
              headerTitle: 'Imóveis cadastrados',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            maxTopHeight: 430,
          ),
        ),
        ContractTabDescriptor(
          label: 'Proprietário',
          requireSavedContract: true,
          builder: (_) => (_propCtrl == null)
              ? const SizedBox.shrink()
              : TabSplit(
            topChild: LaneRegularizationOwnerForm(controller: _propCtrl!),
            bottomChild: LaneRegularizationTable(
              controller: _propCtrl!,
              headerTitle: 'Imóveis cadastrados',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            maxTopHeight: 430,
          ),
        ),
        ContractTabDescriptor(
          label: 'Avaliação',
          requireSavedContract: true,
          builder: (_) => (_propCtrl == null)
              ? const SizedBox.shrink()
              : TabSplit(
            topChild: LaneRegularizationAssessmentForm(controller: _propCtrl!),
            bottomChild: LaneRegularizationTable(
              controller: _propCtrl!,
              headerTitle: 'Imóveis cadastrados',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            maxTopHeight: 430,
          ),
        ),
        ContractTabDescriptor(
          label: 'Notificação',
          requireSavedContract: true,
          builder: (_) => (_propCtrl == null)
              ? const SizedBox.shrink()
              : TabSplit(
            topChild: LaneRegularizationNotificationForm(controller: _propCtrl!),
            bottomChild: LaneRegularizationTable(
              controller: _propCtrl!,
              headerTitle: 'Imóveis cadastrados',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            maxTopHeight: 430,
          ),
        ),
        ContractTabDescriptor(
          label: 'Pagamento',
          requireSavedContract: true,
          builder: (_) => (_propCtrl == null)
              ? const SizedBox.shrink()
              : TabSplit(
            topChild: LaneRegularizationPaymentForm(controller: _propCtrl!),
            bottomChild: LaneRegularizationTable(
              controller: _propCtrl!,
              headerTitle: 'Imóveis cadastrados',
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
            ),
            maxTopHeight: 430,
          ),
        ),
      ],
    );
  }
}
