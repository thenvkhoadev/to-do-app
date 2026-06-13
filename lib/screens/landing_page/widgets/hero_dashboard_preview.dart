import 'package:flutter/material.dart';
import 'design_system.dart';
import 'floating_ai_card.dart';
import 'floating_xp_card.dart';
import 'floating_kanban_card.dart';

class HeroDashboardPreview extends StatelessWidget {
  const HeroDashboardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600.0,
      width: 600.0,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Nebula glow behind the dashboard
          Positioned(
            child: Container(
              width: 450.0,
              height: 450.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC0C1FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Dashboard Base with rotation on hover
          HoverBuilder(
            builder: (context, isHovered) {
              return AnimatedRotation(
                turns: isHovered ? 0.0 : -3 / 360,
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeInOutCubic,
                child: HeroDashboardBase(isHovered: isHovered),
              );
            },
          ),

          // Floating AI Insights Card (stagger 1: top: 40, right: -20)
          const Positioned(
            top: 40.0,
            right: -20.0,
            child: FloatingAiCard(),
          ),

          // Floating XP Card (stagger 2: bottom: 40, left: -40)
          const Positioned(
            bottom: 40.0,
            left: -40.0,
            child: FloatingXpCard(),
          ),

          // Floating Kanban Card (stagger 3: bottom: 160, right: -40)
          const Positioned(
            bottom: 160.0,
            right: -40.0,
            child: FloatingKanbanCard(),
          ),
        ],
      ),
    );
  }
}

class HeroDashboardBase extends StatelessWidget {
  final bool isHovered;

  const HeroDashboardBase({super.key, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500.0,
      height: 350.0,
      decoration: BoxDecoration(
        color: LandingColors.glassBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.20),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 32.0,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Browser chrome title bar
          Container(
            height: 32.0,
            decoration: BoxDecoration(
              color: const Color(0xFF242A3A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: LandingColors.errorRed.withValues(alpha: 0.50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: LandingColors.tertiary.withValues(alpha: 0.50),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    color: LandingColors.success.withValues(alpha: 0.50),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          // Dashboard Contents
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  // Left Columns (col-span-2)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16.0,
                          width: 150.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Container(
                          height: 72.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  
                  // Right Column (col-span-1)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
