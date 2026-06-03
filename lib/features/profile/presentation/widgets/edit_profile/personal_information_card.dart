import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class PersonalInformationCard extends StatefulWidget {
  const PersonalInformationCard({
    required this.fullNameController,
    required this.usernameController,
    required this.bioController,
    required this.email,
    required this.createdAtLabel,
    required this.avatarUrlLabel,
    required this.skills,
    required this.onSkillsChanged,
    super.key,
  });

  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController bioController;
  final String email;
  final String createdAtLabel;
  final String avatarUrlLabel;
  final List<String> skills;
  final ValueChanged<List<String>> onSkillsChanged;

  @override
  State<PersonalInformationCard> createState() => _PersonalInformationCardState();
}

class _PersonalInformationCardState extends State<PersonalInformationCard> {
  String _selectedOccupation = 'Focus Architect';
  String _selectedTimezone = 'UTC+9 (Tokyo Standard)';
  final _locationController = TextEditingController(text: 'NEO-TOKYO NODE');

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _addSkillDialog() {
    final skillController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EditProfileColors.cardBg,
        title: const Text('Add Core Skill', style: TextStyle(color: EditProfileColors.textPrimary)),
        content: TextField(
          controller: skillController,
          style: const TextStyle(color: EditProfileColors.textPrimary),
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter skill name (e.g. Flutter)...',
            hintStyle: TextStyle(color: EditProfileColors.textOutline),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EditProfileColors.borderSides)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EditProfileColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: EditProfileColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newSkill = skillController.text.trim();
              if (newSkill.isNotEmpty && !widget.skills.contains(newSkill)) {
                final updated = List<String>.from(widget.skills)..add(newSkill);
                widget.onSkillsChanged(updated);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: EditProfileColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EditProfileGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: EditProfileColors.primary),
              SizedBox(width: 12),
              Text(
                'Personal Information',
                style: TextStyle(
                  color: EditProfileColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bio Area
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Professional Bio',
                style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListenableBuilder(
                listenable: widget.bioController,
                builder: (context, _) {
                  final length = widget.bioController.text.length;
                  return Stack(
                    children: [
                      TextField(
                        controller: widget.bioController,
                        maxLines: 4,
                        maxLength: 500,
                        style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tell the network about your workflow...',
                          hintStyle: const TextStyle(color: EditProfileColors.textOutline),
                          counterText: '',
                          fillColor: Colors.white.withValues(alpha: 0.03),
                          filled: true,
                          contentPadding: const EdgeInsets.all(16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: EditProfileColors.borderSides),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: EditProfileColors.primary),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Text(
                          '$length / 500',
                          style: TextStyle(
                            color: EditProfileColors.textOutline.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Form Field Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;

              final children = [
                _buildField(
                  label: 'Legal Full Name',
                  child: TextField(
                    controller: widget.fullNameController,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                  ),
                ),
                _buildField(
                  label: 'Public Username',
                  child: TextField(
                    controller: widget.usernameController,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                  ),
                ),
                _buildField(
                  label: 'Primary Email (Readonly)',
                  child: TextField(
                    controller: TextEditingController(text: widget.email),
                    readOnly: true,
                    style: TextStyle(color: EditProfileColors.textPrimary.withValues(alpha: 0.5), fontSize: 14),
                    decoration: _inputDecoration(isReadonly: true),
                  ),
                ),
                _buildField(
                  label: 'Occupation',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedOccupation,
                    dropdownColor: EditProfileColors.cardBg,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                    items: ['Focus Architect', 'Full Stack Developer', 'AI Research Engineer']
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedOccupation = val);
                      }
                    },
                  ),
                ),
                _buildField(
                  label: 'Location Node',
                  child: TextField(
                    controller: _locationController,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                  ),
                ),
                _buildField(
                  label: 'Preferred Timezone',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTimezone,
                    dropdownColor: EditProfileColors.cardBg,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                    items: ['UTC+9 (Tokyo Standard)', 'UTC-8 (Pacific Standard)', 'UTC+1 (Central European)']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTimezone = val);
                      }
                    },
                  ),
                ),
                _buildField(
                  label: 'Avatar URL (Readonly)',
                  child: TextField(
                    controller: TextEditingController(text: widget.avatarUrlLabel),
                    readOnly: true,
                    style: TextStyle(color: EditProfileColors.textPrimary.withValues(alpha: 0.5), fontSize: 14),
                    decoration: _inputDecoration(isReadonly: true),
                  ),
                ),
                _buildField(
                  label: 'Account Created (Readonly)',
                  child: TextField(
                    controller: TextEditingController(text: widget.createdAtLabel),
                    readOnly: true,
                    style: TextStyle(color: EditProfileColors.textPrimary.withValues(alpha: 0.5), fontSize: 14),
                    decoration: _inputDecoration(isReadonly: true),
                  ),
                ),
              ];

              if (isWide) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.8,
                  children: children,
                );
              } else {
                return Column(
                  children: children
                      .map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: c,
                          ))
                      .toList(),
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // Skills Tag Editor
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Core Tech Stack & Skills',
                style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: EditProfileColors.borderSides),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...widget.skills.map((skill) {
                      return Chip(
                        label: Text(
                          skill,
                          style: const TextStyle(color: EditProfileColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: EditProfileColors.primary.withValues(alpha: 0.1),
                        side: BorderSide(color: EditProfileColors.primary.withValues(alpha: 0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        deleteIcon: const Icon(Icons.close, size: 12, color: EditProfileColors.primary),
                        onDeleted: () {
                          final updated = List<String>.from(widget.skills)..remove(skill);
                          widget.onSkillsChanged(updated);
                        },
                      );
                    }),
                    GestureDetector(
                      onTap: _addSkillDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: EditProfileColors.borderSides),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: EditProfileColors.textSecondary, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Add Skill',
                              style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 12),
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
        ],
      ),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: EditProfileColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }

  InputDecoration _inputDecoration({bool isReadonly = false}) {
    return InputDecoration(
      fillColor: isReadonly ? Colors.white.withValues(alpha: 0.01) : Colors.white.withValues(alpha: 0.03),
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EditProfileColors.borderSides),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isReadonly ? EditProfileColors.borderSides : EditProfileColors.primary),
      ),
    );
  }
}
