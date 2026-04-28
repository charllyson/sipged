import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ToastCard extends StatelessWidget {
  const ToastCard({
    super.key,
    required this.id,
    required this.title,
    required this.onClose,
    this.subtitle,
    this.details,
    this.leadingLabel,
    this.icon = Icons.notifications_rounded,
    this.accentColor = const Color(0xFF1565C0),
    this.backgroundColor = Colors.white,
    this.width = 310,
    this.height = 80,
    this.borderRadius = 2,
  });

  final String id;

  final String title;
  final String? subtitle;
  final String? details;
  final String? leadingLabel;

  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  final double width;
  final double height;
  final double borderRadius;

  final VoidCallback onClose;

  String get _safeLeadingLabel {
    final value = (leadingLabel ?? '').trim();
    return value.isNotEmpty ? value : 'Notificação';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSubtitle = (subtitle ?? '').trim();
    final resolvedDetails = (details ?? '').trim();

    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          color: Colors.black87,
        ),
        child: Dismissible(
          key: ValueKey('dismissible_$id'),
          direction: DismissDirection.startToEnd,
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.35,
          },
          movementDuration: const Duration(milliseconds: 180),
          confirmDismiss: (_) async {
            HapticFeedback.lightImpact();
            return true;
          },
          onDismissed: (_) => onClose(),
          background: const SizedBox.shrink(),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: width,
              child: Stack(
                children: [
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(
                        color: const Color(0x11000000),
                      ),
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
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 4,
                            color: accentColor,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 64,
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icon,
                                          color: accentColor,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _safeLeadingLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            letterSpacing: .2,
                                            color: Colors.black54,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                            decoration: TextDecoration.none,
                                          ),
                                        ),
                                        if (resolvedSubtitle.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                              bottom: 5,
                                            ),
                                            child: Text(
                                              resolvedSubtitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.black54,
                                                decoration:
                                                TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        if (resolvedDetails.isNotEmpty)
                                          Text(
                                            resolvedDetails,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.grey.shade700,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
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
                  Positioned(
                    top: 4,
                    right: 2,
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                      splashRadius: 18,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}