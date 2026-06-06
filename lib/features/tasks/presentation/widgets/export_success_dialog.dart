import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class CopySuccessDialog extends StatefulWidget {
  final int count;
  final String format;
  const CopySuccessDialog({required this.count, required this.format, super.key});

  static Future<void> show(BuildContext context, int count, String format) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => CopySuccessDialog(count: count, format: format),
    );
  }

  @override
  State<CopySuccessDialog> createState() => _CopySuccessDialogState();
}

class _CopySuccessDialogState extends State<CopySuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryCtrl.forward();
    
    // Premium light impact haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  List<String> _getBadgesForFormat(String format) {
    final formatLower = format.toLowerCase();
    if (formatLower == 'sql') {
      return ['MySQL', 'PostgreSQL', 'SQLite'];
    } else if (formatLower == 'csv') {
      return ['Excel', 'Google Sheets', 'Numbers'];
    } else if (formatLower == 'json') {
      return ['VS Code', 'Postman', 'JSON Editor'];
    } else {
      return ['Text Editor', 'Clipboard'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final badges = _getBadgesForFormat(widget.format);
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const Positioned.fill(child: _AuroraBackground()),
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      width: 340,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF12182A),
                            Color(0xFF0A0F1E),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFC8B6FF),
                            size: 22,
                          ),
                          const SizedBox(height: 12),
                          const _CopyAnimation(),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.format.toUpperCase()} Copied',
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _AnimatedTaskCounterText(
                            count: widget.count,
                            template: '{n} tasks copied successfully',
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Ready to paste into:',
                            style: TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < badges.length; i++) ...[
                                _DatabaseBadge(name: badges[i]),
                                if (i < badges.length - 1) const SizedBox(width: 8),
                              ],
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_command_key,
                                size: 14,
                                color: DashboardColors.onSurfaceVariant,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'CTRL + V to paste  •  Click anywhere to close',
                                style: TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyAnimation extends StatefulWidget {
  const _CopyAnimation();

  @override
  State<_CopyAnimation> createState() => _CopyAnimationState();
}

class _CopyAnimationState extends State<_CopyAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _paperOpacity;
  late final Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _slide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _paperOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
      ),
    );

    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 60),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 15,
      ),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            child: _GlowBackground(color: Color(0xFFC8B6FF)),
          ),
          Positioned(
            child: Container(
              width: 60,
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: DashboardColors.primary,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slide.value, -6),
                child: Opacity(
                  opacity: _paperOpacity.value,
                  child: Container(
                    width: 40,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2333),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        3,
                        (index) => Container(
                          height: 2.5,
                          margin: const EdgeInsets.only(bottom: 4),
                          width: index == 1 ? 16 : 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 10,
            child: Container(
              width: 24,
              height: 10,
              decoration: const BoxDecoration(
                color: DashboardColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ),
          Positioned(
            bottom: 15,
            right: 64,
            child: ScaleTransition(
              scale: _checkScale,
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.tertiary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F131E),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: DashboardColors.tertiary,
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.black,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExportSuccessDialog extends StatefulWidget {
  final int count;
  final String format;
  final String fileName;
  final String? filePath;
  const ExportSuccessDialog({
    required this.count,
    required this.format,
    required this.fileName,
    this.filePath,
    super.key,
  });

  static Future<void> show(
    BuildContext context,
    int count,
    String format,
    String fileName,
    String? filePath,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => ExportSuccessDialog(
        count: count,
        format: format,
        fileName: fileName,
        filePath: filePath,
      ),
    );
  }

  @override
  State<ExportSuccessDialog> createState() => _ExportSuccessDialogState();
}

class _ExportSuccessDialogState extends State<ExportSuccessDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryCtrl.forward();

    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _openFile(String path) async {
    try {
      await OpenFilex.open(path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: $e')),
        );
      }
    }
  }

  Future<void> _openFolder(String path) async {
    try {
      final dirPath = File(path).parent.path;
      final uri = Uri.file(dirPath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(Uri.parse('file://$dirPath'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open directory: $e')),
        );
      }
    }
  }

  void _copyPath(String path) {
    Clipboard.setData(ClipboardData(text: path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied path to clipboard'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showFileActions = widget.filePath != null && !kIsWeb;
    
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              const Positioned.fill(child: _AuroraBackground()),
              Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Container(
                      width: 350,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF12182A),
                            Color(0xFF0A0F1E),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: Color(0xFFC8B6FF),
                            size: 22,
                          ),
                          const SizedBox(height: 12),
                          const _ExportAnimation(),
                          const SizedBox(height: 16),
                          Text(
                            '${widget.format.toUpperCase()} Exported',
                            style: const TextStyle(
                              color: DashboardColors.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _AnimatedTaskCounterText(
                            count: widget.count,
                            template: 'Exported {n} Tasks',
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '${widget.format.toUpperCase()} saved to',
                            style: const TextStyle(
                              color: DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Text(
                              widget.filePath ?? widget.fileName,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: DashboardColors.onSurfaceVariant,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          if (showFileActions) ...[
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _DialogActionButton(
                                  icon: Icons.insert_drive_file_outlined,
                                  label: 'Open File',
                                  color: DashboardColors.secondary,
                                  onTap: () => _openFile(widget.filePath!),
                                ),
                                _DialogActionButton(
                                  icon: Icons.folder_open_outlined,
                                  label: 'Open Folder',
                                  color: DashboardColors.secondary,
                                  onTap: () => _openFolder(widget.filePath!),
                                ),
                                _DialogActionButton(
                                  icon: Icons.copy_all_outlined,
                                  label: 'Copy Path',
                                  color: DashboardColors.secondary,
                                  onTap: () => _copyPath(widget.filePath!),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_tab,
                                size: 14,
                                color: DashboardColors.onSurfaceVariant,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ESC  •  Click Anywhere To Close',
                                style: TextStyle(
                                  color: DashboardColors.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportAnimation extends StatefulWidget {
  const _ExportAnimation();

  @override
  State<_ExportAnimation> createState() => _ExportAnimationState();
}

class _ExportAnimationState extends State<_ExportAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fileSlide;
  late final Animation<double> _arrowScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fileSlide = Tween<double>(begin: 20.0, end: -22.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.1, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _arrowScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 65),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 15,
      ),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            child: _GlowBackground(color: Color(0xFFC8B6FF)),
          ),
          Positioned(
            child: Container(
              width: 70,
              height: 52,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                border: Border.all(
                  color: DashboardColors.secondary.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _fileSlide,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _fileSlide.value),
                child: Container(
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2333),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 3,
                        width: 18,
                        decoration: BoxDecoration(
                          color: DashboardColors.secondary,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(
                        3,
                        (index) => Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 4),
                          width: index == 1 ? 16 : 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 19,
            child: Container(
              width: 70,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF0F131E).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
                border: Border(
                  left: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.8), width: 2),
                  right: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.8), width: 2),
                  bottom: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.8), width: 2),
                  top: BorderSide(color: DashboardColors.secondary.withValues(alpha: 0.8), width: 1.5),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 54,
            child: ScaleTransition(
              scale: _arrowScale,
              child: Container(
                decoration: BoxDecoration(
                  color: DashboardColors.secondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0F131E),
                    width: 2.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: DashboardColors.secondary,
                      blurRadius: 8,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuroraBackground extends StatefulWidget {
  const _AuroraBackground();

  @override
  State<_AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<_AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        final rad = t * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -80 + 30 * math.sin(rad),
              left: -80 + 30 * math.cos(rad),
              child: _GlowCircle(
                color: const Color(0xFFC8B6FF).withValues(alpha: 0.05),
                size: 250,
              ),
            ),
            Positioned(
              bottom: -90 + 25 * math.sin(rad + 2),
              right: -90 + 35 * math.cos(rad + 2),
              child: _GlowCircle(
                color: const Color(0xFF86BFFF).withValues(alpha: 0.05),
                size: 280,
              ),
            ),
            Positioned(
              top: 100 + 20 * math.cos(rad + 4),
              right: 20 + 25 * math.sin(rad + 4),
              child: _GlowCircle(
                color: const Color(0xFF7B2CBF).withValues(alpha: 0.03),
                size: 220,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}

class _GlowBackground extends StatefulWidget {
  final Color color;
  const _GlowBackground({required this.color});

  @override
  State<_GlowBackground> createState() => _GlowBackgroundState();
}

class _GlowBackgroundState extends State<_GlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _blurAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _blurAnim = Tween<double>(begin: 30.0, end: 60.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );

    _opacityAnim = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final blur = _blurAnim.value;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _opacityAnim.value),
                blurRadius: blur,
                spreadRadius: blur / 3,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedTaskCounterText extends StatefulWidget {
  final int count;
  final String template;
  final TextStyle style;
  const _AnimatedTaskCounterText({
    required this.count,
    required this.template,
    required this.style,
  });

  @override
  State<_AnimatedTaskCounterText> createState() => _AnimatedTaskCounterTextState();
}

class _AnimatedTaskCounterTextState extends State<_AnimatedTaskCounterText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _counterAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _counterAnim = IntTween(begin: 0, end: widget.count).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _counterAnim,
      builder: (context, child) {
        final text = widget.template.replaceAll('{n}', _counterAnim.value.toString());
        return Text(
          text,
          textAlign: TextAlign.center,
          style: widget.style,
        );
      },
    );
  }
}

class _DatabaseBadge extends StatelessWidget {
  final String name;
  const _DatabaseBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        name,
        style: const TextStyle(
          color: DashboardColors.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _DialogActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: color.withValues(alpha: 0.08),
        splashColor: color.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
