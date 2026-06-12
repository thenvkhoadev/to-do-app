import 'dart:async';
import 'package:flutter/material.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class TaskFocusTimerCard extends StatefulWidget {
  const TaskFocusTimerCard({super.key});

  @override
  State<TaskFocusTimerCard> createState() => _TaskFocusTimerCardState();
}

class _TaskFocusTimerCardState extends State<TaskFocusTimerCard> {
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isHovered = false;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _secondsRemaining = 25 * 60;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Focus Session Completed! Take a break. ☕'),
              backgroundColor: DashboardColors.success,
            ),
          );
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = 25 * 60;
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsRemaining / (25 * 60);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _isHovered 
              ? const Color.fromRGBO(255, 255, 255, 0.04)
              : const Color.fromRGBO(255, 255, 255, 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered 
                ? DashboardColors.secondary.withValues(alpha: 0.15)
                : const Color.fromRGBO(255, 255, 255, 0.08),
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: DashboardColors.secondary.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FOCUS SESSION',
                  style: TextStyle(
                    color: DashboardColors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: _isRunning ? DashboardColors.secondary : DashboardColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Circular Progress Timer (Left)
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isRunning ? DashboardColors.secondary : DashboardColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(_secondsRemaining),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                // Timer Controls & Stats (Right)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRunning ? 'STAY FOCUSED' : 'READY TO FOCUS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isRunning ? DashboardColors.secondary : DashboardColors.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Boost productivity with 25-minute Pomodoro sprints.',
                        style: TextStyle(
                          fontSize: 10,
                          color: DashboardColors.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _TimerControlBtn(
                            onTap: _toggleTimer,
                            icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            isActive: _isRunning,
                          ),
                          const SizedBox(width: 8),
                          _TimerControlBtn(
                            onTap: _resetTimer,
                            icon: Icons.replay_rounded,
                            isActive: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerControlBtn extends StatefulWidget {
  const _TimerControlBtn({
    required this.onTap,
    required this.icon,
    required this.isActive,
  });

  final VoidCallback onTap;
  final IconData icon;
  final bool isActive;

  @override
  State<_TimerControlBtn> createState() => _TimerControlBtnState();
}

class _TimerControlBtnState extends State<_TimerControlBtn> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isActive ? DashboardColors.secondary : DashboardColors.primary;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeColor.withValues(alpha: 0.15)
                : (_isHovered ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03)),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isActive
                  ? activeColor.withValues(alpha: 0.3)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.isActive ? activeColor : DashboardColors.onSurface,
          ),
        ),
      ),
    );
  }
}
