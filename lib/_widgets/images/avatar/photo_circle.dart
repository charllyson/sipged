import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/system/user/user_data.dart';

class PhotoCircle extends StatelessWidget {
  final UserData? userData;
  final double size;
  final double borderWidth;
  final Color borderColor;

  const PhotoCircle({
    super.key,
    this.userData,
    this.size = 40,
    this.borderWidth = 1,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = userData?.urlPhoto;

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(borderWidth),
          child: ClipOval(
            child: (photoUrl != null && photoUrl.isNotEmpty)
                ? CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorWidget: (context, url, error) => _defaultAvatar(),
            )
                : _defaultAvatar(),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Image.asset(
      'assets/images/default_avatar.png',
      fit: BoxFit.cover,
      width: size,
      height: size,
    );
  }
}