import 'dart:math';

import 'package:flutter/material.dart';

enum ChallengeType {
  math,
  subtraction,
  multiplication,
  sequence,
  pattern,
  colorRecognition,
  iconRecognition,
  shapeRecognition,
  memory,
  dragSlider,
  imagePuzzle,
  sortNumbers,
  humanLogic,
  captchaText,
  rotateObject,
}

extension ChallengeTypeLabel on ChallengeType {
  String get id => switch (this) {
        ChallengeType.math => 'math',
        ChallengeType.subtraction => 'subtraction',
        ChallengeType.multiplication => 'multiplication',
        ChallengeType.sequence => 'sequence',
        ChallengeType.pattern => 'pattern',
        ChallengeType.colorRecognition => 'color',
        ChallengeType.iconRecognition => 'icon',
        ChallengeType.shapeRecognition => 'shape',
        ChallengeType.memory => 'memory',
        ChallengeType.dragSlider => 'slider',
        ChallengeType.imagePuzzle => 'image_puzzle',
        ChallengeType.sortNumbers => 'sort_numbers',
        ChallengeType.humanLogic => 'human_logic',
        ChallengeType.captchaText => 'captcha_text',
        ChallengeType.rotateObject => 'rotate_object',
      };
}

enum ChallengeAnswerMode {
  text,
  singleChoice,
  multiChoice,
  memory,
  slider,
  puzzle,
  sort,
  rotate,
}

class ChallengeOption {
  const ChallengeOption({
    required this.id,
    required this.label,
    this.color,
    this.icon,
    this.shape = BoxShape.rectangle,
  });

  final String id;
  final String label;
  final Color? color;
  final IconData? icon;
  final BoxShape shape;
}

class Challenge {
  const Challenge({
    required this.type,
    required this.prompt,
    required this.mode,
    required this.correctAnswers,
    this.options = const [],
    this.payload = const {},
  });

  final ChallengeType type;
  final String prompt;
  final ChallengeAnswerMode mode;
  final Set<String> correctAnswers;
  final List<ChallengeOption> options;
  final Map<String, Object> payload;

  bool verify(Object? answer) {
    if (answer is String) {
      return correctAnswers.contains(answer.trim().toLowerCase());
    }
    if (answer is Iterable<String>) {
      final normalized = answer.map((value) => value.trim().toLowerCase()).toSet();
      return normalized.length == correctAnswers.length && normalized.containsAll(correctAnswers);
    }
    if (answer is num) {
      final target = payload['target'];
      final tolerance = payload['tolerance'];
      if (target is num && tolerance is num) {
        return (answer - target).abs() <= tolerance;
      }
    }
    return false;
  }
}

class ChallengeEngine {
  ChallengeEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<Challenge> generateSequence(int count) {
    final types = ChallengeType.values.toList()..shuffle(_random);
    return List.generate(count, (index) => generate(types[index % types.length]));
  }

  Challenge generate(ChallengeType type) {
    return switch (type) {
      ChallengeType.math => _math(),
      ChallengeType.subtraction => _subtraction(),
      ChallengeType.multiplication => _multiplication(),
      ChallengeType.sequence => _sequence(),
      ChallengeType.pattern => _pattern(),
      ChallengeType.colorRecognition => _colorRecognition(),
      ChallengeType.iconRecognition => _iconRecognition(),
      ChallengeType.shapeRecognition => _shapeRecognition(),
      ChallengeType.memory => _memory(),
      ChallengeType.dragSlider => _dragSlider(),
      ChallengeType.imagePuzzle => _imagePuzzle(),
      ChallengeType.sortNumbers => _sortNumbers(),
      ChallengeType.humanLogic => _humanLogic(),
      ChallengeType.captchaText => _captchaText(),
      ChallengeType.rotateObject => _rotateObject(),
    };
  }

  Challenge _math() {
    final a = _random.nextInt(9) + 3;
    final b = _random.nextInt(9) + 2;
    return Challenge(
      type: ChallengeType.math,
      prompt: 'What is $a + $b?',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {'${a + b}'},
    );
  }

  Challenge _subtraction() {
    final a = _random.nextInt(12) + 10;
    final b = _random.nextInt(8) + 2;
    return Challenge(
      type: ChallengeType.subtraction,
      prompt: 'What is $a - $b?',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {'${a - b}'},
    );
  }

  Challenge _multiplication() {
    final a = _random.nextInt(7) + 3;
    final b = _random.nextInt(7) + 3;
    return Challenge(
      type: ChallengeType.multiplication,
      prompt: 'What is $a × $b?',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {'${a * b}'},
    );
  }

  Challenge _sequence() {
    final start = _random.nextInt(3) + 1;
    final step = _random.nextInt(4) + 2;
    final values = List.generate(4, (index) => start + index * step);
    return Challenge(
      type: ChallengeType.sequence,
      prompt: '${values.join('  ')}  ?',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {'${start + 4 * step}'},
    );
  }

  Challenge _pattern() {
    final start = _random.nextInt(10);
    final chars = List.generate(4, (index) => String.fromCharCode(65 + start + index));
    return Challenge(
      type: ChallengeType.pattern,
      prompt: '${chars.join('  ')}  ?',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {String.fromCharCode(65 + start + 4).toLowerCase()},
    );
  }

  Challenge _colorRecognition() {
    const options = [
      ChallengeOption(id: 'blue', label: 'BLUE', color: Color(0xFF3B82F6)),
      ChallengeOption(id: 'green', label: 'GREEN', color: Color(0xFF22C55E)),
      ChallengeOption(id: 'red', label: 'RED', color: Color(0xFFEF4444)),
      ChallengeOption(id: 'yellow', label: 'YELLOW', color: Color(0xFFFACC15)),
    ];
    final target = options[_random.nextInt(options.length)];
    return Challenge(
      type: ChallengeType.colorRecognition,
      prompt: 'Select ${target.label}',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {target.id},
      options: options,
    );
  }

  Challenge _iconRecognition() {
    const options = [
      ChallengeOption(id: 'car', label: 'Car', icon: Icons.directions_car_rounded),
      ChallengeOption(id: 'home', label: 'Home', icon: Icons.home_rounded),
      ChallengeOption(id: 'star', label: 'Star', icon: Icons.star_rounded),
      ChallengeOption(id: 'phone', label: 'Phone', icon: Icons.phone_rounded),
    ];
    final target = options[_random.nextInt(options.length)];
    return Challenge(
      type: ChallengeType.iconRecognition,
      prompt: 'Select the ${target.label.toLowerCase()}',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {target.id},
      options: options,
    );
  }

  Challenge _shapeRecognition() {
    const options = [
      ChallengeOption(id: 'circle_1', label: 'Circle', shape: BoxShape.circle),
      ChallengeOption(id: 'square_1', label: 'Square'),
      ChallengeOption(id: 'circle_2', label: 'Circle', shape: BoxShape.circle),
      ChallengeOption(id: 'square_2', label: 'Square'),
    ];
    return const Challenge(
      type: ChallengeType.shapeRecognition,
      prompt: 'Select all circles',
      mode: ChallengeAnswerMode.multiChoice,
      correctAnswers: {'circle_1', 'circle_2'},
      options: options,
    );
  }

  Challenge _memory() {
    final value = List.generate(5, (_) => _random.nextInt(10)).join();
    return Challenge(
      type: ChallengeType.memory,
      prompt: 'Memorize the code',
      mode: ChallengeAnswerMode.memory,
      correctAnswers: {value},
      payload: {'value': value},
    );
  }

  Challenge _dragSlider() {
    return const Challenge(
      type: ChallengeType.dragSlider,
      prompt: 'Slide to unlock',
      mode: ChallengeAnswerMode.slider,
      correctAnswers: {'complete'},
    );
  }

  Challenge _imagePuzzle() {
    return const Challenge(
      type: ChallengeType.imagePuzzle,
      prompt: 'Move the glowing piece into the target zone',
      mode: ChallengeAnswerMode.puzzle,
      correctAnswers: {'complete'},
    );
  }

  Challenge _sortNumbers() {
    final values = List.generate(4, (_) => _random.nextInt(9) + 1);
    final sorted = [...values]..sort();
    return Challenge(
      type: ChallengeType.sortNumbers,
      prompt: 'Arrange: ${values.join('  ')}',
      mode: ChallengeAnswerMode.sort,
      correctAnswers: {sorted.join(',')},
      payload: {'values': values.join(',')},
    );
  }

  Challenge _humanLogic() {
    const options = [
      ChallengeOption(id: 'dog', label: 'Dog'),
      ChallengeOption(id: 'fish', label: 'Fish'),
      ChallengeOption(id: 'bird', label: 'Bird'),
      ChallengeOption(id: 'cow', label: 'Cow'),
    ];
    return const Challenge(
      type: ChallengeType.humanLogic,
      prompt: 'Which animal barks?',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {'dog'},
      options: options,
    );
  }

  Challenge _captchaText() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final text = List.generate(5, (_) => chars[_random.nextInt(chars.length)]).join();
    return Challenge(
      type: ChallengeType.captchaText,
      prompt: text,
      mode: ChallengeAnswerMode.text,
      correctAnswers: {text.toLowerCase()},
      payload: {'distorted': true},
    );
  }

  Challenge _rotateObject() {
    return const Challenge(
      type: ChallengeType.rotateObject,
      prompt: 'Rotate the object upright',
      mode: ChallengeAnswerMode.rotate,
      correctAnswers: {'complete'},
      payload: {'target': 0.0, 'tolerance': 0.18},
    );
  }
}
