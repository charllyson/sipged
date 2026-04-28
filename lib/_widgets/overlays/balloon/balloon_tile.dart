import 'dart:async';

import 'package:flutter/material.dart';

class BalloonTileData {
  const BalloonTileData({
    required this.id,
    this.title,
    this.subtitle,
    this.details,
    this.icon = Icons.info_outline_rounded,
    this.accentColor = const Color(0xFF1565C0),
    this.highlighted = false,
    this.onTap,
  });

  final String id;

  /// Opcional.
  /// Se null ou vazio, o título não será exibido.
  final String? title;

  final String? subtitle;
  final String? details;

  final IconData icon;
  final Color accentColor;

  final bool highlighted;

  final FutureOr<void> Function()? onTap;
}

class BalloonTile extends StatelessWidget {
  const BalloonTile({
    super.key,
    required this.data,
    this.highlightColor = const Color(0xFFEAF3FF),
    this.backgroundColor = Colors.white,
  });

  final BalloonTileData data;

  final Color highlightColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final title = (data.title ?? '').trim();
    final subtitle = (data.subtitle ?? '').trim();
    final details = (data.details ?? '').trim();

    return InkWell(
      onTap: data.onTap == null
          ? null
          : () async {
        await data.onTap!.call();
      },
      child: Container(
        color: data.highlighted ? highlightColor : backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: data.accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                data.icon,
                color: data.accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: data.highlighted
                              ? FontWeight.w800
                              : FontWeight.w700,
                          color: const Color(0xFF1B2031),
                        ),
                      ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: title.isNotEmpty ? 3 : 0,
                        ),
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.25,
                          ),
                        ),
                      ),
                    if (details.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: title.isNotEmpty || subtitle.isNotEmpty ? 3 : 0,
                        ),
                        child: Text(
                          details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}