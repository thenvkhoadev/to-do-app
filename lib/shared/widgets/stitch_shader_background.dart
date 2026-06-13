import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class StitchShaderBackground extends StatefulWidget {
  const StitchShaderBackground({super.key});

  @override
  State<StitchShaderBackground> createState() => _StitchShaderBackgroundState();
}

class _StitchShaderBackgroundState extends State<StitchShaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Future<ui.FragmentProgram> _program;

  @override
  void initState() {
    super.initState();
    _program = ui.FragmentProgram.fromAsset('shaders/stitch_shader.frag');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.FragmentProgram>(
      future: _program,
      builder: (context, snapshot) {
        final program = snapshot.data;
        if (program == null) {
          return const ColoredBox(color: Color(0xFF0D1322));
        }

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _StitchShaderPainter(
                program: program,
                time: _controller.value * 20.0,
              ),
              child: const SizedBox.expand(),
            );
          },
        );
      },
    );
  }
}

class _StitchShaderPainter extends CustomPainter {
  _StitchShaderPainter({required this.program, required this.time});

  final ui.FragmentProgram program;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      canvas.drawColor(const Color(0xFF0D1322), BlendMode.srcOver);
      return;
    }

    final shader = program.fragmentShader()
      ..setFloat(0, time)
      ..setFloat(1, size.width)
      ..setFloat(2, size.height);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _StitchShaderPainter oldDelegate) {
    return oldDelegate.program != program || oldDelegate.time != time;
  }
}
