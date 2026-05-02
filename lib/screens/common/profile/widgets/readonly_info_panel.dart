import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/screens/common/profile/widgets/info_chip.dart';

class ReadonlyInfoPanel extends StatelessWidget {
  const ReadonlyInfoPanel({
    super.key,
    required this.user,
  });

  final UserData user;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      InfoChip(
        icon: Icons.email_rounded,
        text: user.email ?? 'sem e-mail',
      ),
      if ((user.cpf ?? '').trim().isNotEmpty)
        InfoChip(
          icon: Icons.badge_rounded,
          text: user.cpf!,
        ),
      if ((user.cellPhone ?? '').trim().isNotEmpty)
        InfoChip(
          icon: Icons.phone_rounded,
          text: user.cellPhone!,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: .055),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações vinculadas',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips,
          ),
        ],
      ),
    );
  }
}