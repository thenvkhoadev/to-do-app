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
  division,
  oddEven,
  wordMatch,
  countIcons,
  selectLargest,
  selectSmallest,
  synonym,
  dayOrder,
  tapTarget,
  reverseText,
  missingVowel,
  monthOrder,
  clockReading,
  selectWarmColor,
  selectColdColor,
  primeNumber,
  sumDigits,
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
        ChallengeType.division => 'division',
        ChallengeType.oddEven => 'odd_even',
        ChallengeType.wordMatch => 'word_match',
        ChallengeType.countIcons => 'count_icons',
        ChallengeType.selectLargest => 'select_largest',
        ChallengeType.selectSmallest => 'select_smallest',
        ChallengeType.synonym => 'synonym',
        ChallengeType.dayOrder => 'day_order',
        ChallengeType.tapTarget => 'tap_target',
        ChallengeType.reverseText => 'reverse_text',
        ChallengeType.missingVowel => 'missing_vowel',
        ChallengeType.monthOrder => 'month_order',
        ChallengeType.clockReading => 'clock_reading',
        ChallengeType.selectWarmColor => 'select_warm_color',
        ChallengeType.selectColdColor => 'select_cold_color',
        ChallengeType.primeNumber => 'prime_number',
        ChallengeType.sumDigits => 'sum_digits',
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
  ChallengeEngine({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  List<Challenge> generateSequence(int count) {
    final types = ChallengeType.values.toList()..shuffle(_random);
    return types.take(count.clamp(0, types.length)).map(generate).toList();
  }

  List<ChallengeOption> _shuffledOptions(List<ChallengeOption> options) {
    return [...options]..shuffle(_random);
  }

  List<int> _uniqueNumbers(int count, {int min = 10, int max = 99}) {
    final values = <int>{};
    while (values.length < count) {
      values.add(min + _random.nextInt(max - min + 1));
    }
    return values.toList()..shuffle(_random);
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
      ChallengeType.division => _division(),
      ChallengeType.oddEven => _oddEven(),
      ChallengeType.wordMatch => _wordMatch(),
      ChallengeType.countIcons => _countIcons(),
      ChallengeType.selectLargest => _selectLargest(),
      ChallengeType.selectSmallest => _selectSmallest(),
      ChallengeType.synonym => _synonym(),
      ChallengeType.dayOrder => _dayOrder(),
      ChallengeType.tapTarget => _tapTarget(),
      ChallengeType.reverseText => _reverseText(),
      ChallengeType.missingVowel => _missingVowel(),
      ChallengeType.monthOrder => _monthOrder(),
      ChallengeType.clockReading => _clockReading(),
      ChallengeType.selectWarmColor => _selectWarmColor(),
      ChallengeType.selectColdColor => _selectColdColor(),
      ChallengeType.primeNumber => _primeNumber(),
      ChallengeType.sumDigits => _sumDigits(),
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
      options: _shuffledOptions(options),
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
      options: _shuffledOptions(options),
    );
  }

  Challenge _shapeRecognition() {
    final targetCircles = _random.nextBool();
    const options = [
      ChallengeOption(id: 'circle_1', label: 'Circle', shape: BoxShape.circle),
      ChallengeOption(id: 'square_1', label: 'Square'),
      ChallengeOption(id: 'circle_2', label: 'Circle', shape: BoxShape.circle),
      ChallengeOption(id: 'square_2', label: 'Square'),
    ];
    return Challenge(
      type: ChallengeType.shapeRecognition,
      prompt: targetCircles ? 'Select all circles' : 'Select all squares',
      mode: ChallengeAnswerMode.multiChoice,
      correctAnswers: targetCircles ? {'circle_1', 'circle_2'} : {'square_1', 'square_2'},
      options: _shuffledOptions(options),
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
      prompt: 'Arrange numbers from smallest to largest',
      mode: ChallengeAnswerMode.sort,
      correctAnswers: {sorted.join(',')},
      payload: {'values': values.join(',')},
    );
  }

  Challenge _humanLogic() {
    final prompts = [
      (
        'Which animal barks?',
        'dog',
        const [
          ChallengeOption(id: 'dog', label: 'Dog'),
          ChallengeOption(id: 'fish', label: 'Fish'),
          ChallengeOption(id: 'bird', label: 'Bird'),
          ChallengeOption(id: 'cow', label: 'Cow'),
        ],
      ),
      (
        'Which one can fly?',
        'bird',
        const [
          ChallengeOption(id: 'cat', label: 'Cat'),
          ChallengeOption(id: 'bird', label: 'Bird'),
          ChallengeOption(id: 'horse', label: 'Horse'),
          ChallengeOption(id: 'fish', label: 'Fish'),
        ],
      ),
      (
        'Which one is used to write?',
        'pen',
        const [
          ChallengeOption(id: 'cup', label: 'Cup'),
          ChallengeOption(id: 'pen', label: 'Pen'),
          ChallengeOption(id: 'shoe', label: 'Shoe'),
          ChallengeOption(id: 'plate', label: 'Plate'),
        ],
      ),
    ];
    final selected = prompts[_random.nextInt(prompts.length)];
    return Challenge(
      type: ChallengeType.humanLogic,
      prompt: selected.$1,
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {selected.$2},
      options: _shuffledOptions(selected.$3),
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

  Challenge _division() {
    final answer = _random.nextInt(8) + 2;
    final divisor = _random.nextInt(7) + 2;
    final dividend = answer * divisor;
    return Challenge(
      type: ChallengeType.division,
      prompt: 'What is $dividend ÷ $divisor?',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {'$answer'},
    );
  }

  Challenge _oddEven() {
    final number = _random.nextInt(80) + 11;
    final target = number.isEven ? 'even' : 'odd';
    return Challenge(
      type: ChallengeType.oddEven,
      prompt: 'Is $number odd or even?',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {target},
      options: _shuffledOptions(const [
        ChallengeOption(id: 'odd', label: 'Odd'),
        ChallengeOption(id: 'even', label: 'Even'),
      ]),
    );
  }

  Challenge _wordMatch() {
    const pairs = {
      'SKY': 'sky',
      'OCEAN': 'ocean',
      'FOREST': 'forest',
      'ROBOT': 'robot',
    };
    final target = pairs.keys.elementAt(_random.nextInt(pairs.length));
    return Challenge(
      type: ChallengeType.wordMatch,
      prompt: 'Select $target',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {pairs[target]!},
      options: _shuffledOptions(const [
        ChallengeOption(id: 'sky', label: 'Sky', icon: Icons.cloud_rounded),
        ChallengeOption(id: 'ocean', label: 'Ocean', icon: Icons.water_rounded),
        ChallengeOption(id: 'forest', label: 'Forest', icon: Icons.park_rounded),
        ChallengeOption(id: 'robot', label: 'Robot', icon: Icons.smart_toy_rounded),
      ]),
    );
  }

  Challenge _countIcons() {
    final count = _random.nextInt(3) + 3;
    return Challenge(
      type: ChallengeType.countIcons,
      prompt: 'How many stars are shown? ${List.filled(count, '★').join(' ')}',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {'$count'},
    );
  }

  Challenge _selectLargest() {
    final values = _uniqueNumbers(4);
    final largest = values.reduce(max);
    return Challenge(
      type: ChallengeType.selectLargest,
      prompt: 'Select the largest number',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {'$largest'},
      options: values.map((value) => ChallengeOption(id: '$value', label: '$value')).toList(),
    );
  }

  Challenge _selectSmallest() {
    final values = _uniqueNumbers(4);
    final smallest = values.reduce(min);
    return Challenge(
      type: ChallengeType.selectSmallest,
      prompt: 'Select the smallest number',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {'$smallest'},
      options: values.map((value) => ChallengeOption(id: '$value', label: '$value')).toList(),
    );
  }

  Challenge _synonym() {
    final prompts = [
      (
        'Which word means quick?',
        'fast',
        const [
          ChallengeOption(id: 'fast', label: 'Fast'),
          ChallengeOption(id: 'cold', label: 'Cold'),
          ChallengeOption(id: 'quiet', label: 'Quiet'),
          ChallengeOption(id: 'heavy', label: 'Heavy'),
        ],
      ),
      (
        'Which word means silent?',
        'quiet',
        const [
          ChallengeOption(id: 'bright', label: 'Bright'),
          ChallengeOption(id: 'quiet', label: 'Quiet'),
          ChallengeOption(id: 'rough', label: 'Rough'),
          ChallengeOption(id: 'rapid', label: 'Rapid'),
        ],
      ),
      (
        'Which word means large?',
        'big',
        const [
          ChallengeOption(id: 'tiny', label: 'Tiny'),
          ChallengeOption(id: 'soft', label: 'Soft'),
          ChallengeOption(id: 'big', label: 'Big'),
          ChallengeOption(id: 'late', label: 'Late'),
        ],
      ),
    ];
    final selected = prompts[_random.nextInt(prompts.length)];
    return Challenge(
      type: ChallengeType.synonym,
      prompt: selected.$1,
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {selected.$2},
      options: _shuffledOptions(selected.$3),
    );
  }

  Challenge _dayOrder() {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final index = _random.nextInt(days.length - 1);
    final current = days[index];
    final answer = days[index + 1];
    final distractors = days.where((day) => day != answer).toList()..shuffle(_random);
    final options = [answer, ...distractors.take(3)]..shuffle(_random);
    return Challenge(
      type: ChallengeType.dayOrder,
      prompt: 'Which day comes after ${current[0].toUpperCase()}${current.substring(1)}?',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {answer},
      options: options
          .map((day) => ChallengeOption(
                id: day,
                label: '${day[0].toUpperCase()}${day.substring(1)}',
              ))
          .toList(),
    );
  }

  Challenge _tapTarget() {
    const options = [
      ChallengeOption(id: 'shield', label: 'Shield', icon: Icons.shield_rounded),
      ChallengeOption(id: 'key', label: 'Key', icon: Icons.vpn_key_rounded),
      ChallengeOption(id: 'bell', label: 'Bell', icon: Icons.notifications_rounded),
      ChallengeOption(id: 'flag', label: 'Flag', icon: Icons.flag_rounded),
    ];
    final target = options[_random.nextInt(options.length)];
    return Challenge(
      type: ChallengeType.tapTarget,
      prompt: 'Tap the ${target.label.toLowerCase()}',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {target.id},
      options: _shuffledOptions(options),
    );
  }

  Challenge _reverseText() {
    const words = ['nexus', 'focus', 'human', 'secure', 'verify', 'signal'];
    final word = words[_random.nextInt(words.length)];
    return Challenge(
      type: ChallengeType.reverseText,
      prompt: 'Type this word backwards: $word',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {word.split('').reversed.join()},
    );
  }

  Challenge _missingVowel() {
    const words = ['planet', 'rocket', 'silver', 'window', 'market', 'forest'];
    final word = words[_random.nextInt(words.length)];
    final vowelIndexes = <int>[];
    for (var i = 0; i < word.length; i++) {
      if ('aeiou'.contains(word[i])) vowelIndexes.add(i);
    }
    final missingIndex = vowelIndexes[_random.nextInt(vowelIndexes.length)];
    final masked = '${word.substring(0, missingIndex)}_${word.substring(missingIndex + 1)}';
    return Challenge(
      type: ChallengeType.missingVowel,
      prompt: 'Missing letter: $masked',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {word[missingIndex]},
    );
  }

  Challenge _monthOrder() {
    const months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    final index = _random.nextInt(months.length - 1);
    final current = months[index];
    final answer = months[index + 1];
    final distractors = months.where((month) => month != answer).toList()..shuffle(_random);
    final options = [answer, ...distractors.take(3)]..shuffle(_random);
    return Challenge(
      type: ChallengeType.monthOrder,
      prompt: 'Which month comes after ${current[0].toUpperCase()}${current.substring(1)}?',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {answer},
      options: options
          .map((month) => ChallengeOption(
                id: month,
                label: '${month[0].toUpperCase()}${month.substring(1)}',
              ))
          .toList(),
    );
  }

  Challenge _clockReading() {
    final hour = _random.nextInt(12) + 1;
    final minute = [0, 15, 30, 45][_random.nextInt(4)];
    final answer = '$hour:${minute.toString().padLeft(2, '0')}';
    final options = <String>{answer};
    while (options.length < 4) {
      final h = _random.nextInt(12) + 1;
      final m = [0, 15, 30, 45][_random.nextInt(4)];
      options.add('$h:${m.toString().padLeft(2, '0')}');
    }
    final optionList = options.toList()..shuffle(_random);
    return Challenge(
      type: ChallengeType.clockReading,
      prompt: 'Select the time $answer',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {answer},
      options: optionList.map((time) => ChallengeOption(id: time, label: time)).toList(),
    );
  }

  Challenge _selectWarmColor() {
    const options = [
      ChallengeOption(id: 'red', label: 'Red', color: Color(0xFFEF4444)),
      ChallengeOption(id: 'orange', label: 'Orange', color: Color(0xFFF97316)),
      ChallengeOption(id: 'blue', label: 'Blue', color: Color(0xFF3B82F6)),
      ChallengeOption(id: 'green', label: 'Green', color: Color(0xFF22C55E)),
    ];
    final targets = _random.nextBool() ? {'red'} : {'orange'};
    return Challenge(
      type: ChallengeType.selectWarmColor,
      prompt: 'Select a warm color',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: targets,
      options: _shuffledOptions(options),
    );
  }

  Challenge _selectColdColor() {
    const options = [
      ChallengeOption(id: 'blue', label: 'Blue', color: Color(0xFF3B82F6)),
      ChallengeOption(id: 'cyan', label: 'Cyan', color: Color(0xFF06B6D4)),
      ChallengeOption(id: 'red', label: 'Red', color: Color(0xFFEF4444)),
      ChallengeOption(id: 'yellow', label: 'Yellow', color: Color(0xFFFACC15)),
    ];
    final targets = _random.nextBool() ? {'blue'} : {'cyan'};
    return Challenge(
      type: ChallengeType.selectColdColor,
      prompt: 'Select a cool color',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: targets,
      options: _shuffledOptions(options),
    );
  }

  Challenge _primeNumber() {
    const primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29];
    const nonPrimes = [4, 6, 8, 9, 10, 12, 14, 15, 21, 25];
    final answer = primes[_random.nextInt(primes.length)];
    final distractors = [...nonPrimes]..shuffle(_random);
    final options = [answer, ...distractors.take(3)]..shuffle(_random);
    return Challenge(
      type: ChallengeType.primeNumber,
      prompt: 'Select the prime number',
      mode: ChallengeAnswerMode.singleChoice,
      correctAnswers: {'$answer'},
      options: options.map((value) => ChallengeOption(id: '$value', label: '$value')).toList(),
    );
  }

  Challenge _sumDigits() {
    final number = _random.nextInt(800) + 120;
    final sum = number.toString().split('').fold<int>(0, (total, digit) => total + int.parse(digit));
    return Challenge(
      type: ChallengeType.sumDigits,
      prompt: 'Add the digits: $number',
      mode: ChallengeAnswerMode.text,
      correctAnswers: {'$sum'},
    );
  }
}
