import 'package:flutter/material.dart';

class AppIconDisplay extends StatelessWidget {
  final String? iconUrl;
  final String appName;
  final double size;

  const AppIconDisplay({
    super.key,
    this.iconUrl,
    required this.appName,
    this.size = 80,
  });

  static const _appIconMap = {
    'TikTok': Icons.music_note,
    'Facebook': Icons.facebook,
    'YouTube': Icons.play_circle_filled,
    'Instagram': Icons.camera_alt,
    'Zalo': Icons.chat_bubble,
    'Roblox': Icons.sports_esports,
    'Free Fire': Icons.local_fire_department,
  };

  IconData _getFallbackIcon() {
    return _appIconMap[appName] ?? Icons.apps;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: iconUrl != null && iconUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.2),
              child: Image.network(
                iconUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
              ),
            )
          : _buildFallbackIcon(),
    );
  }

  Widget _buildFallbackIcon() {
    return Icon(
      _getFallbackIcon(),
      size: size * 0.5,
      color: Colors.white,
    );
  }
}
