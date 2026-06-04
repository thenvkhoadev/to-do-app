import 'package:flutter/material.dart';
import 'edit_profile_shared.dart';

class PersonalInformationCard extends StatefulWidget {
  const PersonalInformationCard({
    required this.fullNameController,
    required this.usernameController,
    required this.bioController,
    required this.locationController,
    required this.selectedTimezone,
    required this.onTimezoneChanged,
    required this.selectedOccupation,
    required this.onOccupationChanged,
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
  final TextEditingController locationController;
  final String selectedTimezone;
  final ValueChanged<String> onTimezoneChanged;
  final String selectedOccupation;
  final ValueChanged<String> onOccupationChanged;
  final String email;
  final String createdAtLabel;
  final String avatarUrlLabel;
  final List<String> skills;
  final ValueChanged<List<String>> onSkillsChanged;

  @override
  State<PersonalInformationCard> createState() => _PersonalInformationCardState();
}

class _PersonalInformationCardState extends State<PersonalInformationCard> {
  static const List<String> _timezones = [
    '(UTC-12:00) International Date Line West',
    '(UTC-11:00) Coordinated Universal Time-11',
    '(UTC-10:00) Hawaii',
    '(UTC-09:00) Alaska',
    '(UTC-08:00) Pacific Time (US & Canada)',
    '(UTC-07:00) Mountain Time (US & Canada)',
    '(UTC-06:00) Central Time (US & Canada), Mexico City',
    '(UTC-05:00) Eastern Time (US & Canada), Bogota, Lima',
    '(UTC-04:00) Atlantic Time (Canada), Caracas, La Paz',
    '(UTC-03:30) Newfoundland',
    '(UTC-03:00) Brasilia, Buenos Aires, Georgetown',
    '(UTC-02:00) Mid-Atlantic',
    '(UTC-01:00) Azores, Cape Verde Is.',
    '(UTC±00:00) Dublin, Edinburgh, Lisbon, London',
    '(UTC+01:00) Amsterdam, Berlin, Rome, Vienna, Paris',
    '(UTC+02:00) Athens, Bucharest, Istanbul, Jerusalem',
    '(UTC+03:00) Moscow, St. Petersburg, Baghdad, Kuwait',
    '(UTC+03:30) Tehran',
    '(UTC+04:00) Abu Dhabi, Muscat, Baku, Tbilisi',
    '(UTC+04:30) Kabul',
    '(UTC+05:00) Islamabad, Karachi, Tashkent',
    '(UTC+05:30) Chennai, Kolkata, Mumbai, New Delhi',
    '(UTC+05:45) Kathmandu',
    '(UTC+06:00) Astana, Dhaka, Almaty',
    '(UTC+06:30) Yangon (Rangoon)',
    '(UTC+07:00) Bangkok, Hanoi, Jakarta',
    '(UTC+08:00) Beijing, Hong Kong, Singapore, Taipei',
    '(UTC+08:45) Eucla',
    '(UTC+09:00) Osaka, Sapporo, Tokyo, Seoul',
    '(UTC+09:30) Adelaide, Darwin',
    '(UTC+10:00) Brisbane, Canberra, Melbourne, Sydney',
    '(UTC+10:30) Lord Howe Island',
    '(UTC+11:00) Magadan, Solomon Is., New Caledonia',
    '(UTC+12:00) Auckland, Wellington, Fiji, Kamchatka',
    '(UTC+13:00) Nuku\'alofa, Samoa',
    '(UTC+14:00) Kiritimati Island',
  ];

  static const List<String> _occupations = [
    'Focus Architect',
    'Full Stack Developer',
    'Frontend Developer',
    'Backend Developer',
    'Mobile Developer',
    'UI/UX Designer',
    'Product Designer',
    'Product Manager',
    'Project Manager',
    'Scrum Master',
    'Data Scientist',
    'Data Analyst',
    'Data Engineer',
    'Machine Learning Engineer',
    'AI Research Engineer',
    'DevOps Engineer',
    'Cloud Architect',
    'Security Engineer',
    'QA Engineer',
    'Software Tester',
    'System Administrator',
    'Database Administrator',
    'Network Engineer',
    'Tech Lead',
    'Engineering Manager',
    'CTO / Founder',
    'Freelancer / Contractor',
    'Student / Learner',
    'Other'
  ];

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
                    isExpanded: true,
                    value: _occupations.contains(widget.selectedOccupation) ? widget.selectedOccupation : _occupations.first,
                    dropdownColor: EditProfileColors.cardBg,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                    items: _occupations
                        .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.onOccupationChanged(val);
                      }
                    },
                  ),
                ),
                _buildField(
                  label: 'Location Node',
                  child: TextField(
                    controller: widget.locationController,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                  ),
                ),
                _buildField(
                  label: 'Preferred Timezone',
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _timezones.contains(widget.selectedTimezone) ? widget.selectedTimezone : _timezones.firstWhere((t) => t.contains('Bangkok, Hanoi'), orElse: () => _timezones.first),
                    dropdownColor: EditProfileColors.cardBg,
                    style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
                    decoration: _inputDecoration(),
                    items: _timezones
                        .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        widget.onTimezoneChanged(val);
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
