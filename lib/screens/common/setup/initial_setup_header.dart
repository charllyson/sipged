import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    required this.cnpjValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialSetupLogo(
            logoBytes: logoBytes,
            existingLogoUrl: existingLogoUrl,
            saving: saving,
            onTap: onPickLogo,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                CustomTextField(
                  controller: empresaFantasiaCtrl,
                  labelText: 'Nome fantasia',
                  enabled: !saving,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return 'Informe o nome fantasia';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        controller: empresaNomeCtrl,
                        labelText: 'Razão social / Órgão principal',
                        enabled: !saving,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return 'Informe a razão social';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: empresaCnpjCtrl,
                        labelText: 'CNPJ',
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(14),
                        ],
                        validator: cnpjValidator,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}