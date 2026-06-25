import 'package:flutter/material.dart';

class PostBackground {
  final String id;
  final String? name;
  final Color? solidColor;
  final Gradient? gradient;
  final String? bgImageUrl;
  final Color textColor;

  const PostBackground({
    required this.id,
    this.name,
    this.solidColor,
    this.gradient,
    this.bgImageUrl,
    this.textColor = Colors.white,
  });

  Decoration getDecoration() {
    if (bgImageUrl != null) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(bgImageUrl!),
          fit: BoxFit.cover,
        ),
      );
    } else if (gradient != null) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: gradient,
      );
    } else if (solidColor != null) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: solidColor,
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: Colors.transparent,
    );
  }
}

final List<PostBackground> decorationBgs = [
  const PostBackground(
    id: 'dec_hearts',
    name: 'Trái tim',
    bgImageUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'dec_aurora',
    name: 'Cực quang',
    bgImageUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'dec_silk',
    name: 'Lụa',
    bgImageUrl: 'https://images.unsplash.com/photo-1506784983877-45594efa4cbe?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'dec_gold',
    name: 'Vàng rồng',
    bgImageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'dec_dark_wave',
    name: 'Sóng tối',
    bgImageUrl: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'dec_clouds',
    name: 'Mây mờ',
    bgImageUrl: 'https://images.unsplash.com/photo-1534088568595-a066f410bcda?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'dec_sunset',
    name: 'Hoàng hôn',
    bgImageUrl: 'https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'dec_neon',
    name: 'Neon',
    bgImageUrl: 'https://images.unsplash.com/photo-1507608869274-d3177c8bb4c7?w=500&auto=format&fit=crop&q=60',
    textColor: Colors.white,
  ),
];

final List<PostBackground> gradientBgs = [
  const PostBackground(
    id: 'grad_purple_pink',
    gradient: LinearGradient(
      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFF56040)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'grad_blue_purple',
    gradient: LinearGradient(
      colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'grad_orange_yellow',
    gradient: LinearGradient(
      colors: [Color(0xFFF12711), Color(0xFFF5AF19)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'grad_pink_yellow',
    gradient: LinearGradient(
      colors: [Color(0xFFEE9CA7), Color(0xFFFFDDE1)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Colors.black87,
  ),
  const PostBackground(
    id: 'grad_green_blue',
    gradient: LinearGradient(
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'grad_dark_grey',
    gradient: LinearGradient(
      colors: [Color(0xFF3A3D40), Color(0xFF181A1B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textColor: Colors.white,
  ),
];

final List<PostBackground> solidBgs = [
  const PostBackground(
    id: 'solid_white',
    solidColor: Colors.white,
    textColor: Colors.black87,
  ),
  const PostBackground(
    id: 'solid_grey',
    solidColor: Color(0xFF9E9E9E),
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'solid_dark',
    solidColor: Color(0xFF242526),
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'solid_pink',
    solidColor: Color(0xFFFFC0CB),
    textColor: Colors.black87,
  ),
  const PostBackground(
    id: 'solid_red',
    solidColor: Color(0xFFE41E3F),
    textColor: Colors.white,
  ),
  const PostBackground(
    id: 'solid_magenta',
    solidColor: Color(0xFFFF00FF),
    textColor: Colors.white,
  ),
];

final List<PostBackground> allBgs = [
  ...decorationBgs,
  ...gradientBgs,
  ...solidBgs,
];

PostBackground? getPostBackgroundById(String id) {
  try {
    return allBgs.firstWhere((bg) => bg.id == id);
  } catch (_) {
    return null;
  }
}
