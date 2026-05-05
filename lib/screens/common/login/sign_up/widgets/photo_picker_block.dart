import 'dart:typed_data';

import 'package:flutter/material.dart';

class PhotoPickerBlock extends StatelessWidget {
  const PhotoPickerBlock({
    super.key,
    required this.photoBytes,
    required this.photoName,
    required this.existingPhotoUrl,
    required this.onPickPhoto,
    required this.onClearPhoto,
  });

  final Uint8List? photoBytes;
  final String? photoName;
  final String? existingPhotoUrl;
  final VoidCallback onPickPhoto;
  final VoidCallback onClearPhoto;

  bool get hasLocalPhoto => photoBytes != null;

  bool get hasRemotePhoto {
    final url = existingPhotoUrl?.trim();
    return url != null && url.isNotEmpty;
  }

  bool get hasPhoto => hasLocalPhoto || hasRemotePhoto;

  @override
  Widget build(BuildContext context) {
    final avatar = Tooltip(
      message: hasPhoto ? 'Trocar foto' : 'Adicionar foto',
      child: InkWell(
        onTap: onPickPhoto,
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasPhoto
                    ? null
                    : const LinearGradient(
                  colors: [
                    Color(0xFFEFF6FF),
                    Color(0xFFF5F3FF),
                  ],
                ),
                border: Border.all(
                  color: hasPhoto
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFBFDBFE),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: hasLocalPhoto
                    ? Image.memory(
                  photoBytes!,
                  fit: BoxFit.cover,
                )
                    : hasRemotePhoto
                    ? Image.network(
                  existingPhotoUrl!.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) {
                    return const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF2563EB),
                      size: 42,
                    );
                  },
                )
                    : const Icon(
                  Icons.add_a_photo_rounded,
                  color: Color(0xFF2563EB),
                  size: 36,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: Icon(
                  hasPhoto ? Icons.edit_rounded : Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;

          final textBlock = Expanded(
            child: Column(
              crossAxisAlignment:
              compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto do usuário',
                  style: TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasLocalPhoto
                      ? (photoName?.trim().isNotEmpty ?? false)
                      ? photoName!.trim()
                      : 'Imagem selecionada'
                      : hasRemotePhoto
                      ? 'Foto atual do usuário. Clique no círculo para trocar.'
                      : 'Clique no círculo para adicionar uma foto de perfil.',
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (hasLocalPhoto) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onClearPhoto,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Remover foto selecionada'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );

          if (compact) {
            return Column(
              children: [
                avatar,
                const SizedBox(height: 14),
                Row(
                  children: [
                    textBlock,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 18),
              textBlock,
            ],
          );
        },
      ),
    );
  }
}