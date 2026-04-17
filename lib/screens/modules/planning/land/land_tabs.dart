import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/_process/process_bloc.dart';
import 'package:sipged/_blocs/modules/contracts/_process/process_data.dart';

import 'package:sipged/_blocs/modules/planning/land/property/land_property_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/property/land_property_repository.dart';

import 'package:sipged/_blocs/modules/planning/land/owner/land_owner_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/owner/land_owner_repository.dart';

import 'package:sipged/_blocs/modules/planning/land/assessment/land_assessment_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/assessment/land_assessment_repository.dart';

import 'package:sipged/_blocs/modules/planning/land/notification/land_notification_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/notification/land_notification_repository.dart';

import 'package:sipged/_blocs/modules/planning/land/payment/land_payment_cubit.dart';
import 'package:sipged/_blocs/modules/planning/land/payment/land_payment_repository.dart';

import 'package:sipged/_widgets/menu/tab/tab_split.dart';
import 'package:sipged/_widgets/menu/tab/tab_changed_widget.dart';

import 'package:sipged/screens/modules/planning/land/property/land_property.dart';
import 'package:sipged/screens/modules/planning/land/owner/land_owner.dart';
import 'package:sipged/screens/modules/planning/land/assessment/land_assessment.dart';
import 'package:sipged/screens/modules/planning/land/notification/land_notification.dart';
import 'package:sipged/screens/modules/planning/land/payment/land_payment.dart';
import 'package:sipged/screens/modules/planning/land/land_table.dart';

class LandTabs extends StatefulWidget {
  final ProcessData? contractData;
  final ProcessBloc? contractsBloc;
  final int initialTabIndex;

  const LandTabs({
    super.key,
    this.contractData,
    this.contractsBloc,
    this.initialTabIndex = 0,
  });

  @override
  State<LandTabs> createState() => _LandTabsState();
}

class _LandTabsState extends State<LandTabs> {
  late ProcessData? _contractData;
  String? _selectedPropertyId;

  String get _contractId => _contractData?.id ?? '';

  @override
  void initState() {
    super.initState();
    _contractData = widget.contractData;
  }

  void _handlePropertySelected(String? propertyId) {
    setState(() {
      _selectedPropertyId = propertyId;
    });
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyTable() {
    return LandTable(
    );
  }

  Widget _buildPropertyTab() {
    return BlocProvider<LandPropertyCubit>(
      create: (_) => LandPropertyCubit(
        repository: LandPropertyRepository(),
      ),
      child: TabSplit(
        topChild: LandProperty(
          contractId: _contractId,
          propertyId: _selectedPropertyId,
          onSavedPropertyId: _handlePropertySelected,
        ),
        bottomChild: _buildPropertyTable(),
        maxTopHeight: 430,
      ),
    );
  }

  Widget _buildOwnerTab() {
    if ((_selectedPropertyId ?? '').isEmpty) {
      return _buildPlaceholder(
        'Selecione ou cadastre um imóvel na aba Imóvel para continuar.',
      );
    }

    return BlocProvider<LandOwnerCubit>(
      create: (_) => LandOwnerCubit(
        repository: LandOwnerRepository(),
      ),
      child: TabSplit(
        topChild: LandOwner(
          contractId: _contractId,
          propertyId: _selectedPropertyId!,
        ),
        bottomChild: _buildPropertyTable(),
        maxTopHeight: 430,
      ),
    );
  }

  Widget _buildAssessmentTab() {
    if ((_selectedPropertyId ?? '').isEmpty) {
      return _buildPlaceholder(
        'Selecione ou cadastre um imóvel na aba Imóvel para continuar.',
      );
    }

    return BlocProvider<LandAssessmentCubit>(
      create: (_) => LandAssessmentCubit(
        repository: LandAssessmentRepository(),
      ),
      child: TabSplit(
        topChild: LandAssessment(
          contractId: _contractId,
          propertyId: _selectedPropertyId!,
        ),
        bottomChild: _buildPropertyTable(),
        maxTopHeight: 430,
      ),
    );
  }

  Widget _buildNotificationTab() {
    if ((_selectedPropertyId ?? '').isEmpty) {
      return _buildPlaceholder(
        'Selecione ou cadastre um imóvel na aba Imóvel para continuar.',
      );
    }

    return BlocProvider<LandNotificationCubit>(
      create: (_) => LandNotificationCubit(
        repository: LandNotificationRepository(),
      ),
      child: TabSplit(
        topChild: LandNotification(
          contractId: _contractId,
          propertyId: _selectedPropertyId!,
        ),
        bottomChild: _buildPropertyTable(),
        maxTopHeight: 430,
      ),
    );
  }

  Widget _buildPaymentTab() {
    if ((_selectedPropertyId ?? '').isEmpty) {
      return _buildPlaceholder(
        'Selecione ou cadastre um imóvel na aba Imóvel para continuar.',
      );
    }

    return BlocProvider<LandPaymentCubit>(
      create: (_) => LandPaymentCubit(
        repository: LandPaymentRepository(),
      ),
      child: TabSplit(
        topChild: LandPayment(
          contractId: _contractId,
          propertyId: _selectedPropertyId!,
        ),
        bottomChild: _buildPropertyTable(),
        maxTopHeight: 430,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabChanged(
      contractData: _contractData,
      contractsBloc: widget.contractsBloc,
      initialTabIndex: widget.initialTabIndex,
      tabs: [
        ContractTabDescriptor(
          label: 'Imóvel',
          requireSavedContract: true,
          builder: (_) => _buildPropertyTab(),
        ),
        ContractTabDescriptor(
          label: 'Proprietário',
          requireSavedContract: true,
          builder: (_) => _buildOwnerTab(),
        ),
        ContractTabDescriptor(
          label: 'Avaliação',
          requireSavedContract: true,
          builder: (_) => _buildAssessmentTab(),
        ),
        ContractTabDescriptor(
          label: 'Notificação',
          requireSavedContract: true,
          builder: (_) => _buildNotificationTab(),
        ),
        ContractTabDescriptor(
          label: 'Pagamento',
          requireSavedContract: true,
          builder: (_) => _buildPaymentTab(),
        ),
      ],
    );
  }
}