import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_background.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({required this.title, required this.subtitle, required this.child, super.key});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.sizeOf(context).width >= 760 ? 48.0 : 16.0;

    return Scaffold(
      body: NexusBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Hero(
                      tag: 'nexus-logo',
                      child: Icon(Icons.bubble_chart_rounded, color: NexusColors.primary, size: 38),
                    ),
                    const SizedBox(height: 18),
                    Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: NexusColors.onSurfaceVariant, height: 1.5)),
                    const SizedBox(height: 28),
                    NexusGlassPanel(padding: const EdgeInsets.all(24), child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
