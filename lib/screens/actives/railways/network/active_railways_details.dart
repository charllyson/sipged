import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/currency_input_formatter.dart';
import 'package:flutter_multi_formatter/formatters/money_input_enums.dart';
import 'package:siged/_blocs/actives/railway/active_railway_data.dart';

import 'package:siged/_widgets/layout/responsive_utils.dart';
import 'package:siged/_widgets/input/custom_text_field.dart';

class ActiveRailwaysDetails extends StatefulWidget {
  final ActiveRailwayData fer;
  final bool enabled;
  const ActiveRailwaysDetails({super.key, required this.fer, this.enabled = true});

  @override
  State<ActiveRailwaysDetails> createState() => _ActiveRailwaysDetailsState();
}

class _ActiveRailwaysDetailsState extends State<ActiveRailwaysDetails> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final f = widget.fer;
    void add(String key, dynamic value) =>
        _controllers[key] = TextEditingController(text: value?.toString() ?? '');

    // Identificação
    add('FID', f.fid);
    add('ID nativo', f.nativeId);
    add('Código', f.codigo);
    add('Código Coincidente', f.codigoCoincidente);
    add('Nome', f.nome);

    // Atributos principais
    add('Status', f.status);
    add('Bitola', f.bitola);
    add('Município', f.municipio);
    add('UF', f.uf);

    // Extensões
    add('Extensão (km)', f.extensao?.toStringAsFixed(3));
    add('Extensão E. (km)', f.extensaoE?.toStringAsFixed(3));
    add('Extensão C. (km)', f.extensaoC?.toStringAsFixed(3));

    // Metadados (se usados)
    add('order', f.order);
    add('score', f.score);
    add('createdAt', f.createdAt?.toIso8601String());
    add('createdBy', f.createdBy);
    add('updatedAt', f.updatedAt?.toIso8601String());
    add('updatedBy', f.updatedBy);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
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

  Widget _input(
      BuildContext context,
      String key,
      String label, {
        bool money = false,
      }) {
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
}
