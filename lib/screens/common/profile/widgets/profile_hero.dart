import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:sipged/_blocs/system/user/user_data.dart';
import 'package:sipged/_widgets/draw/background/soft_bubbles.dart';
import 'package:sipged/screens/common/profile/widgets/avatar_editable.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.user,
    required this.displayName,
    required this.currentPhoto,
    required this.previewBytes,
    required this.hasChanges,
    this.onPickImage,
    this.showEditButton = true,
  });

  final UserData user;
  final String displayName;
  final String? currentPhoto;
  final Uint8List? previewBytes;
  final bool hasChanges;
  final VoidCallback? onPickImage;
  final bool showEditButton;

  static const BorderRadius _radius = BorderRadius.all(Radius.circular(28));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = displayName.isEmpty ? 'Meu perfil' : displayName;
    final email = (user.email ?? '').trim();

    return Container(
      decoration: BoxDecoration(
        borderRadius: _radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F4C81),
            Color(0xFF1976D2),
            Color(0xFF42A5F5),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withValues(alpha: .26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _radius,
        child: Stack(
          children: [
            const Positioned.fill(
              child: SoftBubbles.profileHero(),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  AvatarEditable(
                    radius: 48,
                    photoUrl: currentPhoto,
                    previewBytes: previewBytes,
                    onTap: onPickImage,
                    showEditButton: showEditButton,
                    borderColor: Colors.white.withValues(alpha: .70),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Meu perfil',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: .86),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .4,
                                ),
                              ),
                              if (hasChanges)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .18),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: .22),
                                    ),
                                  ),
                                  child: const Text(
                                    'Alterações pendentes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.alternate_email_rounded,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: .82),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(alpha: .88),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}