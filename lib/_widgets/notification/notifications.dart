import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// =============================================================
/// 5) (Opcional) ACTION: Sino com badge usando seus Subjects
///    Deixe pronto para reativar quando quiser
/// =============================================================
class UpBarNotificationAction extends StatelessWidget {
  final BehaviorSubject<int> badgeSubject;
  final VoidCallback? onTap;

  const UpBarNotificationAction({
    super.key,
    required this.badgeSubject,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: badgeSubject.stream,
      initialData: 0,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notificações',
              icon: const Icon(Icons.notifications_none, color: Colors.white),
              onPressed: onTap,
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: _Badge(count: count),
              ),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}