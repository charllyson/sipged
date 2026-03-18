import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:sipged/_widgets/input/custom_text_field.dart';
import 'package:sipged/_widgets/input/custom_date_field.dart';
import 'package:sipged/_widgets/input/drop_down_botton_change.dart';
import 'package:sipged/_widgets/input/custom_auto_complete.dart';
import 'package:sipged/_widgets/texts/section_text_name.dart';
import 'package:sipged/_widgets/layout/split_layout/split_layout.dart';

import 'package:sipged/_blocs/system/user/user_bloc.dart';
import 'package:sipged/_blocs/system/user/user_state.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_cubit.dart';
import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_state.dart';
import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_data.dart';

import 'oac_map_section.dart';

class OacDetailsPage extends StatefulWidget {
  const OacDetailsPage({super.key});

  @override
  State<OacDetailsPage> createState() => _OacDetailsPageState();
}

class _OacDetailsPageState extends State<OacDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // ===== Identificação / localização =====
  final _orderCtrl = TextEditingController();
  final _scoreCtrl = TextEditingController();

  final _ufCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _roadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();

  final _identificationCtrl = TextEditingController(); // ex: "Bueiro BDTC 1,5m - km 23"
  final _oacCodeCtrl = TextEditingController();        // código interno (se houver)
  final _kmCtrl = TextEditingController();
  final _ladoCtrl = TextEditingController();           // "Direito/Esquerdo/Eixo"

  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _altitudeCtrl = TextEditingController();

  // ===== Tipologia / implantação =====
  final _tipoCtrl = TextEditingController();           // bueiro, galeria, ponte pequena, passarela, etc.
  final _materialCtrl = TextEditingController();       // concreto, aço, PEAD, etc.
  final _seccaoCtrl = TextEditingController();         // circular/retangular/oval
  final _diametroCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _larguraCtrl = TextEditingController();
  final _comprimentoCtrl = TextEditingController();
  final _nCelulasCtrl = TextEditingController();       // nº de células/linhas
  final _anguloCtrl = TextEditingController();         // ângulo com eixo da via
  final _cotaMontanteCtrl = TextEditingController();
  final _cotaJusanteCtrl = TextEditingController();

  // ===== Hidráulica / drenagem =====
  final _baciaCtrl = TextEditingController();
  final _vazaoProjetoCtrl = TextEditingController();
  final _declividadeCtrl = TextEditingController();
  final _observacoesHidraulicaCtrl = TextEditingController();

  // ===== Condição / manutenção (geral) =====
  final _empresaRespCtrl = TextEditingController();
  final _contratosRelacionadosCtrl = TextEditingController();
  final _custoEstimadoCtrl = TextEditingController();
  final _custoUltimaManutCtrl = TextEditingController();

  final _observacoesGeraisCtrl = TextEditingController();

  // ===== Datas =====
  final _dtImplantacaoCtrl = TextEditingController();
  final _dtUltimaInspecaoCtrl = TextEditingController();
  final _dtUltimaManutCtrl = TextEditingController();
  final _dtProximaInspecaoCtrl = TextEditingController();

  DateTime? _dtImplantacao;
  DateTime? _dtUltimaInspecao;
  DateTime? _dtUltimaManut;
  DateTime? _dtProximaInspecao;

  // ===== Auditoria =====
  final _createdByCtrl = TextEditingController();
  final _updatedByCtrl = TextEditingController();
  String? _createdById;
  String? _updatedById;
  String _createdAtStr = '-';
  String _updatedAtStr = '-';

  // ===== hidratação =====
  String? _currentId;
  bool _hydrated = false;

  // ===== mapa =====
  MapController? _mapController;
  void Function(LatLng)? _setActivePoint;

  @override
  void dispose() {
    _orderCtrl.dispose();
    _scoreCtrl.dispose();
    _ufCtrl.dispose();
    _municipioCtrl.dispose();
    _roadCtrl.dispose();
    _regionCtrl.dispose();
    _identificationCtrl.dispose();
    _oacCodeCtrl.dispose();
    _kmCtrl.dispose();
    _ladoCtrl.dispose();
    _latitudeCtrl.dispose();
    _longitudeCtrl.dispose();
    _altitudeCtrl.dispose();

    _tipoCtrl.dispose();
    _materialCtrl.dispose();
    _seccaoCtrl.dispose();
    _diametroCtrl.dispose();
    _alturaCtrl.dispose();
    _larguraCtrl.dispose();
    _comprimentoCtrl.dispose();
    _nCelulasCtrl.dispose();
    _anguloCtrl.dispose();
    _cotaMontanteCtrl.dispose();
    _cotaJusanteCtrl.dispose();

    _baciaCtrl.dispose();
    _vazaoProjetoCtrl.dispose();
    _declividadeCtrl.dispose();
    _observacoesHidraulicaCtrl.dispose();

    _empresaRespCtrl.dispose();
    _contratosRelacionadosCtrl.dispose();
    _custoEstimadoCtrl.dispose();
    _custoUltimaManutCtrl.dispose();
    _observacoesGeraisCtrl.dispose();

    _dtImplantacaoCtrl.dispose();
    _dtUltimaInspecaoCtrl.dispose();
    _dtUltimaManutCtrl.dispose();
    _dtProximaInspecaoCtrl.dispose();

    _createdByCtrl.dispose();
    _updatedByCtrl.dispose();
    super.dispose();
  }

  // ===== helpers parse/format =====
  int? _parseInt(String t) => t.trim().isEmpty ? null : int.tryParse(t.trim());
  double? _parseDouble(String text) {
    final t = text.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year.toString()}';
  }

  bool _isValidLatLng(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  void _moveMapToCurrentLatLng() {
    final lat = double.tryParse(_latitudeCtrl.text.replaceAll(',', '.'));
    final lon = double.tryParse(_longitudeCtrl.text.replaceAll(',', '.'));
    if (lat == null || lon == null) return;
    if (!_isValidLatLng(lat, lon)) return;

    final pos = LatLng(lat, lon);
    _mapController?.move(pos, 16);
    _setActivePoint?.call(pos);
  }

  void _onMapTap(double lat, double lon) {
    setState(() {
      _latitudeCtrl.text = lat.toStringAsFixed(6);
      _longitudeCtrl.text = lon.toStringAsFixed(6);
    });
  }

  void _hydrateFromForm(ActiveOacsData d) {
    _currentId = d.id;
    _hydrated = true;

    // Identificação
    _orderCtrl.text = d.order?.toString() ?? '';
    _identificationCtrl.text = d.identificationName ?? '';
    _oacCodeCtrl.text = d.code ?? ''; // <-- era oacCode

    // Localização
    _ufCtrl.text = d.state ?? ''; // <-- era uf
    _municipioCtrl.text = d.municipality ?? ''; // <-- era municipio
    _roadCtrl.text = d.road ?? '';
    _regionCtrl.text = d.region ?? '';

    // KM: no modelo é String
    _kmCtrl.text = d.kmRef ?? ''; // <-- era double km

    // Remover/repensar: lado não existe no model
    _ladoCtrl.text = ''; // ou use outro campo do modelo, se decidir (ex.: environment)

    // Coordenadas
    _latitudeCtrl.text = d.latitude?.toString() ?? '';
    _longitudeCtrl.text = d.longitude?.toString() ?? '';
    _altitudeCtrl.text = d.altitude?.toString() ?? '';

    // Tipologia
    _tipoCtrl.text = d.oacType ?? ''; // <-- era tipo
    _materialCtrl.text = d.material ?? '';
    _seccaoCtrl.text = d.hydraulicType ?? ''; // <-- era seccao

    // Dimensões
    _diametroCtrl.text = d.diameter?.toString() ?? '';
    _alturaCtrl.text = d.height?.toString() ?? '';
    _larguraCtrl.text = d.width?.toString() ?? '';
    _comprimentoCtrl.text = d.length?.toString() ?? '';
    _nCelulasCtrl.text = d.numberOfCells?.toString() ?? '';

    // Campos que NÃO existem no model atual:
    _anguloCtrl.text = ''; // não existe
    _cotaMontanteCtrl.text = d.inletElevation?.toString() ?? '';
    _cotaJusanteCtrl.text = d.outletElevation?.toString() ?? '';

    // Hidrologia
    _baciaCtrl.text = d.catchmentArea?.toString() ?? ''; // <-- era string bacia
    _vazaoProjetoCtrl.text = d.designFlow?.toString() ?? '';
    _declividadeCtrl.text = d.slope?.toString() ?? '';
    _observacoesHidraulicaCtrl.text = d.hydrologyNotes ?? '';

    // Condição / manutenção / custos
    _scoreCtrl.text = d.conditionScore?.toString() ?? ''; // <-- era score
    _empresaRespCtrl.text = d.responsibleCompany ?? ''; // <-- era empresaResponsavel
    _contratosRelacionadosCtrl.text = d.relatedContracts ?? ''; // <-- era contratosRelacionados
    _custoEstimadoCtrl.text = d.maintenanceCostEstimate?.toString() ?? '';
    _custoUltimaManutCtrl.text = d.lastMaintenanceCost?.toString() ?? '';

    // Observações gerais: escolha um destino coerente no model
    _observacoesGeraisCtrl.text = d.maintenanceCostNotes ?? '';

    // Datas
    _dtImplantacao = d.implantationDate;
    _dtUltimaInspecao = d.lastInspectionDate;
    _dtProximaInspecao = d.nextInspectionDate;

    // Não existe no model: dataUltimaManutencao
    _dtUltimaManut = null;

    // Auditoria
    _createdAtStr = _fmtDate(d.createdAt);
    _updatedAtStr = _fmtDate(d.updatedAt);
    _createdById = d.createdBy;
    _updatedById = d.updatedBy;

    _createdByCtrl.text = '';
    _updatedByCtrl.text = '';

    _moveMapToCurrentLatLng();
  }


  Future<void> _handleSave(ActiveOacsState st) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<ActiveOacsCubit>();
    final base = st.form;

    final data = base.copyWith(
      // Identificação
      order: _parseInt(_orderCtrl.text),
      identificationName: _identificationCtrl.text.trim().isEmpty ? null : _identificationCtrl.text.trim(),
      code: _oacCodeCtrl.text.trim().isEmpty ? null : _oacCodeCtrl.text.trim(),

      // Localização
      state: _ufCtrl.text.trim().isEmpty ? null : _ufCtrl.text.trim(),
      municipality: _municipioCtrl.text.trim().isEmpty ? null : _municipioCtrl.text.trim(),
      road: _roadCtrl.text.trim().isEmpty ? null : _roadCtrl.text.trim(),
      region: _regionCtrl.text.trim().isEmpty ? null : _regionCtrl.text.trim(),

      // kmRef é String no model
      kmRef: _kmCtrl.text.trim().isEmpty ? null : _kmCtrl.text.trim(),

      // Coordenadas
      latitude: _parseDouble(_latitudeCtrl.text),
      longitude: _parseDouble(_longitudeCtrl.text),
      altitude: _parseDouble(_altitudeCtrl.text),

      // Tipologia
      oacType: _tipoCtrl.text.trim().isEmpty ? null : _tipoCtrl.text.trim(),
      material: _materialCtrl.text.trim().isEmpty ? null : _materialCtrl.text.trim(),
      hydraulicType: _seccaoCtrl.text.trim().isEmpty ? null : _seccaoCtrl.text.trim(),

      // Dimensões
      diameter: _parseDouble(_diametroCtrl.text),
      height: _parseDouble(_alturaCtrl.text),
      width: _parseDouble(_larguraCtrl.text),
      length: _parseDouble(_comprimentoCtrl.text),
      numberOfCells: _parseInt(_nCelulasCtrl.text),

      inletElevation: _parseDouble(_cotaMontanteCtrl.text),
      outletElevation: _parseDouble(_cotaJusanteCtrl.text),

      // Hidrologia
      catchmentArea: _parseDouble(_baciaCtrl.text),         // agora é double
      designFlow: _parseDouble(_vazaoProjetoCtrl.text),
      slope: _parseDouble(_declividadeCtrl.text),
      hydrologyNotes: _observacoesHidraulicaCtrl.text.trim().isEmpty ? null : _observacoesHidraulicaCtrl.text.trim(),

      // Condição
      conditionScore: _parseDouble(_scoreCtrl.text),

      // Custos / manutenção
      responsibleCompany: _empresaRespCtrl.text.trim().isEmpty ? null : _empresaRespCtrl.text.trim(),
      relatedContracts: _contratosRelacionadosCtrl.text.trim().isEmpty ? null : _contratosRelacionadosCtrl.text.trim(),
      maintenanceCostEstimate: _parseDouble(_custoEstimadoCtrl.text),
      lastMaintenanceCost: _parseDouble(_custoUltimaManutCtrl.text),
      maintenanceCostNotes: _observacoesGeraisCtrl.text.trim().isEmpty ? null : _observacoesGeraisCtrl.text.trim(),

      // Datas
      implantationDate: _dtImplantacao,
      lastInspectionDate: _dtUltimaInspecao,
      nextInspectionDate: _dtProximaInspecao,
    );


    await cubit.upsert(data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data.id == null ? 'OAC salva com sucesso.' : 'OAC atualizada.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActiveOacsCubit, ActiveOacsState>(
      builder: (context, st) {
        final form = st.form;

        if (!_hydrated || form.id != _currentId) {
          _hydrateFromForm(form);
        }

        final isSaving = st.saving;
        final isEditing = form.id != null;

        // ignore: unnecessary_cast
        final userState = context.watch<UserBloc>().state as UserState;
        final List<UserData> allUsers = userState.all;

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
                      const SectionTitle(text: 'Identificação e localização'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CustomTextField(
                            controller: _orderCtrl,
                            labelText: 'Ordem',
                            width: w(4),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          CustomTextField(
                            controller: _ufCtrl,
                            labelText: 'UF',
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _municipioCtrl,
                            labelText: 'Município',
                            width: w(4),
                          ),
                          DropDownButtonChange(
                            controller: _regionCtrl,
                            labelText: 'Região',
                            items: st.regionLabels,
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _roadCtrl,
                            labelText: 'Rodovia',
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _kmCtrl,
                            labelText: 'KM',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _ladoCtrl,
                            labelText: 'Lado (D/E/Eixo)',
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _oacCodeCtrl,
                            labelText: 'Código interno',
                            width: w(4),
                          ),
                          CustomTextField(
                            controller: _identificationCtrl,
                            labelText: 'Identificação / Nome',
                            width: w(2),
                          ),
                          SizedBox(
                            width: w(4),
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) _moveMapToCurrentLatLng();
                              },
                              child: CustomTextField(
                                controller: _latitudeCtrl,
                                labelText: 'Latitude',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: w(4),
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) _moveMapToCurrentLatLng();
                              },
                              child: CustomTextField(
                                controller: _longitudeCtrl,
                                labelText: 'Longitude',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                              ),
                            ),
                          ),
                          CustomTextField(
                            controller: _altitudeCtrl,
                            labelText: 'Altitude',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const SectionTitle(text: 'Implantação (tipologia e dimensões)'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CustomTextField(controller: _tipoCtrl, labelText: 'Tipo de OAC', width: w(4)),
                          CustomTextField(controller: _materialCtrl, labelText: 'Material', width: w(4)),
                          CustomTextField(controller: _seccaoCtrl, labelText: 'Seção', width: w(4)),
                          CustomTextField(
                            controller: _nCelulasCtrl,
                            labelText: 'Nº de células',
                            width: w(4),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                          CustomTextField(
                            controller: _diametroCtrl,
                            labelText: 'Diâmetro (m)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _alturaCtrl,
                            labelText: 'Altura (m)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _larguraCtrl,
                            labelText: 'Largura (m)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _comprimentoCtrl,
                            labelText: 'Comprimento (m)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _anguloCtrl,
                            labelText: 'Ângulo com a via (°)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _cotaMontanteCtrl,
                            labelText: 'Cota montante',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _cotaJusanteCtrl,
                            labelText: 'Cota jusante',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const SectionTitle(text: 'Hidráulica / drenagem'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CustomTextField(controller: _baciaCtrl, labelText: 'Bacia / contribuição', width: w(3)),
                          CustomTextField(
                            controller: _vazaoProjetoCtrl,
                            labelText: 'Vazão de projeto',
                            width: w(3),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _declividadeCtrl,
                            labelText: 'Declividade (%)',
                            width: w(3),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _observacoesHidraulicaCtrl,
                            labelText: 'Observações hidráulicas',
                            width: w(1),
                            maxLines: 3,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const SectionTitle(text: 'Manutenção e custos'),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          CustomTextField(controller: _scoreCtrl, labelText: 'Nota (0 a 5)', width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(controller: _empresaRespCtrl, labelText: 'Empresa responsável', width: w(4)),
                          CustomTextField(controller: _contratosRelacionadosCtrl, labelText: 'Contratos relacionados', width: w(4)),
                          CustomTextField(
                            controller: _custoEstimadoCtrl,
                            labelText: 'Custo estimado (R\$)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          CustomTextField(
                            controller: _custoUltimaManutCtrl,
                            labelText: 'Custo última manutenção (R\$)',
                            width: w(4),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          SizedBox(
                            width: w(4),
                            child: CustomDateField(
                              controller: _dtImplantacaoCtrl,
                              labelText: 'Data implantação',
                              initialValue: _dtImplantacao,
                              onChanged: (d) => _dtImplantacao = d,
                            ),
                          ),
                          SizedBox(
                            width: w(4),
                            child: CustomDateField(
                              controller: _dtUltimaInspecaoCtrl,
                              labelText: 'Última inspeção',
                              initialValue: _dtUltimaInspecao,
                              onChanged: (d) => _dtUltimaInspecao = d,
                            ),
                          ),
                          SizedBox(
                            width: w(4),
                            child: CustomDateField(
                              controller: _dtUltimaManutCtrl,
                              labelText: 'Última manutenção',
                              initialValue: _dtUltimaManut,
                              onChanged: (d) => _dtUltimaManut = d,
                            ),
                          ),
                          SizedBox(
                            width: w(4),
                            child: CustomDateField(
                              controller: _dtProximaInspecaoCtrl,
                              labelText: 'Próxima inspeção',
                              initialValue: _dtProximaInspecao,
                              onChanged: (d) => _dtProximaInspecao = d,
                            ),
                          ),
                          CustomTextField(
                            controller: _observacoesGeraisCtrl,
                            labelText: 'Observações gerais',
                            width: w(1),
                            maxLines: 4,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const SectionTitle(text: 'Registros (auditoria)'),
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
                          SizedBox(
                            width: w(3),
                            child: CustomTextField(
                              controller: TextEditingController(text: _createdAtStr),
                              labelText: 'Criado em',
                              width: w(3),
                              enabled: false,
                            ),
                          ),
                          SizedBox(
                            width: w(3),
                            child: CustomTextField(
                              controller: TextEditingController(text: _updatedAtStr),
                              labelText: 'Atualizado em',
                              width: w(3),
                              enabled: false,
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
                              backgroundColor: WidgetStateProperty.all(Colors.blue.shade800),
                            ),
                            onPressed: isSaving ? null : () => _handleSave(st),
                            icon: isSaving
                                ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Icon(Icons.save_outlined, color: Colors.white),
                            label: Text(
                              isEditing ? 'Atualizar OAC' : 'Salvar OAC',
                              style: const TextStyle(color: Colors.white),
                            ),
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

        Widget buildRightPanel() {
          return OacMapSection(
            onControllerReady: (mc) {
              _mapController = mc;
              _moveMapToCurrentLatLng();
            },
            onBindSetActivePoint: (fn) {
              _setActivePoint = fn;
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
