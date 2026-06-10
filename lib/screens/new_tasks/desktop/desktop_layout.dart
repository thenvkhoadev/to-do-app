import 'dart:convert';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/data/datasource/attachment_datasource.dart';
import 'package:to_do_app/features/tasks/data/models/category_model.dart';
import 'package:to_do_app/features/tasks/data/models/tag_model.dart';
import 'package:to_do_app/core/services/app_providers.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/xp/data/datasource/xp_remote_datasource.dart';
import 'package:to_do_app/features/xp/presentation/providers/xp_providers.dart';
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
    this.avatarUrl,
  });
  final String id;
  final String name;
  final String avatarText;
  final Color color;
  final bool isOnline;
  final String? avatarUrl;
}



const mockProjects = [
  {'name': 'AI Core 2.0', 'color': DashboardColors.primary},
  {'name': 'Quantum Project', 'color': DashboardColors.tertiary},
  {'name': 'Security Audit', 'color': DashboardColors.outline},
  {'name': 'Latency Analysis', 'color': DashboardColors.secondary},
];

class NewTasksDesktopLayout extends ConsumerStatefulWidget {
  const NewTasksDesktopLayout({this.onClose, super.key});

  final VoidCallback? onClose;

  @override
  ConsumerState<NewTasksDesktopLayout> createState() =>
      _NewTasksDesktopLayoutState();
}

class _NewTasksDesktopLayoutState extends ConsumerState<NewTasksDesktopLayout> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _newSubtaskController = TextEditingController();
  late final quill.QuillController _quillController;
  bool _isAddingSubtask = false;

  // Form State
  String? _selectedCategoryId;
  String _selectedPriority = 'medium';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  double _selectedEstimate = 4.0;
  final List<String> _selectedTagIds = [];
  final List<TeamMember> _selectedAssignees = [];
  List<PlatformFileInfo> _selectedFiles = [];
  final FocusNode _editorFocusNode = FocusNode();
  final Map<String, quill.Attribute> _explicitActiveAttributes = {};
  int? _lastToggledOffset;

  // Subtasks State
  final List<SubtaskItem> _subtasks = [];
  bool _isAiGeneratingSubtasks = false;
  bool _localSavingDraft = false;
  bool _localDeploying = false;

  // AI Suggestion Dock State
  bool _showSuggestionDock = false;
  String _suggestionText = '';
  String _suggestionApplyType = ''; // 'priority', 'assignee', 'milestones'

  @override
  void initState() {
    super.initState();
    _quillController = quill.QuillController.basic();
    _quillController.addListener(_onQuillSelectionChanged);
    _titleController.addListener(_onInputChanged);
    _descriptionController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _quillController.removeListener(_onQuillSelectionChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _newSubtaskController.dispose();
    _quillController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onQuillSelectionChanged() {
    if (mounted) {
      final sel = _quillController.selection;
      if (sel.isValid) {
        final currentOffset = sel.start;
        if (sel.isCollapsed) {
          if (_lastToggledOffset != null && currentOffset == _lastToggledOffset) {
            final style = _quillController.getSelectionStyle();
            bool needReapply = false;
            for (final attr in _explicitActiveAttributes.values) {
              final hasAttr = style.containsKey(attr.key) &&
                  style.attributes[attr.key]?.value == true;
              if (!hasAttr) {
                needReapply = true;
                break;
              }
            }
            if (needReapply) {
              for (final attr in _explicitActiveAttributes.values) {
                _quillController.formatSelection(attr);
              }
            }
          } else {
            _explicitActiveAttributes.clear();
            final style = _quillController.getSelectionStyle();
            for (final attr in [quill.Attribute.bold, quill.Attribute.italic]) {
              final hasAttr = style.containsKey(attr.key) &&
                  style.attributes[attr.key]?.value == true;
              if (hasAttr) {
                _explicitActiveAttributes[attr.key] = attr;
              }
            }
            _lastToggledOffset = currentOffset;
          }
        } else {
          _explicitActiveAttributes.clear();
          final style = _quillController.getSelectionStyle();
          for (final attr in [quill.Attribute.bold, quill.Attribute.italic]) {
            final hasAttr = style.containsKey(attr.key) &&
                style.attributes[attr.key]?.value == true;
            if (hasAttr) {
              _explicitActiveAttributes[attr.key] = attr;
            }
          }
          _lastToggledOffset = currentOffset;
        }
      }
      setState(() {});
    }
  }

  void _onInputChanged() {
    final title = _titleController.text.toLowerCase();
    final desc = _descriptionController.text.toLowerCase();

    if (title.contains('security') ||
        desc.contains('security') ||
        title.contains('audit') ||
        desc.contains('audit')) {
      setState(() {
        _showSuggestionDock = true;
        _suggestionText =
            'AI Suggestion: Link this task to security standards & assign to Kevin Park (Security lead).';
        _suggestionApplyType = 'security_assign';
      });
    } else if (title.contains('spec') ||
        desc.contains('spec') ||
        title.contains('inference') ||
        desc.contains('inference')) {
      setState(() {
        _showSuggestionDock = true;
        _suggestionText =
            'AI Suggestion: High correlation with Neural Engine Specs. Suggest High Priority & 8h Estimate.';
        _suggestionApplyType = 'priority_high';
      });
    } else if (title.isNotEmpty || desc.isNotEmpty) {
      setState(() {
        _showSuggestionDock = true;
        _suggestionText =
            'AI Suggestion: Split strategy review into 4 milestones for optimal progress tracking.';
        _suggestionApplyType = 'milestones';
      });
    } else {
      setState(() {
        _showSuggestionDock = false;
      });
    }
  }

  TeamMember _mapUserToTeamMember(UserProfileModel user) {
    final name = user.fullName ?? user.username ?? user.email;
    final avatarText = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final colors = [
      DashboardColors.primary,
      DashboardColors.secondary,
      DashboardColors.tertiary,
      DashboardColors.outline,
    ];
    final index = user.id.hashCode.abs() % colors.length;
    final color = colors[index];
    return TeamMember(
      id: user.id,
      name: name,
      avatarText: avatarText,
      color: color,
      isOnline: true,
      avatarUrl: user.avatarUrl,
    );
  }

  void _applyAiSuggestion() {
    setState(() {
      if (_suggestionApplyType == 'security_assign') {
        final allUsers = ref.read(allUsersProvider).valueOrNull ?? [];
        final kevinUser = allUsers.firstWhere(
          (u) => (u.fullName ?? u.username ?? '').toLowerCase().contains('kevin'),
          orElse: () => allUsers.isNotEmpty
              ? allUsers.first
              : const UserProfileModel(
                  id: 'kevin',
                  email: 'kevin@example.com',
                  fullName: 'Kevin Park',
                ),
        );
        final kevinMember = _mapUserToTeamMember(kevinUser);
        if (!_selectedAssignees.any((m) => m.id == kevinMember.id)) {
          _selectedAssignees.add(kevinMember);
        }
        _selectedPriority = 'high';
      } else if (_suggestionApplyType == 'priority_high') {
        _selectedPriority = 'high';
        _selectedEstimate = 8.0;
      } else if (_suggestionApplyType == 'milestones') {
        // AI suggest subtasks directly
        _generateSubtasksWithAi();
      }
      _showSuggestionDock = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'AI Suggestion successfully applied to Task Orchestration!',
        ),
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
          SubtaskItem(
            id: 'ai-sub-1',
            text: 'Verify model latency on mobile edge devices',
            isDone: false,
          ),
          SubtaskItem(
            id: 'ai-sub-2',
            text: 'Draft benchmark report for board presentation',
            isDone: false,
          ),
          SubtaskItem(
            id: 'ai-sub-3',
            text: 'Establish backup fallbacks for API failure states',
            isDone: false,
          ),
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

  void _toggleQuillFormat(quill.Attribute attribute) {
    if (!_editorFocusNode.hasFocus) {
      _editorFocusNode.requestFocus();
    }

    final sel = _quillController.selection;
    if (!sel.isValid) return;

    _lastToggledOffset = sel.start;

    if (sel.isCollapsed) {
      final plainText = _quillController.document.toPlainText();
      final cursor = sel.start;
      int start = cursor;
      int end = cursor;
      while (start > 0 && _isQuillWordChar(plainText[start - 1])) {
        start--;
      }
      while (end < plainText.length && _isQuillWordChar(plainText[end])) {
        end++;
      }

      if (start != end) {
        _quillController.updateSelection(
          TextSelection(baseOffset: start, extentOffset: end),
          quill.ChangeSource.local,
        );

        final style = _quillController.getSelectionStyle();
        final isActive = style.containsKey(attribute.key) &&
            style.attributes[attribute.key]?.value == true;

        if (isActive) {
          _explicitActiveAttributes.remove(attribute.key);
          _quillController.formatSelection(
              quill.Attribute.clone(attribute, null));
        } else {
          _explicitActiveAttributes[attribute.key] = attribute;
          _quillController.formatSelection(attribute);
        }

        _quillController.updateSelection(
          TextSelection.collapsed(offset: end),
          quill.ChangeSource.local,
        );
        _lastToggledOffset = end;
        return;
      }
    }

    // Check if the attribute is already applied on the selection/cursor
    final style = _quillController.getSelectionStyle();
    final isActive = style.containsKey(attribute.key) &&
        style.attributes[attribute.key]?.value == true;

    if (isActive) {
      _explicitActiveAttributes.remove(attribute.key);
      _quillController.formatSelection(
          quill.Attribute.clone(attribute, null));
    } else {
      _explicitActiveAttributes[attribute.key] = attribute;
      _quillController.formatSelection(attribute);
    }
  }

  bool _isQuillWordChar(String c) => RegExp(r'[\wÀ-ɏ]').hasMatch(c);

  void _toggleBulletList() {
    if (!_editorFocusNode.hasFocus) _editorFocusNode.requestFocus();
    final style = _quillController.getSelectionStyle();
    final currentList = style.attributes[quill.Attribute.list.key]?.value;
    if (currentList == 'bullet') {
      _quillController.formatSelection(
          quill.Attribute.clone(quill.Attribute.list, null));
    } else {
      _quillController.formatSelection(const quill.ListAttribute('bullet'));
    }
  }

  Future<void> _insertQuillLink() async {
    final urlController = TextEditingController();
    final labelController = TextEditingController();

    // Pre-fill label from selection
    final sel = _quillController.selection;
    if (sel.isValid && !sel.isCollapsed) {
      final doc = _quillController.document;
      labelController.text = doc.getPlainText(sel.start, sel.end - sel.start);
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DashboardColors.surfaceLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: DashboardColors.outlineVariant.withValues(alpha: .3)),
        ),
        title: Text('Insert Link',
            style: GoogleFonts.interTight(
                fontWeight: FontWeight.w700,
                color: DashboardColors.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                  labelText: 'URL', hintText: 'https://'),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: DashboardColors.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: DashboardColors.primaryContainer),
            onPressed: () {
              final url = urlController.text.trim();
              final label = labelController.text.trim();
              if (url.isNotEmpty) {
                final sel = _quillController.selection;
                if (sel.isValid && !sel.isCollapsed) {
                  // Apply link attribute to selection
                  _quillController.formatSelection(
                      quill.LinkAttribute(url));
                } else {
                  // Insert label text with link
                  final insertText = label.isNotEmpty ? label : url;
                  _quillController.document.insert(
                      sel.isValid ? sel.start : 0, insertText);
                  final insertSel = TextSelection(
                    baseOffset: sel.isValid ? sel.start : 0,
                    extentOffset:
                        (sel.isValid ? sel.start : 0) + insertText.length,
                  );
                  _quillController.updateSelection(
                      insertSel, quill.ChangeSource.local);
                  _quillController.formatSelection(
                      quill.LinkAttribute(url));
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Insert',
                style: TextStyle(color: DashboardColors.onPrimary)),
          ),
        ],
      ),
    );

    urlController.dispose();
    labelController.dispose();
  }

  void _addNewSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(
        SubtaskItem(
          id: 'sub-${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          isDone: false,
        ),
      );
      _newSubtaskController.clear();
      _isAddingSubtask = false;
    });
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
            dialogTheme: const DialogThemeData(
              backgroundColor: DashboardColors.surfaceLowest,
            ),
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
                side: BorderSide(
                  color: DashboardColors.outlineVariant.withValues(alpha: .3),
                ),
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.primaryContainer,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedEstimate = tempVal;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Confirm',
                    style: TextStyle(color: DashboardColors.onPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAssigneePicker(List<TeamMember> teamMembers) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DashboardColors.surfaceLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: DashboardColors.outlineVariant.withValues(alpha: .3),
                ),
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
                  children:
                      teamMembers.map((m) {
                        final isSelected = _selectedAssignees.any(
                          (selected) => selected.id == m.id,
                        );
                        return CheckboxListTile(
                          activeColor: DashboardColors.primary,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          secondary: CircleAvatar(
                            radius: 16,
                            backgroundColor: m.color.withValues(alpha: .18),
                            backgroundImage: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                                ? NetworkImage(m.avatarUrl!)
                                : null,
                            child: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                                ? null
                                : Text(
                                    m.avatarText,
                                    style: TextStyle(
                                      color: m.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                          ),
                          title: Text(
                            m.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            m.isOnline ? 'Active Now' : 'Offline',
                            style: TextStyle(
                              color:
                                  m.isOnline
                                      ? const Color(0xFF7CFFB2)
                                      : DashboardColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                _selectedAssignees.add(m);
                              } else {
                                _selectedAssignees.removeWhere(
                                  (selected) => selected.id == m.id,
                                );
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
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.primaryContainer,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: DashboardColors.onPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deployTask({bool isDraft = false}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title.')),
      );
      return;
    }

    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    setState(() {
      if (isDraft) {
        _localSavingDraft = true;
      } else {
        _localDeploying = true;
      }
    });

    try {
      final priorityMap = {
        'Smart AI': 'medium',
        'High': 'high',
        'Medium': 'medium',
        'Low': 'low',
        'medium': 'medium',
        'high': 'high',
        'low': 'low',
        'urgent': 'urgent',
      };

      final plain = _quillController.document.toPlainText().trim();
      final created = await ref.read(taskCreationProvider.notifier).createTask(
            userId: user.id,
            title: title,
            description: plain.isEmpty
                ? null
                : jsonEncode(_quillController.document.toDelta().toJson()),
            categoryId: _selectedCategoryId,
            priority: priorityMap[_selectedPriority] ?? 'medium',
            status: isDraft ? 'draft' : 'todo',
            dueDate: _selectedDate,
            estimatedMinutes: (_selectedEstimate * 60).round(),
            tagIds: _selectedTagIds,
            attachments: _selectedFiles,
            assigneeIds: _selectedAssignees.map((m) => m.id).toList(),
            subtaskTitles: _subtasks.map((e) => e.text).toList(),
          );

      if (!mounted) return;

      if (created != null) {
        ref.invalidate(taskAttachmentsProvider(created.id));
        // Award 2 XP for task creation (get_task_creation_xp() = 2)
        try {
          await XpRemoteDataSource(
            ref.read(supabaseClientProvider),
          ).awardXp(
            userId: user.id,
            taskId: created.id,
            xpGained: 2,
            reason: 'Task Created',
          );
          ref.invalidate(xpLogsProvider);
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.rocket_launch_rounded,
                    color: DashboardColors.onPrimary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDraft
                        ? 'Saved "${created.title}" as draft!'
                        : 'Deployed "${created.title}" to workspace!',
                    style: const TextStyle(
                        color: DashboardColors.onPrimary,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            backgroundColor: DashboardColors.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onClose?.call();
      } else {
        final error = ref.read(taskCreationProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create task: ${error ?? 'Unknown error'}'),
            backgroundColor: DashboardColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _localSavingDraft = false;
          _localDeploying = false;
        });
      }
    }
  }

  Future<void> _showAddTagDialog() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final controller = TextEditingController();
    String selectedColorHex = '#8083FF';
    final colors = ['#8083FF', '#7CFFB2', '#FF6B9D', '#FFD166', '#06D6A0', '#FF5733'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DashboardColors.surfaceLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: DashboardColors.outlineVariant.withValues(alpha: .3),
                ),
              ),
              title: Text(
                'Create New Tag',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.onSurface,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: DashboardColors.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Tag Name',
                      labelStyle: const TextStyle(color: DashboardColors.onSurfaceVariant),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: DashboardColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Tag Color',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DashboardColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: colors.map((colorHex) {
                      final color = _parseTagColor(colorHex);
                      final isSelected = selectedColorHex == colorHex;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            selectedColorHex = colorHex;
                          });
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.primaryContainer,
                  ),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    try {
                      final tagDs = ref.read(tagDataSourceProvider);
                      final newTag = await tagDs.createTag(TagModel(
                        id: '',
                        userId: user.id,
                        name: name,
                        color: selectedColorHex,
                      ));
                      // Automatically select the newly created tag
                      setState(() {
                        _selectedTagIds.add(newTag.id);
                      });
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create tag: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Create',
                    style: TextStyle(color: DashboardColors.onPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showAddCategoryDialog() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final controller = TextEditingController();
    String selectedColorHex = '#8083FF';
    String selectedIcon = 'work';
    final colors = ['#8083FF', '#7CFFB2', '#FF6B9D', '#FFD166', '#06D6A0', '#FF5733'];
    final icons = {
      'work': Icons.work_rounded,
      'person': Icons.person_rounded,
      'school': Icons.school_rounded,
      'heart': Icons.favorite_rounded,
      'balance': Icons.account_balance_rounded,
      'sports': Icons.sports_basketball_rounded,
    };

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: DashboardColors.surfaceLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: DashboardColors.outlineVariant.withValues(alpha: .3),
                ),
              ),
              title: Text(
                'Create New Category',
                style: GoogleFonts.interTight(
                  fontWeight: FontWeight.w700,
                  color: DashboardColors.onSurface,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: DashboardColors.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        labelStyle: const TextStyle(color: DashboardColors.onSurfaceVariant),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: DashboardColors.outlineVariant.withValues(alpha: .3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: DashboardColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Select Category Color',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: colors.map((colorHex) {
                        final color = _parseTagColor(colorHex);
                        final isSelected = selectedColorHex == colorHex;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorHex = colorHex;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Select Icon',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: DashboardColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: icons.entries.map((entry) {
                        final isSelected = selectedIcon == entry.key;
                        final color = _parseTagColor(selectedColorHex);
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = entry.key;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: .18)
                                  : Colors.white.withValues(alpha: .02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : DashboardColors.outlineVariant.withValues(alpha: .2),
                              ),
                            ),
                            child: Icon(
                              entry.value,
                              color: isSelected ? color : DashboardColors.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: DashboardColors.onSurfaceVariant),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardColors.primaryContainer,
                  ),
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    try {
                      final categoryDs = ref.read(categoryDataSourceProvider);
                      final newCat = await categoryDs.createCategory(CategoryModel(
                        id: '',
                        userId: user.id,
                        name: name,
                        color: selectedColorHex,
                        icon: selectedIcon,
                      ));
                      // Automatically select the newly created category
                      setState(() {
                        _selectedCategoryId = newCat.id;
                      });
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to create category: $e')),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Create',
                    style: TextStyle(color: DashboardColors.onPrimary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(userCategoriesProvider);
    final tagsAsync = ref.watch(userTagsProvider);
    final categories = categoriesAsync.valueOrNull ?? [];
    final tags = tagsAsync.valueOrNull ?? [];
    final isDeploying = _localSavingDraft || _localDeploying;

    final allUsersAsync = ref.watch(allUsersProvider);
    final allUsers = allUsersAsync.valueOrNull ?? [];
    final teamMembers = allUsers.map(_mapUserToTeamMember).toList();
    final currentUser = ref.watch(authControllerProvider).valueOrNull;
    final otherTeamMembers = teamMembers.where((m) => m.id != currentUser?.id).toList();

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
                    border: Border.all(
                      color: DashboardColors.primary.withValues(alpha: .20),
                    ),
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
                      _Header(
                        onClose: widget.onClose,
                        selectedPriority: _selectedPriority,
                      ),
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
                                    if (_selectedAssignees.isNotEmpty) ...[
                                      _TeamPresenceRow(
                                        members: _selectedAssignees,
                                        fallbackMembers: teamMembers,
                                      ),
                                      const SizedBox(height: 24),
                                    ],
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
                                        hintStyle: TextStyle(
                                          color: DashboardColors
                                              .onSurfaceVariant
                                              .withValues(alpha: .30),
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: DashboardColors
                                                .outlineVariant
                                                .withValues(alpha: .30),
                                          ),
                                        ),
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: DashboardColors.primary,
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 36),
                                    const _Label('DESCRIPTION'),
                                    const SizedBox(height: 12),
                                    _GlassBox(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Toolbar
                                          Builder(
                                            builder: (context) {
                                              final style = _quillController.getSelectionStyle();
                                              final isBold = style.containsKey(quill.Attribute.bold.key) &&
                                                  style.attributes[quill.Attribute.bold.key]?.value == true;
                                              final isItalic = style.containsKey(quill.Attribute.italic.key) &&
                                                  style.attributes[quill.Attribute.italic.key]?.value == true;
                                              return Row(
                                                children: [
                                                  _FormatButton(
                                                    icon: Icons.format_bold_rounded,
                                                    isSelected: isBold,
                                                    onTap: () => _toggleQuillFormat(
                                                        quill.Attribute.bold),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  _FormatButton(
                                                    icon:
                                                        Icons.format_italic_rounded,
                                                    isSelected: isItalic,
                                                    onTap: () => _toggleQuillFormat(
                                                        quill.Attribute.italic),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  _FormatButton(
                                                    icon: Icons.link_rounded,
                                                    onTap: () =>
                                                        _insertQuillLink(),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  _FormatButton(
                                                    icon: Icons.format_list_bulleted_rounded,
                                                    onTap: () => _toggleBulletList(),
                                                  ),
                                                  const Spacer(),
                                                  const Icon(
                                                    Icons.auto_awesome_rounded,
                                                    color: DashboardColors.primary,
                                                    size: 20,
                                                  ),
                                                ],
                                              );
                                            }
                                          ),
                                          const SizedBox(height: 10),
                                          const Divider(
                                            height: 1,
                                            color: DashboardColors.surfaceHighest,
                                          ),
                                          const SizedBox(height: 10),
                                          // Editor
                                          quill.QuillEditor.basic(
                                            controller: _quillController,
                                            focusNode: _editorFocusNode,
                                            config: quill.QuillEditorConfig(
                                              minHeight: 100,
                                              maxHeight: 200,
                                              placeholder:
                                                  'Outline the objective and requirements...',
                                              customStyles:
                                                  quill.DefaultStyles(
                                                paragraph: quill.DefaultTextBlockStyle(
                                                  GoogleFonts.inter(
                                                    fontSize: 16,
                                                    height: 1.5,
                                                    color: DashboardColors
                                                        .onSurface,
                                                  ),
                                                  quill.HorizontalSpacing.zero,
                                                  quill.VerticalSpacing.zero,
                                                  quill.VerticalSpacing.zero,
                                                  null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const _AiDraftNotesCard(),
                                    const SizedBox(height: 32),
                                    // Dynamic Subtasks Section
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const _Label('SUBTASKS'),
                                            const Spacer(),
                                            GestureDetector(
                                              onTap: _generateSubtasksWithAi,
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                child: Text(
                                                  '＋ Generate with AI',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        DashboardColors.primary,
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
                                            tint: DashboardColors.primary
                                                .withValues(alpha: .06),
                                            borderColor: DashboardColors.primary
                                                .withValues(alpha: .2),
                                            child: Center(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              DashboardColors
                                                                  .primary,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'AI Orchestrator is planning steps...',
                                                    style:
                                                        GoogleFonts.jetBrainsMono(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              DashboardColors
                                                                  .primary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: _subtasks.length,
                                            separatorBuilder:
                                                (_, __) =>
                                                    const SizedBox(height: 8),
                                            itemBuilder: (context, index) {
                                              final item = _subtasks[index];
                                              return TweenAnimationBuilder<
                                                double
                                              >(
                                                key: ValueKey(item.id),
                                                tween: Tween(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ),
                                                duration: const Duration(
                                                  milliseconds: 350,
                                                ),
                                                builder: (
                                                  context,
                                                  animVal,
                                                  child,
                                                ) {
                                                  return Opacity(
                                                    opacity: animVal,
                                                    child: Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        (1 - animVal) * 8,
                                                      ),
                                                      child: child,
                                                    ),
                                                  );
                                                },
                                                child: _GlassBox(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          setState(() {
                                                            item.isDone =
                                                                !item.isDone;
                                                          });
                                                        },
                                                        child: MouseRegion(
                                                          cursor:
                                                              SystemMouseCursors
                                                                  .click,
                                                          child: Icon(
                                                            item.isDone
                                                                ? Icons
                                                                    .check_box_rounded
                                                                : Icons
                                                                    .check_box_outline_blank_rounded,
                                                            color:
                                                                item.isDone
                                                                    ? DashboardColors
                                                                        .primary
                                                                    : DashboardColors
                                                                        .outline,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          item.text,
                                                          style: GoogleFonts.inter(
                                                            fontSize: 14,
                                                            decoration:
                                                                item.isDone
                                                                    ? TextDecoration
                                                                        .lineThrough
                                                                    : null,
                                                            color:
                                                                item.isDone
                                                                    ? DashboardColors
                                                                        .onSurfaceVariant
                                                                    : DashboardColors
                                                                        .onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.close_rounded,
                                                          size: 16,
                                                        ),
                                                        color: DashboardColors
                                                            .outline
                                                            .withValues(
                                                              alpha: .5,
                                                            ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _subtasks.removeAt(
                                                              index,
                                                            );
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
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _newSubtaskController,
                                                    autofocus: true,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                          hintText:
                                                              'Enter subtask...',
                                                          border:
                                                              InputBorder.none,
                                                          hintStyle: TextStyle(
                                                            color:
                                                                DashboardColors
                                                                    .outline,
                                                          ),
                                                        ),
                                                    onSubmitted:
                                                        (_) => _addNewSubtask(),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.check_rounded,
                                                    color:
                                                        DashboardColors.primary,
                                                  ),
                                                  onPressed: _addNewSubtask,
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    color:
                                                        DashboardColors.error,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _isAddingSubtask = false;
                                                      _newSubtaskController
                                                          .clear();
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
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: _GlassBox(
                                                dashed: true,
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                child: Row(
                                                  children: const [
                                                    Icon(
                                                      Icons.add_rounded,
                                                      color:
                                                          DashboardColors
                                                              .outline,
                                                      size: 20,
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text(
                                                      'Add another subtask...',
                                                      style: TextStyle(
                                                        color:
                                                            DashboardColors
                                                                .onSurfaceVariant,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(height: 24),
                                        const _SmartCreationTabs(),
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
                                      tint: DashboardColors.primary.withValues(
                                        alpha: .05,
                                      ),
                                      borderColor: DashboardColors.primary
                                          .withValues(alpha: .20),
                                      padding: const EdgeInsets.all(24),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: -48,
                                            right: -48,
                                            child: _Glow(
                                              size: 128,
                                              color: DashboardColors.primary
                                                  .withValues(alpha: .08),
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const _Label(
                                                'INTELLIGENCE SUGGESTIONS',
                                                color: DashboardColors.primary,
                                              ),
                                              const SizedBox(height: 12),
                                              const _CreationAiInsightsCard(),
                                              const SizedBox(height: 12),
                                              const _SuggestionCard(),
                                              const SizedBox(height: 24),
                                              // Assigned Project selector
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const _Label('ASSIGNED PROJECT'),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.add_rounded,
                                                      color: DashboardColors.primary,
                                                      size: 18,
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: _showAddCategoryDialog,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              _CategoryDropdown(
                                                categories: categories,
                                                selectedId: _selectedCategoryId,
                                                onSelected: (id) {
                                                  setState(() {
                                                    _selectedCategoryId = id;
                                                  });
                                                },
                                              ),
                                              const SizedBox(height: 24),
                                              // Manual override Priority chips selector
                                              const _Label('TASK PRIORITY'),
                                              const SizedBox(height: 8),
                                              Row(
                                                children:
                                                    [
                                                      'medium',
                                                      'high',
                                                      'urgent',
                                                      'low',
                                                    ].map((priority) {
                                                      final isSelected =
                                                          _selectedPriority ==
                                                          priority;
                                                      final Color accentColor =
                                                          switch (priority) {
                                                            'urgent' =>
                                                              DashboardColors
                                                                  .error,
                                                            'high' =>
                                                              DashboardColors
                                                                  .error,
                                                            'low' =>
                                                              DashboardColors
                                                                  .tertiary,
                                                            _ =>
                                                              DashboardColors
                                                                  .secondary,
                                                          };
                                                      final label =
                                                          priority[0].toUpperCase() +
                                                          priority.substring(1);
                                                      return Expanded(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              _selectedPriority =
                                                                  priority;
                                                            });
                                                          },
                                                          child: MouseRegion(
                                                            cursor:
                                                                SystemMouseCursors
                                                                    .click,
                                                            child: Container(
                                                              margin:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        2,
                                                                  ),
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: isSelected
                                                                    ? accentColor.withValues(
                                                                        alpha: .18,
                                                                      )
                                                                    : Colors.white.withValues(
                                                                        alpha: .02,
                                                                      ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      10,
                                                                    ),
                                                                border: Border.all(
                                                                  color:
                                                                      isSelected
                                                                          ? accentColor
                                                                          : DashboardColors.outlineVariant.withValues(
                                                                            alpha:
                                                                                .2,
                                                                          ),
                                                                ),
                                                                boxShadow:
                                                                    isSelected
                                                                        ? [
                                                                          BoxShadow(
                                                                            color: accentColor.withValues(
                                                                              alpha:
                                                                                  .1,
                                                                            ),
                                                                            blurRadius:
                                                                                10,
                                                                          ),
                                                                        ]
                                                                        : null,
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  label,
                                                                  style: GoogleFonts.inter(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        isSelected
                                                                            ? FontWeight.w800
                                                                            : FontWeight.w600,
                                                                    color:
                                                                        isSelected
                                                                            ? accentColor
                                                                            : DashboardColors.onSurfaceVariant,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                              const SizedBox(height: 16),
                                              const _SmartPriorityHeatmap(),
                                              const SizedBox(height: 24),

                                              // Due Date & Estimate Interactive Tiles
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const _Label(
                                                          'DUE DATE',
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        GestureDetector(
                                                          onTap:
                                                              _openDatePicker,
                                                          child: MouseRegion(
                                                            cursor:
                                                                SystemMouseCursors
                                                                    .click,
                                                            child: _GlassBox(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .event_rounded,
                                                                    color:
                                                                        DashboardColors
                                                                            .primary,
                                                                    size: 16,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Flexible(
                                                                    child: Text(
                                                                      _formatDate(
                                                                        _selectedDate,
                                                                      ),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            13,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const _Label(
                                                          'ESTIMATE',
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        GestureDetector(
                                                          onTap:
                                                              _openEstimatePicker,
                                                          child: MouseRegion(
                                                            cursor:
                                                                SystemMouseCursors
                                                                    .click,
                                                            child: _GlassBox(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    12,
                                                                  ),
                                                              child: Row(
                                                                children: [
                                                                  const Icon(
                                                                    Icons
                                                                        .timer_rounded,
                                                                    color:
                                                                        DashboardColors
                                                                            .primary,
                                                                    size: 16,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Flexible(
                                                                    child: Text(
                                                                      '${_selectedEstimate.round()} hours',
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                      style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            13,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                              _FocusForecastCard(
                                                hours: _selectedEstimate,
                                              ),
                                              const SizedBox(height: 24),
                                              // Tags block
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      const _Label('TAGS & LABELS'),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.add_rounded,
                                                          color: DashboardColors.primary,
                                                          size: 18,
                                                        ),
                                                        padding: EdgeInsets.zero,
                                                        constraints: const BoxConstraints(),
                                                        onPressed: _showAddTagDialog,
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Wrap(
                                                    spacing: 8,
                                                    runSpacing: 8,
                                                    children: [
                                                      ...tags.map((tag) {
                                                        final isSelected =
                                                            _selectedTagIds
                                                                .contains(
                                                                    tag.id);
                                                        final color = _parseTagColor(
                                                            tag.color);
                                                        return GestureDetector(
                                                          onTap: () {
                                                            setState(() {
                                                              if (isSelected) {
                                                                _selectedTagIds
                                                                    .remove(
                                                                        tag.id);
                                                              } else {
                                                                _selectedTagIds
                                                                    .add(
                                                                        tag.id);
                                                              }
                                                            });
                                                          },
                                                          child: MouseRegion(
                                                            cursor:
                                                                SystemMouseCursors
                                                                    .click,
                                                            child: _Tag(
                                                              '#${tag.name}',
                                                              color,
                                                              isSelected: isSelected,
                                                            ),
                                                          ),
                                                        );
                                                      }),
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
                                    _AttachmentCard(
                                      onFilesChanged: (files) {
                                        setState(() {
                                          _selectedFiles = files;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    const _KnowledgeGraphPreview(),
                                    const SizedBox(height: 20),
                                    const _DraftActivityTimeline(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Footer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        decoration: const BoxDecoration(
                          color: DashboardColors.surfaceHigh,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _openAssigneePicker(otherTeamMembers),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Row(
                                  children: [
                                    if (_selectedAssignees.isEmpty)
                                      const CircleAvatar(
                                        radius: 16,
                                        backgroundColor:
                                            DashboardColors.surfaceHighest,
                                        child: Icon(
                                          Icons.person_rounded,
                                          size: 16,
                                          color: DashboardColors.outline,
                                        ),
                                      )
                                    else
                                      SizedBox(
                                        height: 32,
                                        width:
                                            (32 +
                                                    (_selectedAssignees.length -
                                                            1) *
                                                        26)
                                                .toDouble(),
                                        child: Stack(
                                          children: List.generate(
                                            _selectedAssignees.length,
                                            (idx) {
                                              final m = _selectedAssignees[idx];
                                              return Positioned(
                                                left: (idx * 26).toDouble(),
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor: m.color
                                                      .withValues(alpha: .2),
                                                  backgroundImage: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                                                      ? NetworkImage(m.avatarUrl!)
                                                      : null,
                                                  child: (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                                                      ? null
                                                      : Text(
                                                          m.avatarText,
                                                          style: TextStyle(
                                                            color: m.color,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w900,
                                                          ),
                                                        ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _selectedAssignees.isEmpty
                                          ? 'Assign to team members'
                                          : '${_selectedAssignees.length} assigned collaborators',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: DashboardColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                             OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DashboardColors.onSurface,
                                side: BorderSide(
                                  color: DashboardColors.outlineVariant.withValues(alpha: .3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: isDeploying ? null : () => _deployTask(isDraft: true),
                              child: _localSavingDraft
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: DashboardColors.onSurface,
                                      ),
                                    )
                                  : const Text('Save Draft'),
                            ),
                            const SizedBox(width: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    isDeploying
                                        ? DashboardColors.primary
                                            .withValues(alpha: .5)
                                        : DashboardColors.primary,
                                    isDeploying
                                        ? DashboardColors.secondary
                                            .withValues(alpha: .5)
                                        : DashboardColors.secondary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: DashboardColors.primary.withValues(
                                      alpha: isDeploying ? .10 : .30,
                                    ),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: DashboardColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 18,
                                  ),
                                ),
                                onPressed: isDeploying ? null : () => _deployTask(isDraft: false),
                                icon: _localDeploying
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: DashboardColors.onPrimary,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.rocket_launch_rounded,
                                        size: 16,
                                      ),
                                label: Text(
                                    _localDeploying ? 'Deploying...' : 'Deploy Task'),
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
        const Positioned(
          right: 42,
          bottom: 118,
          child: _CommandPaletteButton(),
        ),
        // AI Suggestion Dock (Dynamic trượt từ đáy màn hình)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          top: _showSuggestionDock ? 60 : -100, // Di chuyển lên phía trên để không đè nút bên dưới
          left: 12,
          right: 30,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DashboardColors.primary.withValues(alpha: .30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DashboardColors.primary.withValues(alpha: .20),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: DashboardColors.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _suggestionText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DashboardColors.onSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: _applyAiSuggestion,
                        style: TextButton.styleFrom(
                          foregroundColor: DashboardColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showSuggestionDock = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: DashboardColors.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Dismiss', style: TextStyle(fontSize: 12)),
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
        border: Border(
          bottom: BorderSide(
            color: DashboardColors.outlineVariant.withValues(alpha: .10),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.add_task_rounded,
            color: DashboardColors.primary,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Task',
                  style: GoogleFonts.interTight(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: DashboardColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deep Work Orchestration',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: DashboardColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: DashboardColors.primary.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: DashboardColors.primary.withValues(alpha: .30),
              ),
              boxShadow: [
                BoxShadow(
                  color: DashboardColors.primary.withValues(alpha: .15),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: .75, end: 1),
                  duration: const Duration(milliseconds: 900),
                  builder:
                      (_, value, child) => Transform.scale(
                        scale: value,
                        child: Opacity(opacity: value, child: child),
                      ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: DashboardColors.primary,
                    size: 16,
                  ),
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
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: DashboardColors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _AssignedProjectDropdown extends StatefulWidget {
  const _AssignedProjectDropdown({
    required this.selectedProject,
    required this.onSelected,
  });

  final String selectedProject;
  final ValueChanged<String> onSelected;

  @override
  State<_AssignedProjectDropdown> createState() =>
      _AssignedProjectDropdownState();
}

class _AssignedProjectDropdownState extends State<_AssignedProjectDropdown> {
  final MenuController _controller = MenuController();
  bool _isOpen = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = _projectByName(widget.selectedProject);

    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          controller: _controller,
          alignmentOffset: const Offset(0, 8),
          style: MenuStyle(
            padding: WidgetStateProperty.all(EdgeInsets.zero),
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
            elevation: WidgetStateProperty.all(0),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
          menuChildren: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .96, end: 1),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              builder:
                  (context, scale, child) => Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: child,
                    ),
                  ),
              child: SizedBox(
                width: constraints.maxWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DashboardColors.surface.withValues(alpha: .78),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .28),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                          BoxShadow(
                            color: DashboardColors.primary.withValues(
                              alpha: .08,
                            ),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final project in mockProjects)
                            _AssignedProjectMenuItem(
                              project: project,
                              selected:
                                  project['name'] == widget.selectedProject,
                              onTap: () {
                                widget.onSelected(project['name'] as String);
                                _controller.close();
                                setState(() => _isOpen = false);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          builder: (context, controller, child) {
            return FocusableActionDetector(
              mouseCursor: SystemMouseCursors.click,
              onShowFocusHighlight: (_) => setState(() {}),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_controller.isOpen) {
                      _controller.close();
                      setState(() => _isOpen = false);
                    } else {
                      _controller.open();
                      setState(() => _isOpen = true);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color:
                          _isHovered || _isOpen
                              ? Colors.white.withValues(alpha: .065)
                              : Colors.white.withValues(alpha: .04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            _isOpen
                                ? DashboardColors.primary.withValues(alpha: .34)
                                : Colors.white.withValues(alpha: .10),
                      ),
                      boxShadow:
                          _isOpen
                              ? [
                                BoxShadow(
                                  color: DashboardColors.primary.withValues(
                                    alpha: .12,
                                  ),
                                  blurRadius: 24,
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      children: [
                        _ProjectDot(
                          color: selected['color'] as Color,
                          strong: true,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.selectedProject,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: DashboardColors.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _isOpen ? .5 : 0,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: DashboardColors.outline,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AssignedProjectMenuItem extends StatefulWidget {
  const _AssignedProjectMenuItem({
    required this.project,
    required this.selected,
    required this.onTap,
  });

  final Map<String, Object> project;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_AssignedProjectMenuItem> createState() =>
      _AssignedProjectMenuItemState();
}

class _AssignedProjectMenuItemState extends State<_AssignedProjectMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.project['color'] as Color;
    final name = widget.project['name'] as String;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color:
                  widget.selected
                      ? color.withValues(alpha: .16)
                      : _hovered
                      ? Colors.white.withValues(alpha: .055)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  widget.selected
                      ? Border.all(color: color.withValues(alpha: .28))
                      : null,
              boxShadow:
                  widget.selected
                      ? [
                        BoxShadow(
                          color: color.withValues(alpha: .14),
                          blurRadius: 18,
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                _ProjectDot(color: color, strong: widget.selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: DashboardColors.onSurface,
                          fontWeight:
                              widget.selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                        ),
                      ),
                      if (widget.selected)
                        Text(
                          'Active project',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: widget.selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.check_rounded, color: color, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectDot extends StatelessWidget {
  const _ProjectDot({required this.color, this.strong = false});

  final Color color;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: strong ? 12 : 10,
      height: strong ? 12 : 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: strong ? .42 : .18),
            blurRadius: strong ? 12 : 8,
          ),
        ],
      ),
    );
  }
}

Map<String, Object> _projectByName(String name) {
  return mockProjects.firstWhere(
    (project) => project['name'] == name,
    orElse: () => mockProjects.first,
  );
}

Color _parseTagColor(String? hex) {
  if (hex == null) return DashboardColors.primary;
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return DashboardColors.primary;
  }
}

class _CategoryDropdown extends StatefulWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryModel> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  State<_CategoryDropdown> createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<_CategoryDropdown> {
  bool _isOpen = false;
  bool _isHovered = false;
  final MenuController _controller = MenuController();

  String get _selectedName {
    if (widget.selectedId == null) return 'No category';
    return widget.categories
            .firstWhere(
              (c) => c.id == widget.selectedId,
              orElse: () => widget.categories.first,
            )
            .name;
  }

  Color get _selectedColor {
    if (widget.selectedId == null) return DashboardColors.outline;
    final cat = widget.categories.firstWhere(
      (c) => c.id == widget.selectedId,
      orElse: () => widget.categories.first,
    );
    return _parseTagColor(cat.color);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MenuAnchor(
          controller: _controller,
          alignmentOffset: const Offset(0, 8),
          style: MenuStyle(
            padding: WidgetStateProperty.all(EdgeInsets.zero),
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
            shadowColor: WidgetStateProperty.all(Colors.transparent),
            surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
            elevation: WidgetStateProperty.all(0),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
          ),
          menuChildren: [
            SizedBox(
              width: constraints.maxWidth,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DashboardColors.surface.withValues(alpha: .78),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .28),
                          blurRadius: 34,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CategoryMenuItem(
                          name: 'No category',
                          color: DashboardColors.outline,
                          selected: widget.selectedId == null,
                          onTap: () {
                            widget.onSelected(null);
                            _controller.close();
                            setState(() => _isOpen = false);
                          },
                        ),
                        ...widget.categories.map((cat) {
                          return _CategoryMenuItem(
                            name: cat.name,
                            color: _parseTagColor(cat.color),
                            selected: cat.id == widget.selectedId,
                            onTap: () {
                              widget.onSelected(cat.id);
                              _controller.close();
                              setState(() => _isOpen = false);
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          builder: (context, controller, child) {
            return MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_controller.isOpen) {
                    _controller.close();
                    setState(() => _isOpen = false);
                  } else {
                    _controller.open();
                    setState(() => _isOpen = true);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isHovered || _isOpen
                        ? Colors.white.withValues(alpha: .065)
                        : Colors.white.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isOpen
                          ? DashboardColors.primary.withValues(alpha: .34)
                          : Colors.white.withValues(alpha: .10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: DashboardColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isOpen ? .5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: DashboardColors.outline,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoryMenuItem extends StatefulWidget {
  const _CategoryMenuItem({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryMenuItem> createState() => _CategoryMenuItemState();
}

class _CategoryMenuItemState extends State<_CategoryMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.color.withValues(alpha: .16)
                  : _hovered
                      ? Colors.white.withValues(alpha: .055)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: widget.selected
                  ? Border.all(color: widget.color.withValues(alpha: .28))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: DashboardColors.onSurface,
                      fontWeight: widget.selected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: widget.selected ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.check_rounded,
                      color: widget.color, size: 18),
                ),
              ],
            ),
          ),
        ),
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
              const Icon(
                Icons.trending_up_rounded,
                color: DashboardColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Dynamic Focus Insights',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your focus heatmap in balance by deploying high complexity tasks during peak energy hours.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.45,
              color: DashboardColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentCard extends StatefulWidget {
  const _AttachmentCard({required this.onFilesChanged});
  final ValueChanged<List<PlatformFileInfo>> onFilesChanged;

  @override
  State<_AttachmentCard> createState() => _AttachmentCardState();
}

class _AttachmentCardState extends State<_AttachmentCard> {
  final List<PlatformFileInfo> _files = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx', 'txt'],
      withData: true,
    );
    if (result == null) return;
    setState(() {
      for (final f in result.files) {
        if (!_files.any((e) => e.name == f.name)) {
          _files.add(PlatformFileInfo(
            name: f.name,
            sizeBytes: f.size,
            extension: f.extension ?? '',
            bytes: f.bytes,
            filePath: f.path,
          ));
        }
      }
    });
    widget.onFilesChanged(_files);
  }

  void _removeFile(int index) {
    setState(() => _files.removeAt(index));
    widget.onFilesChanged(_files);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Label('ATTACHMENTS'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickFiles,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: DashboardColors.primary.withValues(alpha: .22),
                  width: 2,
                ),
                color: DashboardColors.primary.withValues(alpha: .03),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DashboardColors.primary.withValues(alpha: .10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: DashboardColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Upload files',
                          style: GoogleFonts.inter(
                            color: DashboardColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: ' or click to browse',
                          style: GoogleFonts.inter(
                            color: DashboardColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PDF, PNG, JPG, DOC, TXT up to 10MB',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: DashboardColors.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_files.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._files.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GlassBox(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _extColor(f.extension)
                            .withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          f.extension.toUpperCase(),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: _extColor(f.extension),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: DashboardColors.onSurface,
                            ),
                          ),
                          Text(
                            _formatSize(f.sizeBytes),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: DashboardColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16),
                      color: DashboardColors.outline
                          .withValues(alpha: .6),
                      onPressed: () => _removeFile(i),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Color _extColor(String ext) => switch (ext.toLowerCase()) {
        'pdf' => DashboardColors.error,
        'png' || 'jpg' || 'jpeg' => DashboardColors.secondary,
        'doc' || 'docx' => const Color(0xFF2B7CD3),
        'txt' => DashboardColors.tertiary,
        _ => DashboardColors.outline,
      };

  String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}



class _FormatButton extends StatefulWidget {
  const _FormatButton({
    required this.icon,
    required this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  State<_FormatButton> createState() => _FormatButtonState();
}

class _FormatButtonState extends State<_FormatButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? DashboardColors.primary.withValues(alpha: .22)
                : _hovered
                    ? DashboardColors.primary.withValues(alpha: .12)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: widget.isSelected
                ? Border.all(color: DashboardColors.primary.withValues(alpha: .3))
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: (widget.isSelected || _hovered)
                ? DashboardColors.primary
                : DashboardColors.onSurfaceVariant,
          ),
        ),
      ),
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
              color:
                  borderColor ??
                  DashboardColors.onSurface.withValues(
                    alpha: dashed ? .14 : .08,
                  ),
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
  const _Tag(this.text, this.color, {this.isSelected = false});

  final String text;
  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // Tự động điều chỉnh màu chữ dựa trên độ sáng (luminance) của nền tag khi được chọn
    final textColor = isSelected
        ? (color.computeLuminance() > 0.5 ? const Color(0xFF121214) : Colors.white)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? color : color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isSelected ? color : color.withValues(alpha: .3),
          width: 1.5,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
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

class _CreationAiInsightsCard extends StatelessWidget {
  const _CreationAiInsightsCard();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      tint: DashboardColors.primary.withValues(alpha: .05),
      borderColor: DashboardColors.primary.withValues(alpha: .18),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: DashboardColors.tertiary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Creation Intelligence',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _InsightLine('Readiness score: 76%'),
          _InsightLine('Deadline and estimate are aligned'),
          _InsightLine('Suggested focus window: 2PM - 5PM'),
          _InsightLine('One collaborator recommended'),
        ],
      ),
    );
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: DashboardColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPresenceRow extends StatelessWidget {
  const _TeamPresenceRow({required this.members, required this.fallbackMembers});
  final List<TeamMember> members;
  final List<TeamMember> fallbackMembers;

  @override
  Widget build(BuildContext context) {
    final visible =
        members.isEmpty
            ? fallbackMembers.take(3).toList()
            : members.take(3).toList();
    final activeCount = fallbackMembers.isEmpty ? visible.length : fallbackMembers.length;
    final firstActiveName = fallbackMembers.isNotEmpty ? fallbackMembers.first.name : 'Someone';
    return _GlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 34,
            child: Stack(
              children: [
                for (var i = 0; i < visible.length; i++)
                  Positioned(
                    left: i * 22,
                    child: _PresenceAvatar(member: visible[i]),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$activeCount collaborators active • $firstActiveName is viewing this draft',
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const _PulseDot(),
        ],
      ),
    );
  }
}

class _PresenceAvatar extends StatelessWidget {
  const _PresenceAvatar({required this.member});
  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: DashboardColors.background,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: member.color.withValues(alpha: .18),
            backgroundImage: (member.avatarUrl != null && member.avatarUrl!.isNotEmpty)
                ? NetworkImage(member.avatarUrl!)
                : null,
            child: (member.avatarUrl != null && member.avatarUrl!.isNotEmpty)
                ? null
                : Text(
                    member.avatarText,
                    style: TextStyle(
                      color: member.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
        if (member.isOnline)
          const Positioned(right: -1, bottom: -1, child: _OnlineDot()),
      ],
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF7CFFB2),
      border: Border.all(color: DashboardColors.background, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF7CFFB2).withValues(alpha: .35),
          blurRadius: 8,
        ),
      ],
    ),
  );
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: .4, end: 1),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder:
        (context, value, _) => Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: DashboardColors.primary.withValues(alpha: value),
            boxShadow: [
              BoxShadow(
                color: DashboardColors.primary.withValues(alpha: .35 * value),
                blurRadius: 14,
              ),
            ],
          ),
        ),
  );
}

class _AiDraftNotesCard extends StatelessWidget {
  const _AiDraftNotesCard();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      tint: DashboardColors.secondary.withValues(alpha: .04),
      borderColor: DashboardColors.secondary.withValues(alpha: .14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(
                Icons.notes_rounded,
                color: DashboardColors.secondary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'AI Draft Notes',
                style: TextStyle(
                  color: DashboardColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _InsightLine('Clarify success criteria before deployment'),
          _InsightLine('Attach benchmark or reference document'),
          _InsightLine('Add one review checkpoint before final handoff'),
        ],
      ),
    );
  }
}

class _SmartCreationTabs extends StatelessWidget {
  const _SmartCreationTabs();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: _GlassBox(
        padding: const EdgeInsets.all(10),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              isScrollable: true,
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.all(Radius.circular(999)),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(999)),
                color: Color(0x2E8083FF),
                border: Border.fromBorderSide(
                  BorderSide(color: DashboardColors.primary),
                ),
              ),
              labelColor: DashboardColors.primary,
              unselectedLabelColor: DashboardColors.onSurfaceVariant,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Notes'),
                Tab(text: 'Activity'),
                Tab(text: 'Files'),
                Tab(text: 'AI'),
              ],
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 76,
              child: TabBarView(
                children: [
                  _TabCopy(
                    'Draft context and orchestration signals are ready.',
                  ),
                  _TabCopy(
                    'AI notes will update as title and description change.',
                  ),
                  _TabCopy('Creation activity appears here before deployment.'),
                  _TabCopy('Attach docs to strengthen AI context.'),
                  _TabCopy('AI can generate milestones, labels, and owners.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabCopy extends StatelessWidget {
  const _TabCopy(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: DashboardColors.onSurfaceVariant,
        height: 1.4,
      ),
    ),
  );
}

class _SmartPriorityHeatmap extends StatelessWidget {
  const _SmartPriorityHeatmap();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Priority Load Heatmap',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _HeatRow(label: 'High', value: .72, color: DashboardColors.error),
          _HeatRow(
            label: 'Medium',
            value: .54,
            color: DashboardColors.secondary,
          ),
          _HeatRow(label: 'Low', value: .24, color: DashboardColors.tertiary),
        ],
      ),
    );
  }
}

class _HeatRow extends StatelessWidget {
  const _HeatRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            child: Text(
              label,
              style: const TextStyle(
                color: DashboardColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: DashboardColors.surfaceHighest,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusForecastCard extends StatelessWidget {
  const _FocusForecastCard({required this.hours});
  final double hours;

  @override
  Widget build(BuildContext context) {
    final progress = (hours / 8).clamp(.15, 1.0);
    return _GlassBox(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      tint: DashboardColors.tertiary.withValues(alpha: .04),
      borderColor: DashboardColors.tertiary.withValues(alpha: .14),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DashboardColors.tertiary.withValues(alpha: .12),
                  ),
                ),
              ),
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(DashboardColors.tertiary),
                  backgroundColor: Colors.transparent,
                ),
              ),
              const Icon(
                Icons.radar_rounded,
                color: DashboardColors.tertiary,
                size: 16,
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: DashboardColors.tertiary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'FOCUS FORECAST',
                      style: GoogleFonts.inter(
                        color: DashboardColors.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${hours.round()}h session planned • productivity score 88',
                  style: const TextStyle(
                    color: DashboardColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeGraphPreview extends StatelessWidget {
  const _KnowledgeGraphPreview();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        height: 112,
        child: Stack(
          children: const [
            _GraphLine(left: 42, top: 32, width: 120),
            _GraphLine(left: 156, top: 62, width: 102),
            _GraphNode(
              left: 12,
              top: 38,
              label: 'Project',
              color: DashboardColors.primary,
            ),
            _GraphNode(
              left: 130,
              top: 16,
              label: 'Tags',
              color: DashboardColors.secondary,
            ),
            _GraphNode(
              left: 230,
              top: 68,
              label: 'Team',
              color: DashboardColors.tertiary,
            ),
            Positioned(
              left: 8,
              bottom: 0,
              child: Text(
                'AI maps relationships before deployment.',
                style: TextStyle(
                  color: DashboardColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphNode extends StatelessWidget {
  const _GraphNode({
    required this.left,
    required this.top,
    required this.label,
    required this.color,
  });
  final double left;
  final double top;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .22)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: .16), blurRadius: 16),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _GraphLine extends StatelessWidget {
  const _GraphLine({
    required this.left,
    required this.top,
    required this.width,
  });
  final double left;
  final double top;
  final double width;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: Container(
      width: width,
      height: 1.2,
      color: DashboardColors.primary.withValues(alpha: .18),
    ),
  );
}

class _DraftActivityTimeline extends StatelessWidget {
  const _DraftActivityTimeline();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Draft Activity',
            style: TextStyle(
              color: DashboardColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12),
          _ActivityLine('Title field initialized'),
          _ActivityLine('AI generated draft notes'),
          _ActivityLine('Alex assigned as owner'),
        ],
      ),
    );
  }
}

class _ActivityLine extends StatelessWidget {
  const _ActivityLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        const _PulseDot(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: DashboardColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CommandPaletteButton extends StatelessWidget {
  const _CommandPaletteButton();

  @override
  Widget build(BuildContext context) {
    return _GlassBox(
      padding: EdgeInsets.zero,
      borderColor: DashboardColors.primary.withValues(alpha: .18),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Center(
          child: Text(
            '⌘K',
            style: TextStyle(
              color: DashboardColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: DashboardColors.primary.withValues(alpha: .45),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
            child: _Glow(
              size: 420,
              color: DashboardColors.primary.withValues(alpha: .07),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: _Glow(
              size: 340,
              color: DashboardColors.secondary.withValues(alpha: .08),
            ),
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
          Positioned.fill(
            child: ColoredBox(
              color: DashboardColors.surfaceLowest.withValues(alpha: .40),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        'Active Workspace',
        style: GoogleFonts.interTight(
          fontSize: 48,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      Container(
        width: 128,
        height: 40,
        decoration: BoxDecoration(
          color: DashboardColors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      const SizedBox(width: 16),
      Container(
        width: 128,
        height: 40,
        decoration: BoxDecoration(
          color: DashboardColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
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
