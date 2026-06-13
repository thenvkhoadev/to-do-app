import 'package:flutter/material.dart';
import 'design_system.dart';

class FaqSection extends StatelessWidget {
  const FaqSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'q': 'How does the AI optimize my schedule?',
        'a': 'Our AI analyzes your task completion speed, time-of-day energy levels, and historical "deep work" patterns. It then cross-references this with your calendar to suggest blocks where you\'re most likely to succeed.',
      },
      {
        'q': 'Is my data secure?',
        'a': 'Absolutely. We use end-to-end encryption for all task data and local-first AI processing where possible. Your productivity metrics are never sold or shared with third parties.',
      },
      {
        'q': 'What can I use XP for?',
        'a': 'XP unlocks "Pro" features like custom dashboard themes, exclusive profile badges, and advanced analytical widgets. It acts as a milestone tracker for your personal growth.',
      },
    ];

    final openIndex = ValueNotifier<int?>(null);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800.0),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          children: [
            Text(
              'Common Questions',
              style: getLandingGeistStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.w600,
                color: LandingColors.textPrimary,
                letterSpacing: -0.64,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32.0),
            ValueListenableBuilder<int?>(
              valueListenable: openIndex,
              builder: (context, activeIndex, _) {
                return Column(
                  children: List.generate(faqs.length, (index) {
                    final isOpen = activeIndex == index;
                    final faq = faqs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GlassCard(
                        borderRadius: 16.0,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            // Question header row
                            InkWell(
                              onTap: () {
                                openIndex.value = isOpen ? null : index;
                              },
                              borderRadius: BorderRadius.circular(16.0),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                  vertical: 24.0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        faq['q']!,
                                        style: getLandingGeistStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w700,
                                          color: LandingColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: isOpen ? 0.5 : 0.0,
                                      duration: const Duration(milliseconds: 300),
                                      child: const Icon(
                                        Icons.expand_more,
                                        color: LandingColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Answer description row (expandable)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: isOpen
                                  ? Container(
                                      width: double.infinity,
                                      color: Colors.white.withValues(alpha: 0.03),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32.0,
                                        vertical: 24.0,
                                      ),
                                      child: Text(
                                        faq['a']!,
                                        style: getLandingGeistStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.w400,
                                          color: LandingColors.textSecondary,
                                          height: 1.5,
                                        ),
                                      ),
                                    )
                                  : const SizedBox(width: double.infinity, height: 0.0),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
