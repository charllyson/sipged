import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:sisged/_blocs/actives/roads/active_roads_data.dart';
import 'package:sisged/_utils/responsive_utils.dart';
import 'package:sisged/_widgets/input/custom_text_field.dart';

class ActiveRoadsDetails extends StatefulWidget {
  final ActiveRoadsData road;
  final bool enabled;

  const ActiveRoadsDetails({super.key, required this.road, this.enabled = true });

  @override
  State<ActiveRoadsDetails> createState() => _ActiveRoadsDetailsState();
}

class _ActiveRoadsDetailsState extends State<ActiveRoadsDetails> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final road = widget.road;
    void add(String key, dynamic value) => _controllers[key] = TextEditingController(text: value?.toString() ?? '');
    add('Tipo de Segmento', road.segmentType);
    add('Código da Rodovia', road.roadCode);
    add('Sigla da Rodovia', road.acronym);
    add('Gerência Regional', road.regional);

    add('Início do Segmento', road.initialSegment);
    add('Fim do Segmento', road.finalSegment);
    add('Início do Km', road.initialKm?.toStringAsFixed(2));
    add('Fim do Km', road.finalKm?.toStringAsFixed(2));
    add('Extensão', road.extension?.toStringAsFixed(2));

    add('Tipo de Superfície', road.stateSurface);
    add('Tipo de Revestimento', road.revestmentType);
    add('VSA', road.vsa);
    add('TMD', road.tmd);

    add('Estado', road.uf);
    add('Administração', road.administration);
    add('Jurisdição', road.jurisdiction);

    add('Obras', road.works);
    add('Federal Coincidente', road.coincidentFederal);
    add('Ato legal', road.legalAct);
    add('Rod. Estadual Coincidente', road.coincidentState);
    add('coincidentStateSurface', road.coincidentStateSurface);
    add('Superfície', road.surface);
    add('Unidade Local', road.unitLocal);
    add('Coincidente', road.coincident);
    add('Latitude inicial do Segmento', road.initialLatSegment);
    add('Longitude inicial do Segmento', road.initialLongSegment);
    add('Latitude final do Segmento', road.finalLatSegment);
    add('Longitude final do Segmento', road.finalLongSegment);
    add('Número Anterior', road.previousNumber);
    add('Número de faixas', road.tracksNumber);
    add('Velocidade máxima', road.maximumSpeed);
    add('Condição de conservação', road.conservationCondition);
    add('Drenagem', road.drainage);
    add('Nome da Rodovia', road.roadName);
    add('Estado', road.state);
    add('Descrição', road.description);
    add('metadata', road.metadata);
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  double getInputWidth(BuildContext context) {
    return responsiveInputWidth(
      context: context,
      itemsPerLine: 4,
      spacing: 12.0,
      margin: 12.0,
      extraPadding: 24.0,
      reservedWidth: MediaQuery.of(context).size.width * 0.2,
      spaceBetweenReserved: 12.0,
    );
  }

  Widget _input(BuildContext context, String key, String label, {bool money = false}) {
    return CustomTextField(
      labelText: label,
      enabled: widget.enabled,
      controller: _controllers[key]!,
      width: getInputWidth(context),
      keyboardType: money ? TextInputType.number : TextInputType.text,
      inputFormatters: money
          ? [
        CurrencyInputFormatter(
          leadingSymbol: 'R\$ ',
          useSymbolPadding: true,
          thousandSeparator: ThousandSeparator.Period,
          mantissaLength: 2,
        ),
      ]
          : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = _controllers.keys.toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final key in keys) _input(context, key, key),
        ],
      ),
    );
  }

  String? formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
