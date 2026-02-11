import 'package:flutter/material.dart';
import 'package:siged/_utils/theme/sipged_theme.dart';

/// Barra inferior genérica e responsiva para etapas do processo de contratação.
///
/// [title] - título exibido acima dos botões (ex.: "Documento de Formalização de Demanda (DFD)")
/// [icon] - ícone exibido à esquerda do título
/// [busy] - se true, desativa os botões e mostra estado de salvamento
/// [onSave] - callback ao clicar em "Salvar"
/// [onSaveAndNext] - callback ao clicar em "Salvar e aprovar" (quando ainda não aprovado)
/// [approved] - controla o estado da etapa para trocar rótulo/ícone do botão primário
/// [onUpdateApproved] - callback ao clicar em "Atualizar" (quando já aprovado)
class StageProgress extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool busy;

  final VoidCallback onSave;
  final VoidCallback onSaveAndNext;

  /// Quando true, o botão primário vira "Atualizar" (ícone update).
  final bool approved;

  /// Ação quando já está aprovado. Se nulo, cai em onSaveAndNext (compat).
  final VoidCallback? onUpdateApproved;

  const StageProgress({
    super.key,
    required this.title,
    required this.icon,
    required this.busy,
    required this.onSave,
    required this.onSaveAndNext,
    this.approved = false,
    this.onUpdateApproved,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final textWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: SipGedTheme.primaryColor),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: SipGedTheme.primaryColor,
            ),
          ),
        ),
      ],
    );

    final buttons = [
      OutlinedButton.icon(
        style: ButtonStyle(
          foregroundColor:
          MaterialStatePropertyAll(SipGedTheme.primaryColor),
        ),
        onPressed: busy ? null : onSave,
        icon: const Icon(Icons.save_outlined),
        label: Text(
          'Salvar',
          style: TextStyle(color: SipGedTheme.primaryColor),
        ),
      ),
      const SizedBox(width: 8, height: 8),
      FilledButton.icon(
        style: ButtonStyle(
          backgroundColor:
          MaterialStatePropertyAll(SipGedTheme.primaryColor),
        ),
        onPressed: busy
            ? null
            : (approved
            ? (onUpdateApproved ?? onSaveAndNext)
            : onSaveAndNext),
        icon: Icon(approved ? Icons.update : Icons.arrow_forward),
        label: Text(approved ? 'Atualizar' : 'Salvar e aprovar'),
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: isMobile
            ? Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          spacing: 8,
          children: [
            Center(child: textWidget),
            ...buttons,
          ],
        )
            : Row(
          children: [
            textWidget,
            const Spacer(),
            ...buttons,
          ],
        ),
      ),
    );
  }
}
