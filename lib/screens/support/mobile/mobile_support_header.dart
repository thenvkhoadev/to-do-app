import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class MobileSupportHeader extends StatelessWidget {
  const MobileSupportHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: DashboardSpacing.md),
            decoration: BoxDecoration(color: DashboardColors.background.withValues(alpha: .78), border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .06)))),
            child: const Row(children: [Icon(Icons.arrow_back_rounded, color: DashboardColors.onSurface), SizedBox(width: 16), Expanded(child: Text('Support', style: TextStyle(color: DashboardColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900))), Icon(Icons.history_edu_rounded, color: DashboardColors.onSurfaceVariant)]),
          ),
        ),
      ),
    );
  }
}
