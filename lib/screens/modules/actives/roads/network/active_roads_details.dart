import 'package:flutter/material.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_widgets/layout/responsive_utils.dart';

class ActiveRoadsDetails extends StatelessWidget {
  final ActiveRoadsData road;
  final bool enabled;

  const ActiveRoadsDetails({
    super.key,
    required this.road,
    this.enabled = true,
  });

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

  @override
  Widget build(BuildContext context) {
    final fields = road.detailsFields;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final field in fields)
            _DetailFieldCard(
              width: getInputWidth(context),
              label: field.label,
              value: field.value,
            ),
        ],
      ),
    );
  }
}

class _DetailFieldCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;

  const _DetailFieldCard({
    required this.width,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}