// lib/screens/common/setup/initial_setup_header.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sipged/_utils/mask/sipged_masks.dart';
import 'package:sipged/_widgets/input/text_field_change.dart';

import 'initial_setup_logo.dart';

class InitialSetupHeader extends StatelessWidget {
  final TextEditingController empresaFantasiaCtrl;
  final TextEditingController empresaNomeCtrl;
  final TextEditingController empresaCnpjCtrl;
  final bool saving;
  final Uint8List? logoBytes;
  final String? existingLogoUrl;
  final VoidCallback onPickLogo;
  final VoidCallback? onRemoveLogo;
  final String? Function(String?) cnpjValidator;

  const InitialSetupHeader({
    super.key,
    required this.empresaFantasiaCtrl,
    required this.empresaNomeCtrl,
    required this.empresaCnpjCtrl,
    required this.saving,
    required this.logoBytes,
    required this.existingLogoUrl,
    required this.onPickLogo,
    this.onRemoveLogo,
    required this.cnpjValidator,
  });

  String? _requiredValidator(String? value, String message) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final logo = InitialSetupLogo(
            logoBytes: logoBytes,
            existingLogoUrl: existingLogoUrl,
            saving: saving,
            onTap: onPickLogo,
            onRemove: onRemoveLogo,
          );

          final fields = Column(
            children: [
              CustomTextField(
                controller: empresaFantasiaCtrl,
                labelText: 'Nome fantasia',
                enabled: !saving,
                validator: (value) {
                  return _requiredValidator(
                    value,
                    'Informe o nome fantasia',
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, inner) {
                  final twoColumns = inner.maxWidth >= 620;

                  final companyNameField = CustomTextField(
                    controller: empresaNomeCtrl,
                    labelText: 'Razão social / Órgão principal',
                    enabled: !saving,
                    validator: (value) {
                      return _requiredValidator(
                        value,
                        'Informe a razão social',
                      );
                    },
                  );

                  final cnpjField = CustomTextField(
                    controller: empresaCnpjCtrl,
                    labelText: 'CNPJ',
                    enabled: !saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(14),
                      SipGedMasks.cnpj,
                    ],
                    validator: cnpjValidator,
                  );

                  if (!twoColumns) {
                    return Column(
                      children: [
                        companyNameField,
                        const SizedBox(height: 14),
                        cnpjField,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: companyNameField,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: cnpjField,
                      ),
                    ],
                  );
                },
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: logo),
                const SizedBox(height: 16),
                fields,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              logo,
              const SizedBox(width: 18),
              Expanded(child: fields),
            ],
          );
        },
      ),
    );
  }
}