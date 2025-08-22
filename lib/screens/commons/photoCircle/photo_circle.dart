import 'package:flutter/material.dart';
import 'package:sisged/_datas/system/user_data.dart';

class PhotoCircle extends StatelessWidget {
  final UserData? userData;

  const PhotoCircle({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    final photoUrl = userData?.urlPhoto;

    return ClipOval(
      child: (photoUrl != null && photoUrl.isNotEmpty)
          ? Image.network(
        photoUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
      )
          : _defaultAvatar(),
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
