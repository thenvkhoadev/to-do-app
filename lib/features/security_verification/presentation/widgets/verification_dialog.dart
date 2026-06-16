import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_engine.dart';
import 'package:to_do_app/features/security_verification/domain/challenge_result.dart';
import 'package:to_do_app/features/security_verification/presentation/providers/challenge_controller.dart';
import 'package:to_do_app/screens/auth/components/shared_components.dart';

class VerificationDialog extends ConsumerStatefulWidget {
  const VerificationDialog({super.key});

  static Future<ChallengeResult?> show(BuildContext context) {
    return showDialog<ChallengeResult>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      barrierDismissible: false,
      builder: (_) => const VerificationDialog(),
    );
  }

  @override
  ConsumerState<VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends ConsumerState<VerificationDialog>
    with TickerProviderStateMixin {
  final _answerController = TextEditingController();
  final Set<String> _selected = {};
  final List<int> _sortValues = [];
  double _sliderValue = 0;
  double _puzzleDx = 0;
  double _puzzleDy = 0;
  double _rotation = math.pi;
  bool _memoryVisible = true;
  bool _submittingChallenge = false;
  Timer? _memoryTimer;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(challengeControllerProvider.notifier).start();
      _resetLocalState();
    });
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    _closeTimer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _resetLocalState() {
    _answerController.clear();
    _selected.clear();
    _sortValues.clear();
    _sliderValue = 0;
    _rotation = math.pi;
    _memoryVisible = true;
    _submittingChallenge = false;
    _memoryTimer?.cancel();
    final challenge = ref.read(challengeControllerProvider).currentChallenge;
    if (challenge?.type == ChallengeType.imagePuzzle) {
      _puzzleDx = -120.0 - math.Random().nextInt(20);
      _puzzleDy = 0.0;
    } else {
      _puzzleDx = 0.0;
      _puzzleDy = 0.0;
    }
    if (challenge?.mode == ChallengeAnswerMode.memory) {
      _memoryTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _memoryVisible = false);
      });
    }
  }

  void _submit(Object? answer) {
    if (_submittingChallenge) return;
    _submittingChallenge = true;
    final passed = ref.read(challengeControllerProvider.notifier).submit(answer);
    final state = ref.read(challengeControllerProvider);
    if (state.status == ChallengeFlowStatus.completed && state.result != null) {
      _closeTimer?.cancel();
      _closeTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop(state.result);
        }
      });
      return;
    }
    if (passed) {
      setState(_resetLocalState);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(challengeControllerProvider);
    final challenge = state.currentChallenge;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: ModalRoute.of(context)!.animation!,
            curve: Curves.easeOutBack,
          ),
          child: FadeTransition(
            opacity: ModalRoute.of(context)!.animation!,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  width: math.min(MediaQuery.sizeOf(context).width - 32, 460),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xEE081120),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF1B2A44)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 44,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: state.status == ChallengeFlowStatus.failed
                        ? _FailedView(onRetry: () {
                            ref.read(challengeControllerProvider.notifier).retry();
                            setState(_resetLocalState);
                          })
                        : state.status == ChallengeFlowStatus.completed
                            ? const _SuccessView()
                            : challenge == null
                                ? const SizedBox(
                                    height: 180,
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                : _ChallengeView(
                                    key: ValueKey('${challenge.type.id}-${state.currentIndex}'),
                                    challenge: challenge,
                                    step: state.currentIndex + 1,
                                    total: state.totalSteps,
                                    answerController: _answerController,
                                    selected: _selected,
                                    sortValues: _sortValues,
                                    sliderValue: _sliderValue,
                                    puzzleDx: _puzzleDx,
                                    puzzleDy: _puzzleDy,
                                    rotation: _rotation,
                                    memoryVisible: _memoryVisible,
                                    onChanged: () => setState(() {}),
                                    onSliderChanged: (v) {
                                      setState(() => _sliderValue = v);
                                      if (v >= 0.96) _submit('complete');
                                    },
                                    onPuzzleChanged: (dx, dy) {
                                      setState(() {
                                        _puzzleDx = dx;
                                        _puzzleDy = dy;
                                      });
                                    },
                                    onRotationChanged: (v) {
                                      setState(() => _rotation = v);
                                      final normalized = ((v % (math.pi * 2)) + math.pi * 2) % (math.pi * 2);
                                      if (normalized < 0.18 || normalized > math.pi * 2 - 0.18) {
                                        _submit(0.0);
                                      }
                                    },
                                    onSubmit: _submit,
                                  ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChallengeView extends StatelessWidget {
  const _ChallengeView({
    required this.challenge,
    required this.step,
    required this.total,
    required this.answerController,
    required this.selected,
    required this.sortValues,
    required this.sliderValue,
    required this.puzzleDx,
    required this.puzzleDy,
    required this.rotation,
    required this.memoryVisible,
    required this.onChanged,
    required this.onSliderChanged,
    required this.onPuzzleChanged,
    required this.onRotationChanged,
    required this.onSubmit,
    super.key,
  });

  final Challenge challenge;
  final int step;
  final int total;
  final TextEditingController answerController;
  final Set<String> selected;
  final List<int> sortValues;
  final double sliderValue;
  final double puzzleDx;
  final double puzzleDy;
  final double rotation;
  final bool memoryVisible;
  final VoidCallback onChanged;
  final ValueChanged<double> onSliderChanged;
  final void Function(double dx, double dy) onPuzzleChanged;
  final ValueChanged<double> onRotationChanged;
  final ValueChanged<Object?> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('challenge'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Hero(
                  tag: 'security-verification-shield',
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8FF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF1B2A44)),
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFFE2E8FF)),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SECURITY CHECK', style: getGeistStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: const Color(0xFFE2E8FF))),
                    const SizedBox(height: 4),
                    Text('Challenge $step of $total', style: getGeistStyle(fontSize: 13, fontWeight: FontWeight.w500, color: RegisterColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20.0),
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(null),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: step / total,
            backgroundColor: const Color(0xFF1B2A44),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE2E8FF)),
          ),
        ),
        const SizedBox(height: 24),
        Text(challenge.prompt, textAlign: TextAlign.center, style: getGeistStyle(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFFE2E8FF), height: 1.25)),
        const SizedBox(height: 22),
        _body(),
      ],
    );
  }

  Widget _body() {
    return switch (challenge.mode) {
      ChallengeAnswerMode.text => _TextAnswer(challenge: challenge, controller: answerController, onSubmit: onSubmit),
      ChallengeAnswerMode.memory => _MemoryAnswer(challenge: challenge, visible: memoryVisible, controller: answerController, onSubmit: onSubmit),
      ChallengeAnswerMode.singleChoice => _ChoiceGrid(challenge: challenge, selected: selected, multi: false, onChanged: onChanged, onSubmit: onSubmit),
      ChallengeAnswerMode.multiChoice => _ChoiceGrid(challenge: challenge, selected: selected, multi: true, onChanged: onChanged, onSubmit: onSubmit),
      ChallengeAnswerMode.slider => _SliderAnswer(value: sliderValue, onChanged: onSliderChanged),
      ChallengeAnswerMode.puzzle => _PuzzleAnswer(
          challenge: challenge,
          dx: puzzleDx,
          dy: puzzleDy,
          onChanged: onPuzzleChanged,
          onSubmit: onSubmit,
        ),
      ChallengeAnswerMode.sort => _SortAnswer(challenge: challenge, values: sortValues, onSubmit: onSubmit),
      ChallengeAnswerMode.rotate => _RotateAnswer(rotation: rotation, onChanged: onRotationChanged),
    };
  }
}

class _TextAnswer extends StatelessWidget {
  const _TextAnswer({required this.challenge, required this.controller, required this.onSubmit});

  final Challenge challenge;
  final TextEditingController controller;
  final ValueChanged<Object?> onSubmit;

  @override
  Widget build(BuildContext context) {
    final isCaptcha = challenge.type == ChallengeType.captchaText;
    return Column(
      children: [
        if (isCaptcha) ...[
          Transform.rotate(
            angle: -0.04,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A44).withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(challenge.prompt, style: getGeistMonoStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 5, color: const Color(0xFFE2E8FF))),
            ),
          ),
          const SizedBox(height: 18),
        ],
        TextField(
          controller: controller,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          style: getGeistMonoStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RegisterColors.text),
          onSubmitted: (value) => onSubmit(value),
          decoration: _inputDecoration('Enter answer'),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(label: 'Verify', onTap: () => onSubmit(controller.text)),
      ],
    );
  }
}

class _MemoryAnswer extends StatelessWidget {
  const _MemoryAnswer({required this.challenge, required this.visible, required this.controller, required this.onSubmit});

  final Challenge challenge;
  final bool visible;
  final TextEditingController controller;
  final ValueChanged<Object?> onSubmit;

  @override
  Widget build(BuildContext context) {
    final value = challenge.payload['value']?.toString() ?? '';
    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: visible
              ? Text(value, key: const ValueKey('memory-visible'), style: getGeistMonoStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 6, color: const Color(0xFFE2E8FF)))
              : Text('Enter the hidden code', key: const ValueKey('memory-hidden'), style: getGeistStyle(fontSize: 15, fontWeight: FontWeight.w600, color: RegisterColors.onSurfaceVariant)),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          enabled: !visible,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: getGeistMonoStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RegisterColors.text),
          onSubmitted: (value) => onSubmit(value),
          decoration: _inputDecoration('5 digits'),
        ),
        const SizedBox(height: 16),
        _PrimaryButton(label: 'Verify memory', onTap: visible ? null : () => onSubmit(controller.text)),
      ],
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({required this.challenge, required this.selected, required this.multi, required this.onChanged, required this.onSubmit});

  final Challenge challenge;
  final Set<String> selected;
  final bool multi;
  final VoidCallback onChanged;
  final ValueChanged<Object?> onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.35,
          physics: const NeverScrollableScrollPhysics(),
          children: challenge.options.map((option) {
            final active = selected.contains(option.id);
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (multi) {
                  active ? selected.remove(option.id) : selected.add(option.id);
                  onChanged();
                } else {
                  onSubmit(option.id);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE2E8FF).withValues(alpha: 0.13) : const Color(0x661B2A44),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: active ? const Color(0xFFE2E8FF) : const Color(0xFF1B2A44)),
                ),
                child: option.color != null
                    ? Container(width: 34, height: 34, decoration: BoxDecoration(color: option.color, borderRadius: BorderRadius.circular(10)))
                    : option.icon != null
                        ? Icon(option.icon, color: const Color(0xFFE2E8FF), size: 28)
                        : Text(
                            option.label,
                            textAlign: TextAlign.center,
                            style: getGeistStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE2E8FF),
                            ),
                          ),
              ),
            );
          }).toList(),
        ),
        if (multi) ...[
          const SizedBox(height: 16),
          _PrimaryButton(label: 'Submit selection', onTap: () => onSubmit(selected)),
        ],
      ],
    );
  }
}

class _SliderAnswer extends StatelessWidget {
  const _SliderAnswer({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 12,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 18),
            activeTrackColor: const Color(0xFF22C55E),
            inactiveTrackColor: const Color(0xFF1B2A44),
            thumbColor: const Color(0xFFE2E8FF),
          ),
          child: Slider(value: value, onChanged: onChanged),
        ),
        Text('Kéo hết thanh để mở khóa', style: getGeistStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RegisterColors.onSurfaceVariant)),
      ],
    );
  }
}

class _PuzzleAnswer extends StatelessWidget {
  const _PuzzleAnswer({
    required this.challenge,
    required this.dx,
    required this.dy,
    required this.onChanged,
    required this.onSubmit,
  });

  final Challenge challenge;
  final double dx;
  final double dy;
  final void Function(double dx, double dy) onChanged;
  final ValueChanged<Object?> onSubmit;

  @override
  Widget build(BuildContext context) {
    // Generate a stable nature photo using picsum.photos with challenge prompt hash seed.
    final imageUrl = 'https://picsum.photos/seed/${challenge.prompt.hashCode.abs()}/280/156';

    const targetX = 180.0;
    final pieceLeft = targetX + dx;
    final dragProgress = ((dx + 140.0) / 140.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 280,
            height: 156,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1B2A44), width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF081120),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF1B2A44),
                        child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    left: targetX,
                    top: 50,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: pieceLeft,
                    top: 50,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        final newDx = (dx + details.delta.dx).clamp(-140.0, 0.0);
                        onChanged(newDx, 0.0);
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8FF), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 6,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            width: 42,
                            height: 42,
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minWidth: 280,
                              maxWidth: 280,
                              minHeight: 156,
                              maxHeight: 156,
                              child: Transform.translate(
                                offset: const Offset(-targetX, -50),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: const Color(0xFF1B2A44),
                                    child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 280,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1B2A44).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1B2A44).withValues(alpha: 0.8),
                width: 1.2,
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Center(
                  child: Text(
                    'Kéo slider để xếp hình',
                    style: getGeistStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 42 + dragProgress * (280 - 42),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  left: dragProgress * (280 - 42),
                  top: 2,
                  bottom: 2,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      final newDx = (dx + details.delta.dx).clamp(-140.0, 0.0);
                      onChanged(newDx, 0.0);
                    },
                    child: Container(
                      width: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8FF),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF081120),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryButton(
          label: dx.abs() <= 2 ? 'Submit puzzle' : 'Kéo mảnh ghép vào ô trước',
          onTap: dx.abs() <= 2 ? () => onSubmit('complete') : null,
        ),
      ],
    );
  }
}

class _SortAnswer extends StatefulWidget {
  const _SortAnswer({required this.challenge, required this.values, required this.onSubmit});

  final Challenge challenge;
  final List<int> values;
  final ValueChanged<Object?> onSubmit;

  @override
  State<_SortAnswer> createState() => _SortAnswerState();
}

class _SortAnswerState extends State<_SortAnswer> {
  @override
  void initState() {
    super.initState();
    if (widget.values.isEmpty) {
      widget.values.addAll(widget.challenge.payload['values'].toString().split(',').map(int.parse));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.values.length,
          onReorderItem: (oldIndex, newIndex) {
            setState(() {
              final item = widget.values.removeAt(oldIndex);
              widget.values.insert(newIndex, item);
            });
          },
          itemBuilder: (context, index) => Container(
            key: ValueKey('${widget.values[index]}-$index'),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0x661B2A44), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1B2A44))),
            child: Text('${widget.values[index]}', textAlign: TextAlign.center, style: getGeistMonoStyle(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFFE2E8FF))),
          ),
        ),
        const SizedBox(height: 12),
        _PrimaryButton(label: 'Confirm order', onTap: () => widget.onSubmit(widget.values.join(','))),
      ],
    );
  }
}

class _RotateAnswer extends StatelessWidget {
  const _RotateAnswer({required this.rotation, required this.onChanged});

  final double rotation;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onPanUpdate: (details) => onChanged(rotation + details.delta.dx * 0.018),
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(color: const Color(0x661B2A44), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFF1B2A44))),
              child: const Icon(Icons.navigation_rounded, color: Color(0xFFE2E8FF), size: 56),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Drag horizontally until the arrow points up', style: getGeistStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RegisterColors.onSurfaceVariant)),
      ],
    );
  }
}

class _FailedView extends StatelessWidget {
  const _FailedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('failed'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20.0),
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(null),
          ),
        ),
        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 54),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Verification failed',
            style: getGeistStyle(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFFEF4444)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'The challenge response did not match. Try a new sequence.',
          textAlign: TextAlign.center,
          style: getGeistStyle(fontSize: 14, fontWeight: FontWeight.w500, color: RegisterColors.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        _PrimaryButton(label: 'Try Again', onTap: onRetry),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.verified_user_rounded, color: Color(0xFF22C55E), size: 58),
        const SizedBox(height: 16),
        Text('Verification completed', style: getGeistStyle(fontSize: 23, fontWeight: FontWeight.w800, color: const Color(0xFF22C55E))),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE2E8FF),
          disabledBackgroundColor: const Color(0xFF1B2A44),
          foregroundColor: const Color(0xFF081120),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: getGeistStyle(fontSize: 14, fontWeight: FontWeight.w800, color: onTap == null ? RegisterColors.onSurfaceVariant : const Color(0xFF081120))),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: getGeistStyle(fontSize: 14, fontWeight: FontWeight.w500, color: RegisterColors.onSurfaceVariant.withValues(alpha: 0.55)),
    filled: true,
    fillColor: const Color(0x661B2A44),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1B2A44))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8FF), width: 1.4)),
  );
}
