import 'package:flutter/material.dart';

class BalloonTileData {
  const BalloonTileData({
    required this.id,
    required this.title,
    this.subtitle,
    this.details,
    this.info,
    this.icon,
    this.leading,
    this.accentColor,
    this.highlighted = false,
    this.onTap,
  });

  factory BalloonTileData.text({
    required String id,
    required String title,
    String? subtitle,
    String? details,
    String? info,
    IconData? icon,
    Widget? leading,
    Color? accentColor,
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    return BalloonTileData(
      id: id,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: subtitle == null || subtitle.trim().isEmpty
          ? null
          : Text(
        subtitle.trim(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      details: details == null || details.trim().isEmpty
          ? null
          : Text(
        details.trim(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      info: info == null || info.trim().isEmpty
          ? null
          : Text(
        info.trim(),
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
      icon: icon,
      leading: leading,
      accentColor: accentColor,
      highlighted: highlighted,
      onTap: onTap,
    );
  }

  factory BalloonTileData.simple({
    required String id,
    required String title,
    String? subtitle,
    String? details,
    String? info,
    IconData? icon,
    Widget? leading,
    Color? accentColor,
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    return BalloonTileData.text(
      id: id,
      title: title,
      subtitle: subtitle,
      details: details,
      info: info,
      icon: icon,
      leading: leading,
      accentColor: accentColor,
      highlighted: highlighted,
      onTap: onTap,
    );
  }

  final String id;
  final Widget title;
  final Widget? subtitle;
  final Widget? details;
  final Widget? info;
  final IconData? icon;
  final Widget? leading;
  final Color? accentColor;
  final bool highlighted;
  final VoidCallback? onTap;

  bool get hasSecondaryContent {
    return subtitle != null || details != null || info != null;
  }
}

class BalloonTile extends StatelessWidget {
  const BalloonTile({
    super.key,
    required this.data,
  });

  final BalloonTileData data;

  static const TextStyle _defaultTitleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Color(0xFF1E293B),
  );

  static TextStyle _defaultSubtitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade700,
    );
  }

  static TextStyle _defaultDetailsStyle(BuildContext context) {
    return TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w500,
      height: 1.18,
      color: Colors.grey.shade600,
    );
  }

  static TextStyle _defaultInfoStyle(BuildContext context) {
    return TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      height: 1.05,
      color: Colors.grey.shade500,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = data.accentColor ?? Colors.blueGrey.shade700;
    final hasSecondaryContent = data.hasSecondaryContent;

    final backgroundColor = data.highlighted
        ? accent.withValues(alpha: 0.075)
        : Colors.transparent;

    final borderColor = data.highlighted
        ? accent.withValues(alpha: 0.22)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.zero,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 44,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: borderColor,
              width: data.highlighted ? 1 : 0,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: hasSecondaryContent ? 8 : 6,
          ),
          child: Row(
            crossAxisAlignment: hasSecondaryContent
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 38,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: hasSecondaryContent
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    SizedBox.square(
                      dimension: 30,
                      child: data.leading ??
                          Container(
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.16),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              data.icon ?? Icons.circle_outlined,
                              color: accent,
                              size: 17,
                            ),
                          ),
                    ),
                    if (data.info != null) ...[
                      const SizedBox(height: 5),
                      DefaultTextStyle(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: _defaultInfoStyle(context),
                        child: data.info!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: hasSecondaryContent ? 1 : 0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: hasSecondaryContent
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DefaultTextStyle(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _defaultTitleStyle,
                        child: data.title,
                      ),
                      if (data.subtitle != null) ...[
                        const SizedBox(height: 3),
                        DefaultTextStyle(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _defaultSubtitleStyle(context),
                          child: data.subtitle!,
                        ),
                      ],
                      if (data.details != null) ...[
                        const SizedBox(height: 3),
                        DefaultTextStyle(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _defaultDetailsStyle(context),
                          child: data.details!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}