import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;

  const UserAvatar({super.key, this.avatarUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    final hasAvatar = url != null && url.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF2D3748),
      backgroundImage: hasAvatar ? CachedNetworkImageProvider(url) : null,
      child: hasAvatar
          ? null
          : Icon(Icons.person, color: Colors.grey, size: radius),
    );
  }
}
