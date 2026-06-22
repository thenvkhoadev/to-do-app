import 'package:flutter/material.dart';

class DesignTokens {
  // Màu nền
  static const bgPrimary = Color(0xFF0B0B12);
  static const bgCard = Color(0xFF13131C); // tối hơn nền chính 1 cấp
  static const borderSubtle = Color(0x14FFFFFF); // rgba(255,255,255,0.08)

  // Gradient chính (dùng cho mọi nút primary)
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF7C5CFF), Color(0xFFA78BFA)],
  );

  // Trạng thái
  static const onlineGreen = Color(0xFF22C55E);
  static const badgeRed = Color(0xFFEF4444);

  // Bo góc
  static const radiusCard = 18.0;
  static const radiusPill = 999.0;

  // Avatar size
  static const avatarSm = 32.0;
  static const avatarMd = 48.0;
  static const avatarLg = 56.0;   // dùng cho Story ring
  static const avatarXl = 120.0;  // Profile header
}
