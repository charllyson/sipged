import 'package:flutter/material.dart';

class EditUserDangerActions extends StatelessWidget {
  const EditUserDangerActions({
    super.key,
    required this.loading,
    required this.onDeactivateUser,
    required this.onBlockUser,
    required this.onDeleteUser,
    this.isDeactivateSelected = false,
    this.isBlockSelected = false,
    this.isDeleteSelected = false,
  });

  final bool loading;

  final bool isDeactivateSelected;
  final bool isBlockSelected;
  final bool isDeleteSelected;

  final VoidCallback? onDeactivateUser;
  final VoidCallback? onBlockUser;
  final VoidCallback? onDeleteUser;

  static const Color _inactiveColor = Color(0xFF667085);
  static const Color _inactiveBg = Color(0xFFF2F4F7);
  static const Color _inactiveBorder = Color(0xFFD0D5DD);

  static const Color _blockedColor = Color(0xFFDC2626);
  static const Color _blockedBorder = Color(0xFFFCA5A5);

  static const Color _deletedBg = Color(0xFF991B1B);
  static const Color _deletedBorder = Color(0xFF991B1B);

  Widget _circleActionButton({
    required String tooltip,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback? onPressed,
    required bool selected,
  }) {
    final disabled = loading || onPressed == null;

    final size = selected ? 62.0 : 58.0;

    return Tooltip(
      message: tooltip,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: selected && !disabled
              ? [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: disabled ? 0.04 : 0.12,
              ),
              blurRadius: disabled ? 6 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: disabled
                    ? backgroundColor.withValues(alpha: 0.45)
                    : backgroundColor,
                shape: CircleBorder(
                  side: BorderSide(
                    color: disabled
                        ? borderColor.withValues(alpha: 0.35)
                        : borderColor,
                    width: selected ? 2.4 : 1.4,
                  ),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: disabled ? null : onPressed,
                  child: Center(
                    child: Icon(
                      icon,
                      color: disabled
                          ? iconColor.withValues(alpha: 0.45)
                          : iconColor,
                      size: selected ? 29 : 27,
                    ),
                  ),
                ),
              ),
            ),

            // Badge fica acima da borda do botão.
            if (selected)
              Positioned(
                right: -2,
                top: -2,
                child: IgnorePointer(
                  child: Container(
                    width: 21,
                    height: 21,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dangerInfoText() {
    String subtitle = 'Use com cuidado. Essas ações alteram o status ou removem o cadastro.';

    if (isDeleteSelected) {
      subtitle = 'Este usuário está marcado como apagado.';
    } else if (isBlockSelected) {
      subtitle = 'Este usuário está bloqueado. Clique novamente em bloquear para desbloquear.';
    } else if (isDeactivateSelected) {
      subtitle = 'Este usuário está desativado. Clique novamente em desativar para reativar.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações do usuário',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _circleActionButton(
        tooltip: isDeactivateSelected
            ? 'Reativar usuário'
            : 'Desativar usuário',
        icon: isDeactivateSelected
            ? Icons.person_rounded
            : Icons.person_off_rounded,
        backgroundColor:
        isDeactivateSelected ? _inactiveColor : _inactiveBg,
        iconColor:
        isDeactivateSelected ? Colors.white : _inactiveColor,
        borderColor: _inactiveBorder,
        selected: isDeactivateSelected,
        onPressed: onDeactivateUser,
      ),
      _circleActionButton(
        tooltip: isBlockSelected
            ? 'Desbloquear usuário'
            : 'Bloquear usuário',
        icon: isBlockSelected
            ? Icons.lock_open_rounded
            : Icons.block_rounded,
        backgroundColor:
        isBlockSelected ? _blockedColor : Colors.white,
        iconColor:
        isBlockSelected ? Colors.white : _blockedColor,
        borderColor:
        isBlockSelected ? _blockedColor : _blockedBorder,
        selected: isBlockSelected,
        onPressed: onBlockUser,
      ),
      _circleActionButton(
        tooltip: 'Apagar usuário',
        icon: Icons.delete_forever_rounded,
        backgroundColor: _deletedBg,
        iconColor: Colors.white,
        borderColor: _deletedBorder,
        selected: isDeleteSelected,
        onPressed: onDeleteUser,
      ),
    ];

    final hasSelected =
        isDeactivateSelected || isBlockSelected || isDeleteSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasSelected ? const Color(0xFFF8FAFC) : const Color(0xFFFFFBFA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasSelected ? const Color(0xFFCBD5E1) : const Color(0xFFFEE4E2),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _dangerInfoText(),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: buttons,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _dangerInfoText(),
              ),
              const SizedBox(width: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: buttons,
              ),
            ],
          );
        },
      ),
    );
  }
}