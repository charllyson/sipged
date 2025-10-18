import 'package:flutter/material.dart';
import 'package:siged/_blocs/system/user/user_data.dart';

class MiniAvatars extends StatelessWidget {
  const MiniAvatars({
    required this.users,
    super.key});

  final List<UserData> users;

  @override
  Widget build(BuildContext context) {
    final count = users.length.clamp(0, 3);
    const double size = 22;
    const double step = 14;

    if (count == 0) return const SizedBox.shrink();

    return SizedBox(
      width: size + (count - 1) * step,
      height: size,
      child: Stack(
        children: List.generate(count, (i) {
          final u = users[i];
          final hasPhoto = (u.urlPhoto?.trim().isNotEmpty ?? false);
          return Positioned(
            left: i * step.toDouble(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: hasPhoto
                    ? DecorationImage(image: NetworkImage(u.urlPhoto!), fit: BoxFit.cover)
                    : null,
                color: hasPhoto ? null : Colors.grey.shade300,
              ),
              child: hasPhoto ? null : const Icon(Icons.person, size: 14, color: Colors.white),
            ),
          );
        }),
      ),
    );
  }
}
