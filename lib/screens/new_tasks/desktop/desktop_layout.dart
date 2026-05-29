import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class NewTasksDesktopLayout extends StatelessWidget {
  const NewTasksDesktopLayout({this.onClose, super.key});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _DesktopBackdrop(),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _TaskCommandPanel(onClose: onClose),
          ),
        ),
      ],
    );
  }
}

class _TaskCommandPanel extends StatelessWidget {
  const _TaskCommandPanel({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: DashboardColors.primary.withValues(alpha: .20)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 48, offset: const Offset(0, 28)),
              BoxShadow(color: DashboardColors.primary.withValues(alpha: .12), blurRadius: 34),
            ],
          ),
          child: Column(
            children: [_Header(onClose: onClose), const Expanded(child: _Body()), const _Footer()],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .05),
        border: Border(bottom: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .10))),
      ),
      child: Row(
        children: [
          const Icon(Icons.add_task_rounded, color: DashboardColors.primary, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Task', style: GoogleFonts.interTight(fontSize: 24, fontWeight: FontWeight.w700, color: DashboardColors.onSurface)),
                const SizedBox(height: 4),
                Text('Deep Work Orchestration', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: DashboardColors.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: DashboardColors.primary.withValues(alpha: .30)),
              boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .15), blurRadius: 30)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .75, end: 1),
                  duration: const Duration(milliseconds: 900),
                  builder: (_, value, child) => Transform.scale(scale: value, child: Opacity(opacity: value, child: child)),
                  child: const Icon(Icons.psychology_rounded, color: DashboardColors.primary, size: 16),
                ),
                const SizedBox(width: 8),
                Text('AI PRIORITY: AUTO', style: GoogleFonts.jetBrainsMono(fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: DashboardColors.primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded), color: DashboardColors.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(flex: 7, child: _MainForm()),
          const SizedBox(width: 32),
          Expanded(flex: 5, child: Column(children: const [_AiMetadataCard(), SizedBox(height: 32), _AttachmentCard()])),
        ],
      ),
    );
  }
}

class _MainForm extends StatelessWidget {
  const _MainForm();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      _Label('TASK TITLE'),
      _TitleField(),
      SizedBox(height: 32),
      _Label('DESCRIPTION'),
      _DescriptionField(),
      SizedBox(height: 32),
      _SubtasksSection(),
    ]);
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      style: GoogleFonts.interTight(fontSize: 32, height: 1.2, fontWeight: FontWeight.w700, color: DashboardColors.onSurface),
      decoration: InputDecoration(
        hintText: 'What needs to be achieved?',
        hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .30)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .30))),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: DashboardColors.primary)),
      ),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  const _DescriptionField();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(maxLines: 4, style: GoogleFonts.inter(fontSize: 16, height: 1.5), decoration: const InputDecoration.collapsed(hintText: 'Outline the objective and requirements...')),
        const SizedBox(height: 16),
        Row(children: const [Icon(Icons.format_bold_rounded, size: 20), SizedBox(width: 10), Icon(Icons.format_italic_rounded, size: 20), SizedBox(width: 10), Icon(Icons.link_rounded, size: 20), Spacer(), Icon(Icons.auto_awesome_rounded, color: DashboardColors.primary, size: 20)]),
      ]),
    );
  }
}

class _SubtasksSection extends StatelessWidget {
  const _SubtasksSection();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const _Label('SUBTASKS'), const Spacer(), Text('＋ Generate with AI', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: DashboardColors.primary))]),
      const SizedBox(height: 12),
      const _SubtaskRow('Define core project architecture'),
      const SizedBox(height: 8),
      const _SubtaskRow('Draft stakeholder communication plan'),
      const SizedBox(height: 8),
      _GlassBox(dashed: true, padding: const EdgeInsets.all(12), child: Row(children: const [Icon(Icons.add_rounded, color: DashboardColors.outline, size: 20), SizedBox(width: 12), Text('Add another subtask...', style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 14))])),
    ]);
  }
}

class _SubtaskRow extends StatelessWidget {
  const _SubtaskRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return _GlassBox(padding: const EdgeInsets.all(12), child: Row(children: [const Icon(Icons.check_box_outline_blank_rounded, color: DashboardColors.outline, size: 20), const SizedBox(width: 12), Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14)))]));
  }
}

class _AiMetadataCard extends StatelessWidget {
  const _AiMetadataCard();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      tint: DashboardColors.primary.withValues(alpha: .05),
      borderColor: DashboardColors.primary.withValues(alpha: .20),
      padding: const EdgeInsets.all(24),
      child: Stack(children: [
        Positioned(top: -48, right: -48, child: _Glow(size: 128, color: DashboardColors.primary.withValues(alpha: .08))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          _Label('INTELLIGENCE SUGGESTIONS', color: DashboardColors.primary),
          SizedBox(height: 12),
          _SuggestionCard(),
          SizedBox(height: 24),
          Row(children: [Expanded(child: _MetaTile(label: 'DUE DATE', icon: Icons.event_rounded, value: 'Nov 24, 2023')), SizedBox(width: 16), Expanded(child: _MetaTile(label: 'ESTIMATE', icon: Icons.timer_rounded, value: '4 hours'))]),
          SizedBox(height: 24),
          _TagsBlock(),
        ]),
      ]),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      tint: DashboardColors.surface.withValues(alpha: .40),
      borderColor: DashboardColors.primary.withValues(alpha: .10),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.trending_up_rounded, color: DashboardColors.primary, size: 16), const SizedBox(width: 8), Text('Dynamic Priority: High', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800))]),
        const SizedBox(height: 8),
        Text('Based on your upcoming Project X deadline on Friday, this task should be completed by Wednesday morning for optimal flow.', style: GoogleFonts.inter(fontSize: 12, height: 1.45, color: DashboardColors.onSurfaceVariant)),
      ]),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.icon, required this.value});
  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label(label),
      const SizedBox(height: 8),
      _GlassBox(padding: const EdgeInsets.all(12), child: Row(children: [Icon(icon, color: DashboardColors.primary, size: 16), const SizedBox(width: 8), Flexible(child: Text(value, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 14)))])),
    ]);
  }
}

class _TagsBlock extends StatelessWidget {
  const _TagsBlock();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Label('TAGS & LABELS'),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: const [_Tag('#Strategy', DashboardColors.secondary), _Tag('#DeepWork', DashboardColors.tertiary), _AddTag()]),
    ]);
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Label('ATTACHMENTS'),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .20), width: 2)),
        child: Column(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .05), shape: BoxShape.circle), child: const Icon(Icons.upload_file_rounded)),
          const SizedBox(height: 12),
          Text.rich(TextSpan(children: [TextSpan(text: 'Upload files', style: GoogleFonts.inter(color: DashboardColors.primary, fontWeight: FontWeight.w800)), TextSpan(text: ' or drag and drop', style: GoogleFonts.inter(color: DashboardColors.onSurfaceVariant))])),
          const SizedBox(height: 8),
          Text('PDF, PNG, JPG up to 10MB', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.outline)),
        ]),
      ),
    ]);
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(color: DashboardColors.surfaceHigh),
      child: Row(children: [
        const CircleAvatar(radius: 16, backgroundColor: DashboardColors.primaryContainer, child: Icon(Icons.person_rounded, size: 16, color: DashboardColors.onPrimary)),
        Transform.translate(offset: const Offset(-8, 0), child: const CircleAvatar(radius: 16, backgroundColor: DashboardColors.surfaceHighest, child: Icon(Icons.person_add_rounded, size: 14))),
        Text('Assign to team members', style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.onSurfaceVariant)),
        const Spacer(),
        OutlinedButton(onPressed: () {}, child: const Text('Save Draft')),
        const SizedBox(width: 16),
        DecoratedBox(
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [DashboardColors.primary, DashboardColors.secondary]), borderRadius: BorderRadius.circular(999), boxShadow: [BoxShadow(color: DashboardColors.primary.withValues(alpha: .30), blurRadius: 20)]),
          child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: DashboardColors.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18)), onPressed: () {}, icon: const Icon(Icons.rocket_launch_rounded, size: 16), label: const Text('Deploy Task')),
        ),
      ]),
    );
  }
}

class _GlassBox extends StatelessWidget {
  const _GlassBox({required this.child, this.padding, this.tint, this.borderColor, this.dashed = false});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final Color? borderColor;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(color: tint ?? Colors.white.withValues(alpha: .03), borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor ?? DashboardColors.onSurface.withValues(alpha: dashed ? .14 : .08))),
          child: child,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.color});
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(text, style: GoogleFonts.jetBrainsMono(fontSize: 12, height: 1, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: color ?? DashboardColors.onSurfaceVariant));
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withValues(alpha: .22))), child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: color)));
}

class _AddTag extends StatelessWidget {
  const _AddTag();

  @override
  Widget build(BuildContext context) => Container(width: 32, height: 28, decoration: BoxDecoration(borderRadius: BorderRadius.circular(999), border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .30))), child: const Icon(Icons.add_rounded, size: 16));
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)]));
}

class _DesktopBackdrop extends StatelessWidget {
  const _DesktopBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardColors.surfaceLowest,
      child: Stack(children: [
        Positioned(top: -120, right: -80, child: _Glow(size: 420, color: DashboardColors.primary.withValues(alpha: .07))),
        Positioned(bottom: -140, left: -100, child: _Glow(size: 340, color: DashboardColors.secondary.withValues(alpha: .08))),
        Center(
          child: Opacity(
            opacity: .20,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BackdropHeader(),
                  const SizedBox(height: 32),
                  const Row(
                    children: [
                      Expanded(child: _BackdropCard()),
                      SizedBox(width: 24),
                      Expanded(child: _BackdropCard()),
                      SizedBox(width: 24),
                      Expanded(child: _BackdropCard()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: ColoredBox(color: DashboardColors.surfaceLowest.withValues(alpha: .40))),
      ]),
    );
  }
}

class _BackdropHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(children: [Text('Active Workspace', style: GoogleFonts.interTight(fontSize: 48, fontWeight: FontWeight.w800)), const Spacer(), Container(width: 128, height: 40, decoration: BoxDecoration(color: DashboardColors.surfaceContainer, borderRadius: BorderRadius.circular(8))), const SizedBox(width: 16), Container(width: 128, height: 40, decoration: BoxDecoration(color: DashboardColors.primary, borderRadius: BorderRadius.circular(8)))]);
}

class _BackdropCard extends StatelessWidget {
  const _BackdropCard();

  @override
  Widget build(BuildContext context) => _GlassBox(padding: const EdgeInsets.all(24), child: const SizedBox(height: 208));
}
