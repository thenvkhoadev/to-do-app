import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_background.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: NexusBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: 'nexus-logo',
                child: Icon(
                  Icons.bubble_chart_rounded,
                  color: NexusColors.primary,
                  size: 68,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'NEXUS AI',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Your cognitive command center',
                style: TextStyle(color: NexusColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
