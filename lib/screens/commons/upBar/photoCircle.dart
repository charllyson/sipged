import 'package:flutter/material.dart';
import '../../../_datas/user/user_data.dart';

class PhotoCircle extends StatelessWidget {
  const PhotoCircle({super.key, this.userData});
  final UserData? userData;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: (userData?.urlPhoto?.isNotEmpty ?? false)
          ? Image.network(
        userData!.urlPhoto!,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/default_avatar.png',
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );
        },
      )
          : Image.asset(
        'assets/images/default_avatar.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }
}
