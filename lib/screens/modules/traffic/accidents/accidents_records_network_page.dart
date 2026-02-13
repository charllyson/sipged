// lib/screens/modules/traffic/accidents/accidents_records_network_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


import 'package:sipged/_widgets/background/background_cleaner.dart';
import 'package:sipged/_widgets/menu/upBar/up_bar.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

// Cubit
import 'package:sipged/_blocs/modules/transit/accidents/accidents_cubit.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_state.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

// Notificações
import 'package:sipged/_widgets/notification/app_notification.dart';
import 'package:sipged/_widgets/notification/notification_center.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/windows/show_window_dialog.dart';

// SEÇÕES
import 'accidents_form_section.dart';
import 'accidents_selector_dates_section.dart';
import 'accidents_table_section.dart';
import 'accidents_map_section.dart';

class AccidentsRecordsNetworkPage extends StatefulWidget {
  const AccidentsRecordsNetworkPage({super.key});

  @override
  State<AccidentsRecordsNetworkPage> createState() =>
      _AccidentsRecordsNetworkPageState();
}

class _AccidentsRecordsNetworkPageState
    extends State<AccidentsRecordsNetworkPage> {
  bool _inited = false;


  /// Modelo atual do formulário
  AccidentsData _formData = const AccidentsData();

  /// Registro atualmente selecionado na tabela
  AccidentsData? _selectedAccident;

  bool formValidated = false;

  // Visibilidade (toggles)
  bool _showForm = true;
  bool _showTable = true;
  bool _showMap = true;

  // ====== Scroll da tabela ======
  final ScrollController _tableHCtrl = ScrollController();
  final ScrollController _tableVCtrl = ScrollController();

  // ====== Referências ao MAPA ======
  MapController? _mapController;
  void Function(LatLng)? _setActivePoint;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _inited) return;

      // Agora: carrega TUDO sem filtro de ano/mês (mapa completo).
      context.read<AccidentsCubit>().warmup();

      _inited = true;
    });
  }

  // ===== Helpers ===================================================

  bool _isFormValid(AccidentsData d) {
    if (d.date == null) return false;
    final cityDesc = (d.city ?? '').trim();
    final cityAddr = (d.locality ?? '').trim();
    if (cityDesc.isEmpty && cityAddr.isEmpty) return false;
    if ((d.typeOfAccident ?? '').trim().isEmpty) return false;
    return true;
  }

  /// Cria um novo AccidentsData "limpo", calculando a próxima ordem.
  Future<void> _createNew(AccidentsState st) async {
    final maxOrder = st.universe
        .map((e) => e.order ?? 0)
        .fold<int>(0, (prev, val) => math.max(prev, val));

    final nextOrder = maxOrder + 1;

    setState(() {
      _selectedAccident = null;
      _formData = AccidentsData(
        order: nextOrder,
        date: DateTime.now(),
      );
      formValidated = _isFormValid(_formData);
    });
  }

  Future<void> _save(AccidentsState st) async {
    // Garante que o id seja mantido quando for atualização
    final dataToSave = _formData.copyWith(
      id: _selectedAccident?.id ?? _formData.id,
    );

    await context.read<AccidentsCubit>().saveAccident(dataToSave);
  }

  Future<void> _delete(String id, {int? yearHint}) async {
    await context.read<AccidentsCubit>().deleteAccident(
      id: id,
      yearHint: yearHint,
    );
  }

  void _fillFields(AccidentsData data) {
    setState(() {
      _selectedAccident = data;
      _formData = data;
      formValidated = _isFormValid(_formData);
    });
  }

  Future<void> _updateMapFromCep(String cep) async {
    await context.read<AccidentsCubit>().geocodeCep(cep);
  }

  void _applyLocationSuggestionToForm(AccidentsState state) {
    final suggestion = state.locationSuggestion;
    if (suggestion == null) return;

    final lat = suggestion.latitude;
    final lon = suggestion.longitude;

    LatLng? latLng;
    if (lat != null && lon != null) {
      latLng = LatLng(lat, lon);
    }

    setState(() {
      _formData = _formData.copyWith(
        latLng: latLng ?? _formData.latLng,
        street: suggestion.street.isNotEmpty
            ? suggestion.street
            : _formData.street,
        subLocality: suggestion.subLocality.isNotEmpty
            ? suggestion.subLocality
            : _formData.subLocality,
        locality: suggestion.city.isNotEmpty
            ? suggestion.city
            : _formData.locality,
        administrativeArea: suggestion.administrativeArea.isNotEmpty
            ? suggestion.administrativeArea
            : _formData.administrativeArea,
        postalCode: suggestion.postalCode.isNotEmpty
            ? suggestion.postalCode
            : _formData.postalCode,
        country: suggestion.country.isNotEmpty
            ? suggestion.country
            : _formData.country,
        isoCountryCode: suggestion.isoCountryCode.isNotEmpty
            ? suggestion.isoCountryCode
            : _formData.isoCountryCode,
        // Se a cidade de descrição estiver vazia, tenta assumir a da sugestão
        city: (_formData.city == null || _formData.city!.trim().isEmpty)
            ? suggestion.city
            : _formData.city,
      );

      formValidated = _isFormValid(_formData);
    });

    if (latLng != null) {
      _mapController?.move(latLng, 18);
      _setActivePoint?.call(latLng);
    }
  }

  // ===== Wrapper: Tabela com scroll H + V, sem gaps laterais =====
  Widget _buildScrollableTable({
    required BuildContext context,
    required List<AccidentsData> pageItems,
    required AccidentsState state,
  }) {
    final tableCore = AccidentsTableSection(
      onPrint: (item) {
        // Implementar impressão real via LabelPrintService se quiser
        // LabelPrintService.printAccident(context, item, ...);
      },
      listData: pageItems,
      selectedItem: _selectedAccident,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      onPageChange: (p) async =>
          context.read<AccidentsCubit>().changePage(p),
      onTapItem: (item) {
        _fillFields(item);
      },
      onDelete: (id) async {
        final toDelete = state.view.firstWhere(
              (e) => e.id == id,
          orElse: () => AccidentsData(id: id),
        );
        final ok = await confirmDialog(context, 'Deseja apagar este acidente?');
        if (ok) await _delete(id, yearHint: toDelete.date?.year);
      },
    );

    return LayoutBuilder(
      builder: (ctx, c) {
        final available = c.maxWidth.isFinite ? c.maxWidth : 1200.0;
        final double minWidth = math.max(1200.0, available);

        return Scrollbar(
          controller: _tableHCtrl,
          thumbVisibility: true,
          notificationPredicate: (notif) =>
          notif.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _tableHCtrl,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: minWidth),
              child: SizedBox(
                width: minWidth,
                child: Scrollbar(
                  controller: _tableVCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _tableVCtrl,
                    padding: EdgeInsets.zero,
                    child: tableCore,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===== Painel esquerdo (form + filtros + tabela) =====
  Widget _buildLeftPanel(AccidentsState state) {
    final pageItems = state.pageItems;

    final zeroTableGapsTheme = Theme.of(context).copyWith(
      dataTableTheme: const DataTableThemeData(
        horizontalMargin: 0,
        columnSpacing: 20,
        dividerThickness: 1,
      ),
    );

    return Theme(
      data: zeroTableGapsTheme,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 12.0, bottom: 12.0, right: 8.0),
        child: LayoutBuilder(
          builder: (context, c) {
            final bool narrow = c.maxWidth < 700;
            final int itemsPerLine = narrow ? 1 : 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showForm) ...[
                  const SectionTitle(text: 'Cadastrar acidentes'),
                  AccidentsFormSection(
                    itemsPerLineOverride: itemsPerLine,
                    isEditable: true,
                    formValidated: formValidated,
                    currentAccidentId: _selectedAccident?.id,
                    data: _formData,
                    onChanged: (updated) {
                      setState(() {
                        _formData = updated;
                        formValidated = _isFormValid(updated);
                      });
                    },
                    onSave: () async {
                      final ok = await confirmDialog(
                          context, 'Deseja salvar este acidente?');
                      if (ok) await _save(state);
                    },
                    onClear: () => _createNew(state),
                    onGetLocation: () {
                      context.read<AccidentsCubit>().getCurrentLocation();
                    },
                    onUpdateMapFromLatLng: (lat, lon) {
                      final latLng = LatLng(lat, lon);

                      final mc = _mapController;
                      if (mc != null) {
                        mc.move(latLng, 18);
                      }

                      _setActivePoint?.call(latLng);

                      context.read<AccidentsCubit>().reverseGeocode(
                        latitude: lat,
                        longitude: lon,
                      );
                    },
                    onUpdateMapFromCep: (cep) => _updateMapFromCep(cep),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_showTable) ...[
                  const SectionTitle(text: 'Filtrar por datas'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: AccidentsSelectorDatesSection(
                      allAccidents: state.universe,
                      initialYear: state.year,
                      initialMonth: state.month,
                      onSelectionChanged: (res) async {
                        final y = res.selectedYear;
                        final m = res.selectedMonth;

                        // Evita chamada inútil se nada mudou
                        if (y == state.year && m == state.month) return;

                        context.read<AccidentsCubit>().changeFilter(
                          year: y,
                          month: m,
                        );
                      },
                    ),

                  ),
                  const SectionTitle(text: 'Acidentes cadastrados no sistema'),
                  if (pageItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('Nenhum acidente encontrado'),
                    )
                  else
                    _buildScrollableTable(
                      context: context,
                      pageItems: pageItems,
                      state: state,
                    ),
                ],
                if (!_showForm && !_showTable)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                        'Nenhum painel selecionado. Ative Formulário e/ou Tabela.'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ===== Painel direito (mapa) =====
  Widget _buildRightMap() {
    return AccidentsMapSection(
      onControllerReady: (mc) {
        _mapController = mc;
      },
      onBindSetActivePoint: (setPoint) {
        _setActivePoint = setPoint;
      },
      onMapTap: (lat, lon) {
        context.read<AccidentsCubit>().reverseGeocode(
          latitude: lat,
          longitude: lon,
        );
      },
    );
  }

  // ============================================================
  //                          BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccidentsCubit, AccidentsState>(
      listenWhen: (prev, curr) =>
      prev.error != curr.error ||
          prev.success != curr.success ||
          prev.locationError != curr.locationError ||
          prev.locationSuggestion != curr.locationSuggestion,
      listener: (context, state) async {
        // Notificações gerais
        if (state.error != null && state.error!.trim().isNotEmpty) {
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Falha na operação'),
              subtitle: Text(state.error!),
              type: AppNotificationType.error,
              leadingLabel: const Text('Acidentes'),
              duration: const Duration(seconds: 6),
            ),
          );
        }
        if (state.success != null && state.success!.trim().isNotEmpty) {
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Operação concluída'),
              subtitle: Text(state.success!),
              type: AppNotificationType.success,
              leadingLabel: const Text('Acidentes'),
              duration: const Duration(seconds: 4),
            ),
          );
          await _createNew(state);
        }

        // Notificações de localização
        if (state.locationError != null &&
            state.locationError!.trim().isNotEmpty) {
          NotificationCenter.instance.show(
            AppNotification(
              title: const Text('Falha ao obter endereço'),
              subtitle: Text(state.locationError!),
              type: AppNotificationType.error,
              leadingLabel: const Text('Localização'),
              duration: const Duration(seconds: 6),
            ),
          );
        }

        // Aplicar sugestão de endereço + centralizar mapa + pin
        if (state.locationSuggestion != null) {
          _applyLocationSuggestionToForm(state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(87),
            child: Column(
              children: [
                UpBar(
                  showPhotoMenu: true,
                  actions: [
                    IconButton(
                      tooltip: 'Formulário',
                      icon: Icon(
                        _showForm
                            ? Icons.description
                            : Icons.description_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _showForm = !_showForm),
                    ),
                    IconButton(
                      tooltip: 'Tabela',
                      icon: Icon(
                        _showTable
                            ? Icons.table_chart
                            : Icons.table_chart_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _showTable = !_showTable),
                    ),
                    IconButton(
                      tooltip: 'Mapa',
                      icon: Icon(
                        _showMap ? Icons.map : Icons.map_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _showMap = !_showMap),
                    ),
                  ],
                ),
                // AccidentsMenu(),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              const BackgroundClean(),
              LayoutBuilder(
                builder: (context, c) {
                  final left = _buildLeftPanel(state);
                  final right = _buildRightMap();

                  return SplitLayout(
                    left: left,
                    right: right,
                    showRightPanel: _showMap,
                    stackedRightOnTop: true,
                  );
                },
              ),
              if (state.saving || state.gettingLocation)
                Stack(
                  children: [
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
