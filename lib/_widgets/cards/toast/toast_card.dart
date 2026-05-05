import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ToastCard extends StatefulWidget {
  static const double defaultWidth = 286;
  static const double defaultHeight = 64;

  const ToastCard({
    super.key,
    required this.id,
    required this.title,
    required this.onClose,
    this.subtitle,
    this.details,
    this.leading,
    this.icon = Icons.notifications_rounded,
    this.accentColor = const Color(0xFF1565C0),
    this.backgroundColor = Colors.white,
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.borderRadius = 4,
  });

  final String id;

  final String title;
  final String? subtitle;
  final String? details;

  /// Widget livre para o lado esquerdo do toast.
  /// Pode ser Icon, CircleAvatar, Image, MiniAvatar etc.
  final Widget? leading;

  final IconData icon;
  final Color accentColor;
  final Color backgroundColor;

  final double width;
  final double height;
  final double borderRadius;

  final VoidCallback onClose;

  @override
  State<ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<ToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.15, 0),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(curvedAnimation);

    _scaleAnimation = Tween<double>(
      begin: 0.985,
      end: 1,
    ).animate(curvedAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    HapticFeedback.lightImpact();
    widget.onClose();
  }

  Widget _buildDefaultLeading() {
    return Icon(
      widget.icon,
      color: widget.accentColor,
      size: 26,
    );
  }

  Widget _buildLeading() {
    return SizedBox(
      width: 44,
      child: Center(
        child: widget.leading ?? _buildDefaultLeading(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSubtitle = (widget.subtitle ?? '').trim();
    final resolvedDetails = (widget.details ?? '').trim();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            type: MaterialType.transparency,
            child: DefaultTextStyle(
              style: const TextStyle(
                decoration: TextDecoration.none,
                color: Colors.black87,
              ),
              child: Dismissible(
                key: ValueKey('dismissible_${widget.id}'),
                direction: DismissDirection.startToEnd,
                dismissThresholds: const {
                  DismissDirection.startToEnd: 0.35,
                },
                movementDuration: const Duration(milliseconds: 180),
                confirmDismiss: (_) async {
                  HapticFeedback.lightImpact();
                  return true;
                },
                onDismissed: (_) => widget.onClose(),
                background: const SizedBox.shrink(),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: widget.width,
                    height: widget.height,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: widget.height,
                          decoration: BoxDecoration(
                            color: widget.backgroundColor,
                            borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                            border: Border.all(
                              color: const Color(0x11000000),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                              BoxShadow(
                                color: Color(0x06000000),
                                blurRadius: 14,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                            BorderRadius.circular(widget.borderRadius),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  width: 3,
                                  color: widget.accentColor,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 28,
                                      top: 6,
                                      bottom: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        _buildLeading(),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.05,
                                                  color: Colors.black,
                                                  decoration:
                                                  TextDecoration.none,
                                                ),
                                              ),
                                              if (resolvedSubtitle.isNotEmpty)
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                    top: 2,
                                                  ),
                                                  child: Text(
                                                    resolvedSubtitle,
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 11.2,
                                                      height: 1.05,
                                                      color: Colors.black54,
                                                      decoration:
                                                      TextDecoration.none,
                                                    ),
                                                  ),
                                                ),
                                              if (resolvedDetails.isNotEmpty)
                                                Padding(
                                                  padding:
                                                  const EdgeInsets.only(
                                                    top: 2,
                                                  ),
                                                  child: Text(
                                                    resolvedDetails,
                                                    maxLines: 1,
                                                    overflow:
                                                    TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      height: 1.05,
                                                      color:
                                                      Colors.grey.shade700,
                                                      decoration:
                                                      TextDecoration.none,
                                                    ),
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
                          top: 1,
                          right: 1,
                          child: IconButton(
                            onPressed: _close,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 15,
                            ),
                            splashRadius: 15,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}