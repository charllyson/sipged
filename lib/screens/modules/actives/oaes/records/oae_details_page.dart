import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_state.dart';
import 'package:sipged/_blocs/modules/actives/oaes/active_oaes_data.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_widgets/input/custom_auto_complete.dart';
import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/custom_date_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

import 'oae_map_section.dart';

class OaeDetailsPage extends StatefulWidget {
  const OaeDetailsPage({super.key});

  @override
  State<OaeDetailsPage> createState() => _OaeDetailsPageState();
}

class _OaeDetailsPageState extends State<OaeDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // controllers principais
  final _orderCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();

  final _stateCtrl = TextEditingController();
  final _roadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _identificationCtrl = TextEditingController();

  final _extensionCtrl = TextEditingController();
  final _widthCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();

  final _structureTypeCtrl = TextEditingController();
  final _relatedContractsCtrl = TextEditingController();
  final _valueInterventionCtrl = TextEditingController();
  final _linearCostMediaCtrl = TextEditingController();
  final _costEstimateCtrl = TextEditingController();

  final _companyBuildCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _altitudeCtrl = TextEditingController();

  final _lastDateInterventionCtrl = TextEditingController();

  // novos controllers + IDs
  final _createdByCtrl = TextEditingController();
  final _updatedByCtrl = TextEditingController();
  String? _createdById;
  String? _updatedById;

  // read-only infos

  DateTime? _lastDateIntervention;

  String? _currentId;
  bool _hydrated = false;

  // ====== MAPA OAEs ======
  MapController? _mapController;
  void Function(LatLng)? _setActivePoint;

  @override
  void dispose() {
    _orderCtrl.dispose();
    _scoreCtrl.dispose();
    _stateCtrl.dispose();
    _roadCtrl.dispose();
    _regionCtrl.dispose();
    _identificationCtrl.dispose();
    _extensionCtrl.dispose();
    _widthCtrl.dispose();
    _areaCtrl.dispose();
    _structureTypeCtrl.dispose();
    _relatedContractsCtrl.dispose();
    _valueInterventionCtrl.dispose();
    _linearCostMediaCtrl.dispose();
    _costEstimateCtrl.dispose();
    _companyBuildCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _altitudeCtrl.dispose();
    _lastDateInterventionCtrl.dispose();

    _createdByCtrl.dispose();
    _updatedByCtrl.dispose();

    super.dispose();
  }

  void _hydrateFromForm(ActiveOaesData d) {
    _currentId = d.id;
    _hydrated = true;

    _orderCtrl.text = d.order?.toString() ?? '';
    _scoreCtrl.text = d.score?.toString() ?? '';

    _stateCtrl.text = d.state ?? '';
    _roadCtrl.text = d.road ?? '';
    _regionCtrl.text = d.region ?? '';
    _identificationCtrl.text = d.identificationName ?? '';

    _extensionCtrl.text = d.extension?.toString() ?? '';
    _widthCtrl.text = d.width?.toString() ?? '';
    _areaCtrl.text = d.area?.toString() ?? '';

    _structureTypeCtrl.text = d.estructureType ?? '';
    _relatedContractsCtrl.text = d.relatedContracts ?? '';
    _valueInterventionCtrl.text = d.valueIntervention?.toString() ?? '';
    _linearCostMediaCtrl.text = d.linearCostMedia?.toString() ?? '';
    _costEstimateCtrl.text = d.costEstimate?.toString() ?? '';

    _companyBuildCtrl.text = d.companyBuild ?? '';
    _latitudeCtrl.text = d.latitude?.toString() ?? '';
    _longitudeCtrl.text = d.longitude?.toString() ?? '';
    _altitudeCtrl.text = d.altitude?.toString() ?? '';

    _lastDateIntervention = d.lastDateIntervention;

    // datas

    // IDs de usuário
    _createdById = d.createdBy;
    _updatedById = d.updatedBy;

    // textos (preenchidos pelo Autocomplete)
    _createdByCtrl.text = '';
    _updatedByCtrl.text = '';

    // se já tem lat/lon, posiciona o mapa
    _moveMapToCurrentLatLng();
  }

  int? _parseInt(String text) {
    if (text.trim().isEmpty) return null;
    return int.tryParse(text.trim());
  }

  double? _parseDouble(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }


  bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  void _moveMapToCurrentLatLng() {
    final lat = double.tryParse(_latitudeCtrl.text.replaceAll(',', '.'));
    final lon = double.tryParse(_longitudeCtrl.text.replaceAll(',', '.'));
    if (lat == null || lon == null) return;
    if (!_isValidLatLng(lat, lon)) return;

    final pos = LatLng(lat, lon);
    if (_mapController != null) {
      _mapController!.move(pos, 16);
    }
    _setActivePoint?.call(pos);
  }

  void _onMapTap(double lat, double lon) {
    setState(() {
      _latitudeCtrl.text = lat.toStringAsFixed(6);
      _longitudeCtrl.text = lon.toStringAsFixed(6);
    });
  }

  Future<void> _handleSave(ActiveOaesState st) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<ActiveOaesCubit>();
    final base = st.form;

    final data = base.copyWith(
      order: _parseInt(_orderCtrl.text),
      score: _parseDouble(_scoreCtrl.text),
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      road: _roadCtrl.text.trim().isEmpty ? null : _roadCtrl.text.trim(),
      region: _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),
      identificationName: _identificationCtrl.text.trim().isEmpty
          ? null
          : _identificationCtrl.text.trim(),
      extension: _parseDouble(_extensionCtrl.text),
      width: _parseDouble(_widthCtrl.text),
      area: _parseDouble(_areaCtrl.text),
      structureType: _structureTypeCtrl.text.trim().isEmpty
          ? null
          : _structureTypeCtrl.text.trim(),
      relatedContracts: _relatedContractsCtrl.text.trim().isEmpty
          ? null
          : _relatedContractsCtrl.text.trim(),
      valueIntervention: _parseDouble(_valueInterventionCtrl.text),
      linearCostMedia: _parseDouble(_linearCostMediaCtrl.text),
      costEstimate: _parseDouble(_costEstimateCtrl.text),
      lastDateIntervention: _lastDateIntervention,
      companyBuild: _companyBuildCtrl.text.trim().isEmpty
          ? null
          : _companyBuildCtrl.text.trim(),
      latitude: _parseDouble(_latitudeCtrl.text),
      longitude: _parseDouble(_longitudeCtrl.text),
      altitude: _parseDouble(_altitudeCtrl.text),
    );

    await cubit.upsert(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          Text(data.id == null ? 'OAE salva com sucesso.' : 'OAE atualizada.'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOaesCubit, ActiveOaesState>(
      builder: (context, st) {
        final form = st.form;

        if (!_hydrated || form.id != _currentId) {
          _hydrateFromForm(form);
        }

        final isSaving = st.saving;
        final isEditing = form.id != null;

        // pega lista de usuários
        final userState = context.watch<UserBloc>().state;
        final List<UserData> allUsers = userState.all;

        // Painel ESQUERDO: formulário
        Widget buildLeftPanel() {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  double w(int perLine) => width >= 900
                      ? (width - (perLine - 1) * 12) / perLine
                      : width >= 600
                      ? (width - 12) / 2
                      : width;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(text: 'Dados gerais'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CustomTextField(
                            controller: _orderCtrl,
                            labelText: 'Ordem',
                            width: w(4),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                          CustomTextField(
                            controller: _stateCtrl,
                            labelText: 'UF',
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _roadCtrl,
                            labelText: 'Rodovia',
                            width: w(4),
                          ),
                          DropDownButtonChange(
                            controller: _regionCtrl,
                            labelText: 'Região',
                            items: st.regionLabels,
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _identificationCtrl,
                            labelText: 'Identificação',
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _extensionCtrl,
                            labelText: 'Extensão (m)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          CustomTextField(
                            controller: _widthCtrl,
                            labelText: 'Largura (m)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          CustomTextField(
                            controller: _areaCtrl,
                            labelText: 'Área (m²)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          CustomTextField(
                            controller: _structureTypeCtrl,
                            labelText: 'Tipo de estrutura',
                            width: w(4),
                          ),

                          // Latitude com sync no blur
                          SizedBox(
                            width: w(4),
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) _moveMapToCurrentLatLng();
                              },
                              child: CustomTextField(
                                controller: _latitudeCtrl,
                                labelText: 'Latitude',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                              ),
                            ),
                          ),

                          // Longitude com sync no blur
                          SizedBox(
                            width: w(4),
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) _moveMapToCurrentLatLng();
                              },
                              child: CustomTextField(
                                controller: _longitudeCtrl,
                                labelText: 'Longitude',
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                  signed: true,
                                ),
                              ),
                            ),
                          ),
                          CustomTextField(
                            controller: _altitudeCtrl,
                            labelText: 'Altitude',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const SectionTitle(text: 'Dados técnicos'),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CustomTextField(
                            controller: _scoreCtrl,
                            labelText: 'Nota (0 a 5)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          CustomTextField(
                            controller: _relatedContractsCtrl,
                            labelText: 'Contratos relacionados',
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _valueInterventionCtrl,
                            labelText: 'Valor intervenção',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          CustomTextField(
                            controller: _linearCostMediaCtrl,
                            labelText: 'Custo linear médio',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          CustomTextField(
                            controller: _costEstimateCtrl,
                            labelText: 'Custo estimado',
                            width: w(3),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          CustomTextField(
                            controller: _companyBuildCtrl,
                            labelText: 'Empresa responsável',
                            width: w(3),
                          ),
                          SizedBox(
                            width: w(3),
                            child: CustomDateField(
                              controller: _lastDateInterventionCtrl,
                              labelText: 'Última intervenção',
                              initialValue: _lastDateIntervention,
                              onChanged: (d) => _lastDateIntervention = d,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const SectionTitle(text: 'Registros'),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          SizedBox(
                            width: w(3),
                            child: CustomAutoComplete<UserData>(
                              label: 'Criado por',
                              controller: _createdByCtrl,
                              allList: allUsers,
                              enabled: false,
                              initialId: _createdById,
                              hint: 'Criado por',
                              idOf: (u) => u.uid,
                              displayOf: (u) => u.name ?? u.email ?? '',
                              subtitleOf: (u) => u.email ?? '',
                              photoUrlOf: (u) => u.urlPhoto,
                            ),
                          ),
                          SizedBox(
                            width: w(3),
                            child: CustomAutoComplete<UserData>(
                              label: 'Atualizado por',
                              controller: _updatedByCtrl,
                              allList: allUsers,
                              enabled: false,
                              initialId: _updatedById,
                              hint: 'Atualizado por',
                              idOf: (u) => u.uid,
                              displayOf: (u) => u.name ?? u.email ?? '',
                              subtitleOf: (u) => u.email ?? '',
                              photoUrlOf: (u) => u.urlPhoto,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.all(
                                  Colors.blue.shade800
                              ),
                            ),
                            onPressed: isSaving ? null : () => _handleSave(st),
                            icon: isSaving
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.save_outlined, color: Colors.white),
                            label: Text(
                                isEditing ? 'Atualizar OAE' : 'Salvar OAE', style: const TextStyle(color: Colors.white))
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }

        // Painel DIREITO: mapa
        Widget buildRightPanel() {
          return OaeMapSection(
            onControllerReady: (mc) {
              _mapController = mc;
              // quando o controller chega, se já houver lat/lon, move o mapa
              _moveMapToCurrentLatLng();
            },
            onBindSetActivePoint: (fn) {
              _setActivePoint = fn;
              // idem: se já tiver lat/lon, posiciona o pin
              _moveMapToCurrentLatLng();
            },
            onMapTap: _onMapTap,
          );
        }

        return SplitLayout(
          left: buildLeftPanel(),
          right: buildRightPanel(),
          showRightPanel: true,
          stackedRightOnTop: true,
        );
      },
    );
  }
}
