import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class BlockedUserView extends StatelessWidget {
  const BlockedUserView({super.key,
    required this.userData,
    required this.onSignOut,
  });

  final UserData userData;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final statusLabel = userData.statusLabel;
    final statusColor = userData.statusColor;
    final statusIcon = userData.statusIcon;

    final reason = userData.deletedReason ??
        userData.blockedReason ??
        userData.deactivatedReason ??
        'A conta não está autorizada a acessar o sistema.';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 460,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 46,
                      color: statusColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Usuário $statusLabel',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: onSignOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}