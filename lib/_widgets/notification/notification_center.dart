// lib/_blocs/system/notification/notification_center.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_notification.dart';

/// API global para publicar notificações de qualquer lugar.
class NotificationCenter {
  NotificationCenter._();
  static final NotificationCenter instance = NotificationCenter._();

  _NotificationCenterHostState? _host;

  void _attach(_NotificationCenterHostState host) => _host = host;
  void _detach(_NotificationCenterHostState host) { if (_host == host) _host = null; }

  void show(AppNotification n) => _host?.show(n);
  void clear() => _host?.clear();
  void dismissById(String id) => _host?.dismissById(id);
}

/// Host único do app: instala no MaterialApp.builder
class NotificationCenterHost extends StatefulWidget {
  const NotificationCenterHost({super.key, required this.child});
  final Widget child;

  @override
  State<NotificationCenterHost> createState() => _NotificationCenterHostState();
}

class _NotificationCenterHostState extends State<NotificationCenterHost> {
  final _items = <_Entry>[];
  final _animatedListKey = GlobalKey<AnimatedListState>();

  // Layout
  static const double _cardWidth  = 310;
  static const double _gapRight   = 20;
  static const double _gapTop     = 70;
  static const double _vSpacing   = 5;
  static const int    _maxVisible = 4;

  final List<_Entry> _pendingQueue = [];

  @override
  void initState() {
    super.initState();
    NotificationCenter.instance._attach(this);
  }

  @override
  void dispose() {
    NotificationCenter.instance._detach(this);
    for (final e in _items) { e.timer?.cancel(); }
    for (final e in _pendingQueue) { e.timer?.cancel(); }
    super.dispose();
  }

  void show(AppNotification n) {
    final entry = _Entry(notification: n);
    if (_items.length >= _maxVisible) {
      _pendingQueue.add(entry);
      return;
    }
    _insertVisible(entry);
  }

  void _insertVisible(_Entry entry) {
    entry.timer = Timer(entry.notification.duration, () => _dismiss(entry));
    HapticFeedback.selectionClick();

    _items.insert(0, entry); // topo
    _animatedListKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 250));
    setState(() {});
  }

  void _dismiss(_Entry entry) {
    final index = _items.indexOf(entry);
    if (index < 0) {
      _pendingQueue.remove(entry);
      return;
    }

    entry.timer?.cancel();
    _animatedListKey.currentState?.removeItem(
      index,
          (ctx, anim) => _buildItem(entry, anim),
      duration: const Duration(milliseconds: 200),
    );
    _items.removeAt(index);
    setState(() {});

    if (_pendingQueue.isNotEmpty) {
      final next = _pendingQueue.removeAt(0);
      Future.delayed(const Duration(milliseconds: 120), () => _insertVisible(next));
    }
  }

  void dismissById(String id) {
    final idx = _items.indexWhere((e) => e.notification.id == id);
    if (idx >= 0) { _dismiss(_items[idx]); return; }
    final pidx = _pendingQueue.indexWhere((e) => e.notification.id == id);
    if (pidx >= 0) { final e = _pendingQueue.removeAt(pidx); e.timer?.cancel(); }
  }

  void clear() {
    for (final e in [..._items]) { _dismiss(e); }
    for (final e in _pendingQueue) { e.timer?.cancel(); }
    _pendingQueue.clear();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[widget.child];

    if (_items.isNotEmpty) {
      children.add(
        Positioned(
          top: _gapTop,
          right: _gapRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
                minWidth: _cardWidth, maxWidth: _cardWidth),
            child: SafeArea(
              top: false, left: false, right: true, bottom: true,
              child: AnimatedList(
                key: _animatedListKey,
                initialItemCount: _items.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (ctx, index, animation) {
                  final entry = _items[index];
                  return Padding(
                    padding: EdgeInsets.only(
                        bottom: index == _items.length - 1 ? 0 : _vSpacing),
                    child: _buildItem(entry, animation),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: children);
  }

  Widget _buildItem(_Entry entry, Animation<double> animation) {
    final n = entry.notification;

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      axisAlignment: 1.0,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: _ToastCard(
          onClose: () => _dismiss(entry),
          accentColor: n.resolvedAccent,
          backgroundColor: n.backgroundColor,
          leadingIcon: n.resolvedLeadingIcon,
          leadingLabel: n.leadingLabel ?? const Text('Notificação'),
          title: n.title,
          subtitle: n.subtitle ?? const SizedBox.shrink(),
          details: n.details ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _Entry {
  _Entry({required this.notification});
  final AppNotification notification;
  Timer? timer;
}

/// Implementação interna do card (substitui o antigo NotificationToast)
class _ToastCard extends StatelessWidget {
  const _ToastCard({
    required this.onClose,
    required this.accentColor,
    required this.backgroundColor,
    required this.leadingIcon,
    required this.leadingLabel,
    required this.title,
    required this.subtitle,
    required this.details,
  });

  final VoidCallback onClose;
  final Color accentColor;
  final Color backgroundColor;

  final Widget? leadingIcon;
  final Widget? leadingLabel;

  final Widget title;
  final Widget subtitle;
  final Widget details;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.startToEnd,
      dismissThresholds: const {DismissDirection.startToEnd: 0.35},
      movementDuration: const Duration(milliseconds: 180),
      confirmDismiss: (dir) async {
        HapticFeedback.lightImpact();
        return true;
      },
      onDismissed: (_) => onClose(),
      background: const SizedBox.shrink(),
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 310,
          child: Stack(
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: const Color(0x11000000)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 20,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(width: 4, color: accentColor), // barra de acento
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          child: Row(
                            children: [
                              // Lado esquerdo: ícone + rótulo
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  leadingIcon ?? Icon(Icons.notifications_outlined, size: 28, color: accentColor),
                                  const SizedBox(height: 12),
                                  leadingLabel ?? const Text('Notificação', style: TextStyle(letterSpacing: .2)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Lado direito: conteúdo
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DefaultTextStyle.merge(
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                      child: title,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0, bottom: 6.0),
                                      child: DefaultTextStyle.merge(
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Colors.black54,
                                        ),
                                        child: subtitle,
                                      ),
                                    ),
                                    details,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // botão fechar (sem tooltip para não exigir Overlay específico no Web)
              Positioned(
                top: 4,
                right: 2,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  splashRadius: 18,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
