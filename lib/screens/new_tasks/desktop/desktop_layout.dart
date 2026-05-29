import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/theme/dashboard_theme.dart';

class SubtaskItem {
  SubtaskItem({required this.id, required this.text, this.isDone = false});
  final String id;
  String text;
  bool isDone;
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.avatarText,
    required this.color,
    required this.isOnline,
  });
  final String id;
  final String name;
  final String avatarText;
  final Color color;
  final bool isOnline;
}

const mockTeamMembers = [
  TeamMember(id: 'alex', name: 'Alex Rivera', avatarText: 'A', color: DashboardColors.primary, isOnline: true),
  TeamMember(id: 'maria', name: 'Maria Santos', avatarText: 'M', color: DashboardColors.secondary, isOnline: true),
  TeamMember(id: 'kevin', name: 'Kevin Park', avatarText: 'K', color: DashboardColors.tertiary, isOnline: false),
  TeamMember(id: 'sarah', name: 'Sarah Connor', avatarText: 'S', color: DashboardColors.error, isOnline: true),
];

const mockProjects = [
  {'name': 'AI Core 2.0', 'color': DashboardColors.primary},
  {'name': 'Quantum Project', 'color': DashboardColors.tertiary},
  {'name': 'Security Audit', 'color': DashboardColors.outline},
  {'name': 'Latency Analysis', 'color': DashboardColors.secondary},
];

class NewTasksDesktopLayout extends StatefulWidget {
  const NewTasksDesktopLayout({this.onClose, super.key});

  final VoidCallback? onClose;

  @override
  State<NewTasksDesktopLayout> createState() => _NewTasksDesktopLayoutState();
}

class _NewTasksDesktopLayoutState extends State<NewTasksDesktopLayout> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newSubtaskController = TextEditingController();
  bool _isAddingSubtask = false;

  // Form State
  String _selectedProject = 'AI Core 2.0';
  String _selectedPriority = 'Smart AI';
  DateTime _selectedDate = DateTime(2026, 11, 24);
  double _selectedEstimate = 4.0;
  final List<String> _selectedTags = ['#Strategy', '#DeepWork'];
  final List<TeamMember> _selectedAssignees = [
    mockTeamMembers[0], // Pre-assign Alex Rivera
  ];

  // Subtasks State
  final List<SubtaskItem> _subtasks = [
    SubtaskItem(id: 'sub-1', text: 'Define core project architecture', isDone: false),
    SubtaskItem(id: 'sub-2', text: 'Draft stakeholder communication plan', isDone: false),
  ];
  bool _isAiGeneratingSubtasks = false;

  // AI Suggestion Dock State
  bool _showSuggestionDock = false;
  String _suggestionText = '';
  String _suggestionApplyType = ''; // 'priority', 'assignee', 'milestones'

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onInputChanged);
    _descriptionController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newSubtaskController.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final title = _titleController.text.toLowerCase();
    final desc = _descriptionController.text.toLowerCase();

    if (title.contains('security') || desc.contains('security') || title.contains('audit') || desc.contains('audit')) {
      setState(() {
        _showSuggestionDock = true;
        _suggestionText = 'AI Suggestion: Link this task to security standards & assign to Kevin Park (Security lead).';
        _suggestionApplyType = 'security_assign';
      });
    } else if (title.contains('spec') || desc.contains('spec') || title.contains('inference') || desc.contains('inference')) {
      setState(() {
        _showSuggestionDock = true;
        _suggestionText = 'AI Suggestion: High correlation with Neural Engine Specs. Suggest High Priority & 8h Estimate.';
        _suggestionApplyType = 'priority_high';
      });
    } else if (title.isNotEmpty || desc.isNotEmpty) {
      setState(() {
        _showSuggestionDock = true;
        _suggestionText = 'AI Suggestion: Split strategy review into 4 milestones for optimal progress tracking.';
        _suggestionApplyType = 'milestones';
      });
    } else {
      setState(() {
        _showSuggestionDock = false;
      });
    }
  }

  void _applyAiSuggestion() {
    setState(() {
      if (_suggestionApplyType == 'security_assign') {
        // Assign to Kevin Park (mockTeamMembers[2])
        if (!_selectedAssignees.any((m) => m.id == 'kevin')) {
          _selectedAssignees.add(mockTeamMembers[2]);
        }
        _selectedProject = 'Security Audit';
        _selectedPriority = 'High';
      } else if (_suggestionApplyType == 'priority_high') {
        _selectedPriority = 'High';
        _selectedEstimate = 8.0;
      } else if (_suggestionApplyType == 'milestones') {
        // AI suggest subtasks directly
        _generateSubtasksWithAi();
      }
      _showSuggestionDock = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Suggestion successfully applied to Task Orchestration!'),
        backgroundColor: DashboardColors.primaryContainer,
      ),
    );
  }

  Future<void> _generateSubtasksWithAi() async {
    if (_isAiGeneratingSubtasks) return;
    setState(() {
      _isAiGeneratingSubtasks = true;
    });

    // Simulate AI generation process with custom micro-animation time
    await Future.delayed(const Duration(milliseconds: 1400));

    if (mounted) {
      setState(() {
        _isAiGeneratingSubtasks = false;
        _subtasks.addAll([
          SubtaskItem(id: 'ai-sub-1', text: 'Verify model latency on mobile edge devices', isDone: false),
          SubtaskItem(id: 'ai-sub-2', text: 'Draft benchmark report for board presentation', isDone: false),
          SubtaskItem(id: 'ai-sub-3', text: 'Establish backup fallbacks for API failure states', isDone: false),
        ]);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('3 AI Subtasks generated based on task context.'),
          backgroundColor: DashboardColors.primaryContainer,
        ),
      );
    }
  }

  void _addNewSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(SubtaskItem(
        id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        isDone: false,
      ));
      _newSubtaskController.clear();
      _isAddingSubtask = false;
    });
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _openDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DashboardColors.primary,
              onPrimary: DashboardColors.onPrimary,
              surface: DashboardColors.surfaceLow,
              onSurface: DashboardColors.onSurface,
            ),
            dialogBackgroundColor: DashboardColors.surfaceLowest,
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _openEstimatePicker() {
    showDialog(
      context: context,
      builder: (context) {
        double tempVal = _selectedEstimate;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DashboardColors.surfaceLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .3)),
              ),
              title: Text(
                'Estimate Hours',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tempVal.round()} hours',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: DashboardColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: tempVal,
                    min: 1,
                    max: 40,
                    divisions: 39,
                    activeColor: DashboardColors.primary,
                    inactiveColor: DashboardColors.surfaceHighest,
                    onChanged: (val) {
                      setDialogState(() {
                        tempVal = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: DashboardColors.onSurfaceVariant)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: DashboardColors.primaryContainer),
                  onPressed: () {
                    setState(() {
                      _selectedEstimate = tempVal;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Confirm', style: TextStyle(color: DashboardColors.onPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAssigneePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DashboardColors.surfaceLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .3)),
              ),
              title: Text(
                'Assign Collaborators',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.onSurface,
                ),
              ),
              content: SizedBox(
                width: 320,
                child: ListView(
                  shrinkWrap: true,
                  children: mockTeamMembers.map((m) {
                    final isSelected = _selectedAssignees.any((selected) => selected.id == m.id);
                    return CheckboxListTile(
                      activeColor: DashboardColors.primary,
                      checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      secondary: CircleAvatar(
                        radius: 16,
                        backgroundColor: m.color.withValues(alpha: .18),
                        child: Text(
                          m.avatarText,
                          style: TextStyle(color: m.color, fontSize: 12, fontWeight: FontWeight.w900),
                        ),
                      ),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        m.isOnline ? 'Active Now' : 'Offline',
                        style: TextStyle(
                          color: m.isOnline ? const Color(0xFF7CFFB2) : DashboardColors.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedAssignees.add(m);
                          } else {
                            _selectedAssignees.removeWhere((selected) => selected.id == m.id);
                          }
                        });
                        setState(() {}); // Update parent screen state
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: DashboardColors.primaryContainer),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: DashboardColors.onPrimary)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deployTask() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: DashboardColors.onPrimary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Deploying "${_titleController.text.isNotEmpty ? _titleController.text : 'New Task'}" to workspace...',
                style: const TextStyle(color: DashboardColors.onPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: DashboardColors.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _DesktopBackdrop(),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .03),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: DashboardColors.primary.withValues(alpha: .20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .45),
                        blurRadius: 48,
                        offset: const Offset(0, 28),
                      ),
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: .12),
                        blurRadius: 34,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _Header(onClose: widget.onClose, selectedPriority: _selectedPriority),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _Label('TASK TITLE'),
                                    TextField(
                                      controller: _titleController,
                                      style: GoogleFonts.interTight(
                                        fontSize: 32,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardColors.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'What needs to be achieved?',
                                        hintStyle: TextStyle(color: DashboardColors.onSurfaceVariant.withValues(alpha: .30)),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: DashboardColors.outlineVariant.withValues(alpha: .30),
                                          ),
                                        ),
                                        focusedBorder: const UnderlineInputBorder(
                                          borderSide: BorderSide(color: DashboardColors.primary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    const _Label('DESCRIPTION'),
                                    _GlassBox(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          TextField(
                                            controller: _descriptionController,
                                            maxLines: 4,
                                            style: GoogleFonts.inter(fontSize: 16, height: 1.5),
                                            decoration: const InputDecoration.collapsed(
                                              hintText: 'Outline the objective and requirements...',
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: const [
                                              Icon(Icons.format_bold_rounded, size: 20),
                                              SizedBox(width: 10),
                                              Icon(Icons.format_italic_rounded, size: 20),
                                              SizedBox(width: 10),
                                              Icon(Icons.link_rounded, size: 20),
                                              Spacer(),
                                              Icon(Icons.auto_awesome_rounded, color: DashboardColors.primary, size: 20),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    // Dynamic Subtasks Section
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const _Label('SUBTASKS'),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: _generateSubtasksWithAi,
                                              child: MouseRegion(
                                                cursor: SystemMouseCursors.click,
                                                child: Text(
                                                  '＋ Generate with AI',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: SystemMouseCursors.click == SystemMouseCursors.click ? FontWeight.w800 : FontWeight.w500,
                                                    color: DashboardColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (_isAiGeneratingSubtasks)
                                          _GlassBox(
                                            padding: const EdgeInsets.all(20),
                                            tint: DashboardColors.primary.withValues(alpha: .06),
                                            borderColor: DashboardColors.primary.withValues(alpha: .2),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: DashboardColors.primary,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'AI Orchestrator is planning steps...',
                                                    style: GoogleFonts.jetBrainsMono(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w700,
                                                      color: DashboardColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _subtasks.length,
                                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                                            itemBuilder: (context, index) {
                                              final item = _subtasks[index];
                                              return TweenAnimationBuilder<double>(
                                                key: ValueKey(item.id),
                                                tween: Tween(begin: 0.0, end: 1.0),
                                                duration: const Duration(milliseconds: 350),
                                                builder: (context, animVal, child) {
                                                  return Opacity(
                                                    opacity: animVal,
                                                    child: Transform.translate(
                                                      offset: Offset(0, (1 - animVal) * 8),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: _GlassBox(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                                  child: Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            item.isDone = !item.isDone;
                                                          });
                                                        },
                                                        child: Icon(
                                                          item.isDone
                                                              ? Icons.check_box_rounded
                                                              : Icons.check_box_outline_blank_rounded,
                                                          color: item.isDone ? DashboardColors.primary : DashboardColors.outline,
                                                          size: 20,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          item.text,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 14,
                                                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                                                            color: item.isDone ? DashboardColors.onSurfaceVariant : DashboardColors.onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.close_rounded, size: 16),
                                                        color: DashboardColors.outline.withValues(alpha: .5),
                                                        onPressed: () {
                                                          setState(() {
                                                            _subtasks.removeAt(index);
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        const SizedBox(height: 8),
                                        if (_isAddingSubtask)
                                          _GlassBox(
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _newSubtaskController,
                                                    autofocus: true,
                                                    style: const TextStyle(fontSize: 14),
                                                    decoration: const InputDecoration(
                                                      hintText: 'Enter subtask...',
                                                      border: InputBorder.none,
                                                      hintStyle: TextStyle(color: DashboardColors.outline),
                                                    ),
                                                    onSubmitted: (_) => _addNewSubtask(),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.check_rounded, color: DashboardColors.primary),
                                                  onPressed: _addNewSubtask,
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.close_rounded, color: DashboardColors.error),
                                                  onPressed: () {
                                                    setState(() {
                                                      _isAddingSubtask = false;
                                                      _newSubtaskController.clear();
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                          )
                                        else
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _isAddingSubtask = true;
                                              });
                                            },
                                            child: _GlassBox(
                                              dashed: true,
                                              padding: const EdgeInsets.all(12),
                                              child: Row(
                                                children: const [
                                                  Icon(Icons.add_rounded, color: DashboardColors.outline, size: 20),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    'Add another subtask...',
                                                    style: TextStyle(color: DashboardColors.onSurfaceVariant, fontSize: 14),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  children: [
                                    // Interactive Intelligence Card
                                    _GlassBox(
                                      tint: DashboardColors.primary.withValues(alpha: .05),
                                      borderColor: DashboardColors.primary.withValues(alpha: .20),
                                      padding: const EdgeInsets.all(24),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: -48,
                                            right: -48,
                                            child: _Glow(size: 128, color: DashboardColors.primary.withValues(alpha: .08)),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const _Label('INTELLIGENCE SUGGESTIONS', color: DashboardColors.primary),
                                              const SizedBox(height: 12),
                                              const _SuggestionCard(),
                                              const SizedBox(height: 24),
                                              // Assigned Project selector
                                              const _Label('ASSIGNED PROJECT'),
                                              const SizedBox(height: 8),
                                              Theme(
                                                data: Theme.of(context).copyWith(
                                                  cardColor: DashboardColors.surfaceLow,
                                                ),
                                                child: PopupMenuButton<String>(
                                                  offset: const Offset(0, 48),
                                                  tooltip: 'Select Project',
                                                  onSelected: (value) {
                                                    setState(() {
                                                      _selectedProject = value;
                                                    });
                                                  },
                                                  itemBuilder: (context) => mockProjects.map((p) {
                                                    final isSelected = p['name'] == _selectedProject;
                                                    return PopupMenuItem<String>(
                                                      value: p['name'] as String,
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 10,
                                                            height: 10,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: p['color'] as Color,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          Text(
                                                            p['name'] as String,
                                                            style: TextStyle(
                                                              color: isSelected ? DashboardColors.primary : DashboardColors.onSurface,
                                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                  child: _GlassBox(
                                                    padding: const EdgeInsets.all(12),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 10,
                                                          height: 10,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: mockProjects.firstWhere((p) => p['name'] == _selectedProject)['color'] as Color,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            _selectedProject,
                                                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                                                          ),
                                                        ),
                                                        const Icon(Icons.keyboard_arrow_down_rounded, color: DashboardColors.outline, size: 20),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 24),
                                              // Manual override Priority chips selector
                                              const _Label('TASK PRIORITY'),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: ['Smart AI', 'High', 'Medium', 'Low'].map((priority) {
                                                  final isSelected = _selectedPriority == priority;
                                                  final Color accentColor = switch (priority) {
                                                    'High' => DashboardColors.error,
                                                    'Medium' => DashboardColors.secondary,
                                                    'Low' => DashboardColors.tertiary,
                                                    _ => DashboardColors.primary,
                                                  };
                                                  return Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _selectedPriority = priority;
                                                        });
                                                      },
                                                      child: Container(
                                                        margin: const EdgeInsets.symmetric(horizontal: 2),
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                        decoration: BoxDecoration(
                                                          color: isSelected ? accentColor.withValues(alpha: .18) : Colors.white.withValues(alpha: .02),
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(
                                                            color: isSelected ? accentColor : DashboardColors.outlineVariant.withValues(alpha: .2),
                                                          ),
                                                          boxShadow: isSelected ? [BoxShadow(color: accentColor.withValues(alpha: .1), blurRadius: 10)] : null,
                                                        ),
                                                        child: Center(
                                                          child: Text(
                                                            priority,
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                              color: isSelected ? accentColor : DashboardColors.onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                              const SizedBox(height: 24),
                                              // Due Date & Estimate Interactive Tiles
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const _Label('DUE DATE'),
                                                        const SizedBox(height: 8),
                                                        GestureDetector(
                                                          onTap: _openDatePicker,
                                                          child: _GlassBox(
                                                            padding: const EdgeInsets.all(12),
                                                            child: Row(
                                                              children: [
                                                                const Icon(Icons.event_rounded, color: DashboardColors.primary, size: 16),
                                                                const SizedBox(width: 8),
                                                                Flexible(
                                                                  child: Text(
                                                                    _formatDate(_selectedDate),
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const _Label('ESTIMATE'),
                                                        const SizedBox(height: 8),
                                                        GestureDetector(
                                                          onTap: _openEstimatePicker,
                                                          child: _GlassBox(
                                                            padding: const EdgeInsets.all(12),
                                                            child: Row(
                                                              children: [
                                                                const Icon(Icons.timer_rounded, color: DashboardColors.primary, size: 16),
                                                                const SizedBox(width: 8),
                                                                Flexible(
                                                                  child: Text(
                                                                    '${_selectedEstimate.round()} hours',
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                              // Tags block
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const _Label('TAGS & LABELS'),
                                                  const SizedBox(height: 10),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      ..._selectedTags.map((tag) {
                                                        final Color color = tag == '#Strategy'
                                                            ? DashboardColors.secondary
                                                            : DashboardColors.tertiary;
                                                        return GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _selectedTags.remove(tag);
                                                            });
                                                          },
                                                          child: _Tag(tag, color),
                                                        );
                                                      }),
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              final controller = TextEditingController();
                                                              return AlertDialog(
                                                                backgroundColor: DashboardColors.surfaceLow,
                                                                title: const Text('Add Tag'),
                                                                content: TextField(
                                                                  controller: controller,
                                                                  decoration: const InputDecoration(hintText: 'e.g. #Backend'),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: const Text('Cancel'),
                                                                  ),
                                                                  FilledButton(
                                                                    onPressed: () {
                                                                      final text = controller.text.trim();
                                                                      if (text.isNotEmpty) {
                                                                        setState(() {
                                                                          final cleanedText = text.startsWith('#') ? text : '#$text';
                                                                          if (!_selectedTags.contains(cleanedText)) {
                                                                            _selectedTags.add(cleanedText);
                                                                          }
                                                                        });
                                                                      }
                                                                      Navigator.pop(context);
                                                                    },
                                                                    child: const Text('Add'),
                                                                  ),
                                                                ],
                                                              );
                                                            },
                                                          );
                                                        },
                                                        child: const _AddTag(),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    const _AttachmentCard(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Footer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: const BoxDecoration(color: DashboardColors.surfaceHigh),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _openAssigneePicker,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Row(
                                  children: [
                                    if (_selectedAssignees.isEmpty)
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor: DashboardColors.surfaceHighest,
                                        child: Icon(Icons.person_rounded, size: 16, color: DashboardColors.outline),
                                      )
                                    else
                                      SizedBox(
                                        height: 32,
                                        width: (16 + (_selectedAssignees.length - 1) * 24).toDouble(),
                                        child: Stack(
                                          children: List.generate(_selectedAssignees.length, (idx) {
                                            final m = _selectedAssignees[idx];
                                            return Positioned(
                                              left: (idx * 24).toDouble(),
                                              child: CircleAvatar(
                                                radius: 16,
                                                backgroundColor: m.color.withValues(alpha: .2),
                                                child: Text(
                                                  m.avatarText,
                                                  style: TextStyle(
                                                    color: m.color,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedAssignees.isEmpty
                                          ? 'Assign to team members'
                                          : '${_selectedAssignees.length} assigned collaborators',
                                      style: GoogleFonts.inter(fontSize: 14, color: DashboardColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Draft saved successfully!')),
                                );
                              },
                              child: const Text('Save Draft'),
                            ),
                            const SizedBox(width: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [DashboardColors.primary, DashboardColors.secondary],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: DashboardColors.primary.withValues(alpha: .30),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: DashboardColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                                ),
                                onPressed: _deployTask,
                                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                                label: const Text('Deploy Task'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // AI Suggestion Dock (Dynamic trượt từ đáy màn hình)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          bottom: _showSuggestionDock ? 36 : -100,
          left: 0,
          right: 0,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DashboardColors.primary.withValues(alpha: .22)),
                    boxShadow: [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: .15),
                        blurRadius: 34,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: DashboardColors.secondary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _suggestionText,
                        style: const TextStyle(color: DashboardColors.onSurface, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 20),
                      TextButton(
                        onPressed: _applyAiSuggestion,
                        style: TextButton.styleFrom(
                          foregroundColor: DashboardColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showSuggestionDock = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: DashboardColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Dismiss'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onClose, required this.selectedPriority});

  final VoidCallback? onClose;
  final String selectedPriority;

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
                Text(
                  'PRIORITY: ${selectedPriority.toUpperCase()}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.primary,
                  ),
                ),
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

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      tint: DashboardColors.surface.withValues(alpha: .40),
      borderColor: DashboardColors.primary.withValues(alpha: .10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: DashboardColors.primary, size: 16),
              const SizedBox(width: 8),
              Text('Dynamic Focus Insights', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your focus heatmap in balance by deploying high complexity tasks during peak energy hours.',
            style: GoogleFonts.inter(fontSize: 12, height: 1.45, color: DashboardColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('ATTACHMENTS'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .20), width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.upload_file_rounded),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Upload files',
                      style: GoogleFonts.inter(color: DashboardColors.primary, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: ' or drag and drop', style: GoogleFonts.inter(color: DashboardColors.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('PDF, PNG, JPG up to 10MB', style: GoogleFonts.inter(fontSize: 12, color: DashboardColors.outline)),
            ],
          ),
        ),
      ],
    );
  }
}

class _GlassBox extends StatelessWidget {
  const _GlassBox({
    required this.child,
    this.padding,
    this.tint,
    this.borderColor,
    this.dashed = false,
  });

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
          decoration: BoxDecoration(
            color: tint ?? Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? DashboardColors.onSurface.withValues(alpha: dashed ? .14 : .08),
            ),
          ),
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        height: 1,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: color ?? DashboardColors.onSurfaceVariant,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: color)),
    );
  }
}

class _AddTag extends StatelessWidget {
  const _AddTag();

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: DashboardColors.outlineVariant.withValues(alpha: .30)),
        ),
        child: const Icon(Icons.add_rounded, size: 16),
      );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 20)],
        ),
      );
}

class _DesktopBackdrop extends StatelessWidget {
  const _DesktopBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DashboardColors.surfaceLowest,
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: _Glow(size: 420, color: DashboardColors.primary.withValues(alpha: .07)),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(size: 340, color: DashboardColors.secondary.withValues(alpha: .08)),
          ),
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
        ],
      ),
    );
  }
}

class _BackdropHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text('Active Workspace', style: GoogleFonts.interTight(fontSize: 48, fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            width: 128,
            height: 40,
            decoration: BoxDecoration(color: DashboardColors.surfaceContainer, borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(width: 16),
          Container(
            width: 128,
            height: 40,
            decoration: BoxDecoration(color: DashboardColors.primary, borderRadius: BorderRadius.circular(8)),
          ),
        ],
      );
}

class _BackdropCard extends StatelessWidget {
  const _BackdropCard();

  @override
  Widget build(BuildContext context) => const _GlassBox(
        padding: EdgeInsets.all(24),
        child: SizedBox(height: 208),
      );
}
