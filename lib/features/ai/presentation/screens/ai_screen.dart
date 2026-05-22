import 'package:flutter/material.dart';
import 'package:to_do_app/core/theme/nexus_colors.dart';
import 'package:to_do_app/shared/widgets/nexus_glass_panel.dart';
import 'package:to_do_app/shared/widgets/nexus_gradient_button.dart';
import 'package:to_do_app/shared/widgets/responsive_page.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nexus AI', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Ask for plans, prioritization, or task breakdowns.', style: TextStyle(color: NexusColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          NexusGlassPanel(
            glowColor: NexusColors.secondary.withValues(alpha: 0.18),
            child: Column(
              children: [
                const TextField(
                  minLines: 5,
                  maxLines: 8,
                  decoration: InputDecoration(hintText: 'Break down my product launch into focused tasks...'),
                ),
                const SizedBox(height: 16),
                NexusGradientButton(label: 'Generate plan', icon: Icons.auto_awesome_rounded, onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _PromptChip(label: 'Plan my week'),
              _PromptChip(label: 'Prioritize today'),
              _PromptChip(label: 'Create deep work block'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), avatar: const Icon(Icons.bolt_rounded, size: 16));
  }
}
