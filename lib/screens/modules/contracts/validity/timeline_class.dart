// lib/_widgets/timeline/timeline_class.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/contracts/validity/validity_cubit.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_data.dart';
import 'package:sipged/_blocs/modules/contracts/validity/validity_state.dart';

import 'package:sipged/_blocs/modules/contracts/additives/additives_data.dart';
import 'package:sipged/_blocs/modules/contracts/contract/contract_data.dart';

import 'package:sipged/_blocs/modules/contracts/hiring/10Publicacao/publicacao_extrato_data.dart';

import 'package:sipged/_utils/formatters/sipged_format_dates.dart';
import 'package:sipged/_widgets/timeline/time_line.dart';
import 'package:sipged/_widgets/timeline/timeline_shimmer.dart';

class TimelineClass extends StatelessWidget {
  final String? dfdStatus;

  static const double _timelineHeight = 310;

  const TimelineClass({
    super.key,
    this.dfdStatus,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValidityCubit, ValidityState>(
      builder: (context, state) {
        final cubit = context.read<ValidityCubit>();

        final contract = state.contract;
        final validities = state.validities;
        final additives = state.additives;

        if (contract == null) {
          return const TimelineShimmer(
            height: _timelineHeight,
            itemCount: 4,
          );
        }

        final contractId = contract.id?.trim();

        if (contractId == null || contractId.isEmpty) {
          return const TimelineShimmer(
            height: _timelineHeight,
            itemCount: 4,
          );
        }

        final status = dfdStatus?.toUpperCase().trim() ?? '';

        final entries = _buildEntries(
          contract: contract,
          validities: validities,
          additives: additives,
          publicacao: cubit.publicacaoExtrato,
          dataFinalContrato: cubit.dataFinalContrato,
          dataFinalExecucao: cubit.dataFinalExecucao,
          status: status,
        );

        if (entries.isEmpty) {
          return const TimelineShimmer(
            height: _timelineHeight,
            itemCount: 4,
          );
        }

        return ModernTimeline(
          height: _timelineHeight,
          items: entries,
          status: status,
          dateFormatter: SipGedFormatDates.dateToDdMMyyyy,
          title: 'Linha do tempo contratual',
          subtitle:
          '${entries.length} marco${entries.length == 1 ? '' : 's'} registrado${entries.length == 1 ? '' : 's'} no ciclo do contrato',
        );
      },
    );
  }

  List<ModernTimelineEntry<dynamic>> _buildEntries({
    required ContractData contract,
    required List<ValidityData> validities,
    required List<AdditivesData> additives,
    required PublicacaoExtratoData? publicacao,
    required DateTime? dataFinalContrato,
    required DateTime? dataFinalExecucao,
    required String status,
  }) {
    final entries = <ModernTimelineEntry<dynamic>>[];

    final sortedValidities = List<ValidityData>.from(validities)
      ..sort(
            (a, b) => (a.orderNumber ?? 0).compareTo(b.orderNumber ?? 0),
      );

    for (int i = 0; i < sortedValidities.length; i++) {
      final validity = sortedValidities[i];

      final orderDate = validity.orderdate;
      if (orderDate == null) {
        continue;
      }

      final title = validity.ordertype?.trim().isNotEmpty == true
          ? validity.ordertype!.trim()
          : 'ORDEM';

      final visual = _getVisualForValidity(title);

      final badges = <ModernTimelineBadge>[];

      final diasParalisados = _calcularDiasParalisados(
        currentIndex: i,
        sortedValidities: sortedValidities,
      );

      if ((diasParalisados ?? 0) > 0) {
        badges.add(
          ModernTimelineBadge(
            label:
            '$diasParalisados dia${diasParalisados == 1 ? '' : 's'} parado',
            icon: Icons.timer_off_rounded,
            color: const Color(0xFFF97316),
          ),
        );
      }

      entries.add(
        ModernTimelineEntry<ValidityData>(
          title: title,
          subtitle: _subtitleForValidity(title),
          date: orderDate,
          color: visual.$1,
          icon: visual.$2,
          badges: badges,
          original: validity,
        ),
      );
    }

    final dataPublicacao = publicacao?.dataPublicacao;

    if (dataPublicacao != null) {
      entries.add(
        ModernTimelineEntry<PublicacaoExtratoData>(
          title: 'PUBLICAÇÃO',
          subtitle: 'Extrato publicado',
          date: dataPublicacao,
          color: const Color(0xFF334155),
          icon: Icons.article_rounded,
          original: publicacao,
        ),
      );
    }

    for (final additive in additives) {
      final additiveDate = additive.additiveDate;

      final hasPrazoContract =
          (additive.additiveValidityContractDays ?? 0) > 0;
      final hasPrazoExecution =
          (additive.additiveValidityExecutionDays ?? 0) > 0;

      if (additiveDate != null && (hasPrazoContract || hasPrazoExecution)) {
        final badges = <ModernTimelineBadge>[];

        if (hasPrazoContract) {
          final days = additive.additiveValidityContractDays ?? 0;

          badges.add(
            ModernTimelineBadge(
              label: '+$days dia${days == 1 ? '' : 's'} contrato',
              icon: Icons.event_repeat_rounded,
              color: const Color(0xFF0F766E),
            ),
          );
        }

        if (hasPrazoExecution) {
          final days = additive.additiveValidityExecutionDays ?? 0;

          badges.add(
            ModernTimelineBadge(
              label: '+$days dia${days == 1 ? '' : 's'} execução',
              icon: Icons.run_circle_rounded,
              color: const Color(0xFF2563EB),
            ),
          );
        }

        entries.add(
          ModernTimelineEntry<AdditivesData>(
            title: 'ASSINATURA ADITIVO DE PRAZO',
            subtitle: 'Alteração de prazo',
            date: additiveDate,
            color: const Color(0xFF0F766E),
            icon: Icons.edit_note_rounded,
            badges: badges,
            original: additive,
          ),
        );
      }
    }

    if (dataFinalContrato != null) {
      entries.add(
        ModernTimelineEntry<void>(
          title: 'FINAL DO CONTRATO',
          subtitle: 'Data limite calculada',
          date: dataFinalContrato,
          color: const Color(0xFF7C3AED),
          icon: Icons.event_available_rounded,
          badges: _buildPrazoBadges(
            itemDate: dataFinalContrato,
            status: status,
          ),
        ),
      );
    }

    if (dataFinalExecucao != null) {
      entries.add(
        ModernTimelineEntry<void>(
          title: 'FINAL DA EXECUÇÃO',
          subtitle: 'Data limite calculada',
          date: dataFinalExecucao,
          color: const Color(0xFF7C3AED),
          icon: Icons.event_available_rounded,
          badges: _buildPrazoBadges(
            itemDate: dataFinalExecucao,
            status: status,
          ),
        ),
      );
    }

    entries.sort((a, b) => a.date.compareTo(b.date));

    return entries;
  }

  int? _calcularDiasParalisados({
    required int currentIndex,
    required List<ValidityData> sortedValidities,
  }) {
    if (currentIndex <= 0) {
      return null;
    }

    final current = sortedValidities[currentIndex];
    final previous = sortedValidities[currentIndex - 1];

    final currentType = current.ordertype?.toUpperCase().trim() ?? '';
    final previousType = previous.ordertype?.toUpperCase().trim() ?? '';

    if (!currentType.contains('REINÍCIO')) {
      return null;
    }

    if (!previousType.contains('PARALISA')) {
      return null;
    }

    final currentDate = current.orderdate;
    final previousDate = previous.orderdate;

    if (currentDate == null || previousDate == null) {
      return null;
    }

    final days = currentDate.difference(previousDate).inDays;

    if (days <= 0) {
      return null;
    }

    return days;
  }

  List<ModernTimelineBadge> _buildPrazoBadges({
    required DateTime itemDate,
    required String status,
  }) {
    final cleanStatus = status.toUpperCase().trim();

    if (cleanStatus != 'EM ANDAMENTO') {
      if (cleanStatus.isEmpty) {
        return const [];
      }

      return [
        ModernTimelineBadge(
          label: cleanStatus,
          icon: Icons.info_outline_rounded,
          color: const Color(0xFF475569),
        ),
      ];
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(itemDate.year, itemDate.month, itemDate.day);

    if (target.isAfter(today)) {
      final days = target.difference(today).inDays;

      return [
        ModernTimelineBadge(
          label: 'Faltam $days dia${days == 1 ? '' : 's'}',
          icon: Icons.schedule_rounded,
          color: const Color(0xFF2563EB),
        ),
      ];
    }

    if (target.isAtSameMomentAs(today)) {
      return const [
        ModernTimelineBadge(
          label: 'Vence hoje',
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFF97316),
        ),
      ];
    }

    final days = today.difference(target).inDays;

    return [
      ModernTimelineBadge(
        label: 'Vencido há $days dia${days == 1 ? '' : 's'}',
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFDC2626),
      ),
    ];
  }

  (Color, IconData) _getVisualForValidity(String title) {
    final type = title.toUpperCase();

    if (type.contains('REINÍCIO')) {
      return (
      const Color(0xFF2563EB),
      Icons.restart_alt_rounded,
      );
    }

    if (type.contains('INÍCIO')) {
      return (
      const Color(0xFF16A34A),
      Icons.play_arrow_rounded,
      );
    }

    if (type.contains('PARALISA')) {
      return (
      const Color(0xFFF97316),
      Icons.pause_rounded,
      );
    }

    if (type.contains('FINALIZA')) {
      return (
      const Color(0xFF059669),
      Icons.check_circle_rounded,
      );
    }

    return (
    const Color(0xFF64748B),
    Icons.description_rounded,
    );
  }

  String _subtitleForValidity(String title) {
    final type = title.toUpperCase();

    if (type.contains('INÍCIO')) {
      return 'Marco de execução';
    }

    if (type.contains('REINÍCIO')) {
      return 'Retomada registrada';
    }

    if (type.contains('PARALISA')) {
      return 'Interrupção do prazo';
    }

    if (type.contains('FINALIZA')) {
      return 'Encerramento de etapa';
    }

    return 'Ordem contratual';
  }
}