import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class PhotoCircle extends StatelessWidget {
  final UserData? userData;

  const PhotoCircle({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final photoUrl = userData?.urlPhoto;

    return Container(
      width: 44, // 40 + 2px de borda em cada lado
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1), // borda branca
      ),
      child: ClipOval(
        child: (photoUrl != null && photoUrl.isNotEmpty)
            ? Image.network(
          photoUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
        )
            : _defaultAvatar(),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Image.asset(
      'assets/images/default_avatar.png',
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }
}
