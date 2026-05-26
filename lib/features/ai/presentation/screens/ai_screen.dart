import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:to_do_app/constants/dashboard_constants.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';
import 'package:to_do_app/widgets/dashboard/desktop_dashboard_widgets.dart';
import 'package:to_do_app/widgets/dashboard/mobile_dashboard_widgets.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: DashboardTheme.dark(),
      child: DashboardScaffold(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 1024) return const AiAssistantDesktopScreen();
            return const AiAssistantMobileScreen();
          },
        ),
      ),
    );
  }
}

class AiAssistantDesktopScreen extends StatelessWidget {
  const AiAssistantDesktopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DesktopSidebar(selectedIndex: 2, onSelected: (index) => _goDesktop(context, index)),
        const Expanded(child: DesktopAiAssistantContent()),
      ],
    );
  }

  void _goDesktop(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/tasks');
      case 2:
        context.go('/ai');
      case 3:
        context.go('/calendar');
      case 5:
        context.go('/profile');
      default:
        context.go('/home');
    }
  }
}

class DesktopAiAssistantContent extends StatelessWidget {
  const DesktopAiAssistantContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AiAssistantHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(flex: 3, child: ChatSection()),
                SizedBox(width: 24),
                SizedBox(width: 420, child: IntelligencePanel()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AiAssistantHeader extends StatelessWidget {
  const AiAssistantHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: DashboardColors.surface.withValues(alpha: .50),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08))),
      ),
      child: const Row(
        children: [
          Icon(Icons.chat_bubble_rounded, color: DashboardColors.primary),
          SizedBox(width: 12),
          Text('AI Assistant', style: TextStyle(color: DashboardColors.primary, fontSize: 24, fontWeight: FontWeight.w900)),
          Spacer(),
          _HeaderIcon(icon: Icons.notifications_none_rounded),
          SizedBox(width: 12),
          ProfileAvatar(),
        ],
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      tooltip: 'Notifications',
      icon: Icon(icon, color: DashboardColors.onSurfaceVariant),
    );
  }
}

class ChatSection extends StatelessWidget {
  const ChatSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: DashboardRadii.xl,
      child: Column(
        children: const [
          Expanded(child: _DesktopChatList()),
          Divider(height: 1, color: Color(0x1AFFFFFF)),
          Padding(
            padding: EdgeInsets.all(24),
            child: AiInputArea(),
          ),
        ],
      ),
    );
  }
}

class _DesktopChatList extends StatelessWidget {
  const _DesktopChatList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: const [
        AiOrbHero(compact: false),
        SizedBox(height: 32),
        ChatMessageBubble(
          alignment: ChatMessageAlignment.user,
          message: 'My afternoon feels cluttered. I have three back-to-back meetings starting at 2 PM. Can we re-organize for better deep work?',
        ),
        SizedBox(height: 22),
        ChatMessageBubble(
          alignment: ChatMessageAlignment.assistant,
          message: 'I analyzed your priorities and focus rhythm. Move Sync with Design to tomorrow at 10 AM and protect a 2.5 hour Deep Work block now. Want me to prepare the schedule changes?',
          actions: ['Yes, reschedule', 'Show alternative'],
        ),
        SizedBox(height: 22),
        TypingIndicator(),
      ],
    );
  }
}

class AiInputArea extends StatelessWidget {
  const AiInputArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AiSuggestionChip(icon: Icons.auto_fix_high_rounded, label: 'Re-organize my afternoon'),
              SizedBox(width: 10),
              AiSuggestionChip(icon: Icons.summarize_rounded, label: 'Summarize my day'),
              SizedBox(width: 10),
              AiSuggestionChip(icon: Icons.event_repeat_rounded, label: 'Check tomorrow\'s load'),
            ],
          ),
        ),
        SizedBox(height: 16),
        AiInputBar(),
      ],
    );
  }
}

class AiInputBar extends StatelessWidget {
  const AiInputBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      decoration: BoxDecoration(
        color: DashboardColors.surfaceContainer.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
        boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .08), blurRadius: 24)],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Type a command or question...',
                hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .75)),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            tooltip: 'Voice input',
            icon: const Icon(Icons.mic_none_rounded, color: DashboardColors.outline),
          ),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [DashboardColors.primary, DashboardColors.secondary]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .28), blurRadius: 18)],
            ),
            child: IconButton(
              onPressed: () {},
              tooltip: 'Send',
              icon: const Icon(Icons.arrow_upward_rounded, color: DashboardColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

enum ChatMessageAlignment { user, assistant }

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({required this.alignment, required this.message, this.actions = const [], super.key});

  final ChatMessageAlignment alignment;
  final String message;
  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    final isUser = alignment == ChatMessageAlignment.user;

    return Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          const _AssistantAvatar(),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isUser ? DashboardColors.surfaceHigh.withValues(alpha: .82) : DashboardColors.primaryContainer.withValues(alpha: .16),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isUser ? 22 : 6),
                topRight: Radius.circular(isUser ? 6 : 22),
                bottomLeft: const Radius.circular(22),
                bottomRight: const Radius.circular(22),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              boxShadow: !isUser ? [BoxShadow(color: DashboardColors.primary.withValues(alpha: .10), blurRadius: 22)] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 16, height: 1.5)),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final action in actions) _MessageAction(label: action)],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageAction extends StatelessWidget {
  const _MessageAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: DashboardColors.primary,
        side: BorderSide(color: DashboardColors.primary.withValues(alpha: .28)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DashboardRadii.full)),
      ),
      child: Text(label),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [DashboardColors.primary, DashboardColors.secondary])),
      child: const Icon(Icons.auto_awesome_rounded, color: DashboardColors.onPrimary, size: 18),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _AssistantAvatar(),
        const SizedBox(width: 12),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          radius: 18,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _TypingDot(delay: 0),
              SizedBox(width: 5),
              _TypingDot(delay: 120),
              SizedBox(width: 5),
              _TypingDot(delay: 240),
              SizedBox(width: 10),
              Text('Thinking...', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .35, end: 1),
      duration: Duration(milliseconds: 900 + delay),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Opacity(opacity: value, child: Transform.scale(scale: value, child: child)),
      child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: DashboardColors.primary, shape: BoxShape.circle)),
    );
  }
}

class AiSuggestionChip extends StatelessWidget {
  const AiSuggestionChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: DashboardRadii.full,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(DashboardRadii.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: DashboardColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class AiOrbHero extends StatelessWidget {
  const AiOrbHero({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AiOrbWidget(size: compact ? 96 : 112),
        SizedBox(height: compact ? 18 : 22),
        GradientText(text: compact ? 'How can I optimize your flow?' : 'How can I help optimize your flow today?', fontSize: compact ? 30 : 34),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: const Text(
            'I analyzed your schedule for the next 48 hours and found the best windows for deep work.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 16, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class AiOrbWidget extends StatelessWidget {
  const AiOrbWidget({this.size = 104, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .94, end: 1.05),
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [DashboardColors.primary, DashboardColors.secondary]),
          boxShadow: [
            BoxShadow(color: DashboardColors.primary.withValues(alpha: .38), blurRadius: 56, spreadRadius: 10),
            BoxShadow(color: DashboardColors.secondary.withValues(alpha: .20), blurRadius: 80, spreadRadius: 8),
          ],
        ),
        child: const Icon(Icons.psychology_rounded, color: DashboardColors.onPrimary, size: 48),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  const GradientText({required this.text, this.fontSize = 32, super.key});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(colors: [DashboardColors.primary, DashboardColors.secondary]).createShader(rect),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: fontSize, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -.7),
      ),
    );
  }
}

class IntelligencePanel extends StatelessWidget {
  const IntelligencePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Row(
            children: [
              Expanded(child: Text('Intelligence Hub', style: TextStyle(color: DashboardColors.onSurface, fontSize: 24, fontWeight: FontWeight.w900))),
              Icon(Icons.insights_rounded, color: DashboardColors.secondary),
            ],
          ),
          SizedBox(height: 24),
          FocusTrendsCard(),
          SizedBox(height: 24),
          ProductivityInsightCard(),
          SizedBox(height: 24),
          SmartSuggestionsCard(),
          SizedBox(height: 24),
          AiStatusCard(),
        ],
      ),
    );
  }
}

class FocusTrendsCard extends StatelessWidget {
  const FocusTrendsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      radius: DashboardRadii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [SectionTitle(label: 'Focus Trends'), Spacer(), Text('+12% vs last week', style: TextStyle(color: DashboardColors.secondary, fontSize: 12, fontWeight: FontWeight.w800))]),
          SizedBox(height: 18),
          AnalyticsBars(values: [.40, .65, .50, .90, .30, .55, .70], labels: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']),
        ],
      ),
    );
  }
}

class ProductivityInsightCard extends StatelessWidget {
  const ProductivityInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: DashboardRadii.xl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Peak Productivity', style: TextStyle(color: DashboardColors.onSurface, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          const Row(children: [Text('09:00 - 11:30', style: TextStyle(color: DashboardColors.onSurfaceVariant)), Spacer(), Text('94% Flow', style: TextStyle(color: DashboardColors.secondary, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(DashboardRadii.full),
            child: LinearProgressIndicator(value: .94, minHeight: 9, backgroundColor: Colors.white.withValues(alpha: .06), color: DashboardColors.secondary),
          ),
          const SizedBox(height: 14),
          const Text('Your cognitive load is lowest during these hours. Protect this time for Deep Work.', style: TextStyle(color: DashboardColors.onSurfaceVariant, height: 1.45, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class SmartSuggestionsCard extends StatelessWidget {
  const SmartSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label: 'Smart Suggestions'),
        SizedBox(height: 14),
        _SmartSuggestion(icon: Icons.bedtime_rounded, title: 'Digital Detox', subtitle: 'Mute Slack for 60 mins to finish Project Phoenix draft.', color: DashboardColors.tertiary),
        SizedBox(height: 12),
        _SmartSuggestion(icon: Icons.timer_rounded, title: 'Deep Work Block', subtitle: 'Scheduled for 3:00 PM. AI will handle incoming calls.', color: DashboardColors.primary),
      ],
    );
  }
}

class _SmartSuggestion extends StatelessWidget {
  const _SmartSuggestion({required this.icon, required this.title, required this.subtitle, required this.color});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: DashboardRadii.lg,
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: DashboardColors.onSurface, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12, height: 1.4))])),
          const Icon(Icons.chevron_right_rounded, color: DashboardColors.outline),
        ],
      ),
    );
  }
}

class AiStatusCard extends StatelessWidget {
  const AiStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: DashboardRadii.xl,
      glowColor: DashboardColors.primary,
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TaskFlow Engine', style: TextStyle(color: DashboardColors.primary, fontSize: 12, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('98.2%', style: TextStyle(color: DashboardColors.onSurface, fontSize: 42, height: 1, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Optimization Efficiency', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          SizedBox(width: 58, height: 58, child: CircularProgressIndicator(value: .982, strokeWidth: 5, color: DashboardColors.primary, backgroundColor: Colors.white.withValues(alpha: .08))),
        ],
      ),
    );
  }
}

class AiAssistantMobileScreen extends StatelessWidget {
  const AiAssistantMobileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        const Positioned.fill(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: 88)),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(DashboardSpacing.md, 0, DashboardSpacing.md, 168),
                sliver: SliverToBoxAdapter(child: MobileAiAssistantContent()),
              ),
            ],
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: MobileTopBar()),
        Positioned(left: 16, right: 16, bottom: 82 + bottomInset, child: const AiInputBar()),
        Positioned(left: 0, right: 0, bottom: 0, child: MobileBottomNavBar(bottomInset: bottomInset)),
      ],
    );
  }
}

class MobileAiAssistantContent extends StatelessWidget {
  const MobileAiAssistantContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AiOrbHero(compact: true),
        SizedBox(height: 28),
        MobileInsightGrid(),
        SizedBox(height: 28),
        ChatMessageBubble(alignment: ChatMessageAlignment.user, message: 'Can you help me re-organize my afternoon? I have a sudden meeting at 3 PM.'),
        SizedBox(height: 18),
        ChatMessageBubble(
          alignment: ChatMessageAlignment.assistant,
          message: 'I shifted Project Alpha review to tomorrow morning and compressed email triage to 15 minutes. Your 3 PM meeting stays clear without missing deadlines.',
          actions: ['Apply Changes', 'View Schedule'],
        ),
        SizedBox(height: 18),
        TypingIndicator(),
        SizedBox(height: 28),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AiSuggestionChip(icon: Icons.summarize_rounded, label: 'Summarize my day'),
              SizedBox(width: 10),
              AiSuggestionChip(icon: Icons.event_repeat_rounded, label: 'Re-schedule tasks'),
              SizedBox(width: 10),
              AiSuggestionChip(icon: Icons.psychology_rounded, label: 'Focus tips'),
            ],
          ),
        ),
      ],
    );
  }
}

class MobileInsightGrid extends StatelessWidget {
  const MobileInsightGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return const Row(
            children: [
              Expanded(child: MobileInsightCard(icon: Icons.insights_rounded, label: 'Smart Insight', title: 'Focus peaks at 10 AM', body: 'Schedule deep work between 9:30 and 11:30.')),
              SizedBox(width: 16),
              Expanded(child: MobileInsightCard(icon: Icons.bolt_rounded, label: 'Actionable Tip', title: 'Quick Wins Available', body: 'Clear 3 tasks under 5 minutes to reduce cognitive load.')),
            ],
          );
        }

        return const Column(
          children: [
            MobileInsightCard(icon: Icons.insights_rounded, label: 'Smart Insight', title: 'Focus peaks at 10 AM', body: 'Schedule deep work between 9:30 and 11:30.'),
            SizedBox(height: 16),
            MobileInsightCard(icon: Icons.bolt_rounded, label: 'Actionable Tip', title: 'Quick Wins Available', body: 'Clear 3 tasks under 5 minutes to reduce cognitive load.'),
          ],
        );
      },
    );
  }
}

class MobileInsightCard extends StatelessWidget {
  const MobileInsightCard({required this.icon, required this.label, required this.title, required this.body, super.key});

  final IconData icon;
  final String label;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: DashboardRadii.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: DashboardColors.primary, size: 20), const SizedBox(width: 8), Text(label.toUpperCase(), style: const TextStyle(color: DashboardColors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2))]),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: DashboardColors.onSurface, fontSize: 22, height: 1.2, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: DashboardColors.onSurfaceVariant, height: 1.45)),
        ],
      ),
    );
  }
}
