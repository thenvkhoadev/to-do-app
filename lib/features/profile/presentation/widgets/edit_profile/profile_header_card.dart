import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_shared.dart';
import '../../providers/profile_provider.dart';

class ProfileHeaderCard extends ConsumerStatefulWidget {
  const ProfileHeaderCard({
    required this.email,
    required this.tier,
    required this.role,
    required this.fullNameController,
    required this.usernameController,
    required this.avatarUrlController,
    required this.onDiscard,
    required this.onSave,
    this.isSaving = false,
    super.key,
  });

  final String email;
  final String tier;
  final String role;
  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController avatarUrlController;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  ConsumerState<ProfileHeaderCard> createState() => _ProfileHeaderCardState();
}

class _ProfileHeaderCardState extends ConsumerState<ProfileHeaderCard> {
  void _removeAvatar() {
    widget.avatarUrlController.clear();
  }

  void _triggerAvatarChange(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => _ProfilePhotoDialog(
        username: widget.usernameController.text,
        avatarUrlController: widget.avatarUrlController,
        onRemove: _removeAvatar,
        onUpload: (bytes, fileName) async {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId == null) throw Exception('User not logged in');

          final extension = fileName.split('.').last;

          final imageUrl = await ref.read(profileRemoteDataSourceProvider).uploadAvatar(
            userId,
            bytes,
            fileName: 'avatar_$userId${DateTime.now().millisecondsSinceEpoch}.$extension',
          );

          if (imageUrl != null) {
            widget.avatarUrlController.text = imageUrl;
          } else {
            throw Exception('Upload failed');
          }
        },
        onSaveUrl: (url) {
          widget.avatarUrlController.text = url;
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.fullNameController, widget.usernameController, widget.avatarUrlController]),
      builder: (context, _) {
        final currentName = widget.fullNameController.text.isNotEmpty ? widget.fullNameController.text : 'User';
        final currentUsername = widget.usernameController.text.isNotEmpty ? widget.usernameController.text : 'username';
        final currentAvatar = widget.avatarUrlController.text.trim();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            final avatarWidget = Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: EditProfileColors.primary.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _triggerAvatarChange(context),
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [EditProfileColors.primary, EditProfileColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Hero(
                        tag: 'profile_avatar_hero',
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: EditProfileColors.cardBg,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Material(
                            type: MaterialType.transparency,
                            child: currentAvatar.isNotEmpty
                                ? Image.network(
                                    currentAvatar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(currentUsername),
                                  )
                                : _buildPlaceholderAvatar(currentUsername),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _triggerAvatarChange(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EditProfileColors.primary,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            final infoWidget = Column(
              crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      currentName,
                      style: const TextStyle(
                        color: EditProfileColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EditProfileColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: EditProfileColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        widget.tier.toUpperCase(),
                        style: const TextStyle(
                          color: EditProfileColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: EditProfileColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: EditProfileColors.secondary.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: const TextStyle(
                          color: EditProfileColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '@$currentUsername • ${widget.email}',
                  textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                  style: const TextStyle(
                    color: EditProfileColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: EditProfileColors.success, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(color: EditProfileColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Text(
                        'Level 42',
                        style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            );

            final actionsWidget = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: widget.onDiscard,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EditProfileColors.textPrimary,
                        side: const BorderSide(color: EditProfileColors.borderSides),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 12),
                    EditProfileGradientButton(
                      label: 'Save Changes',
                      isLoading: widget.isSaving,
                      onTap: widget.onSave,
                    ),
                  ],
                ),
              ],
            );

            if (isDesktop) {
              return EditProfileGlassCard(
                child: Row(
                  children: [
                    avatarWidget,
                    const SizedBox(width: 32),
                    Expanded(child: infoWidget),
                    const SizedBox(width: 24),
                    actionsWidget,
                  ],
                ),
              );
            } else {
              return EditProfileGlassCard(
                child: Column(
                  children: [
                    avatarWidget,
                    const SizedBox(height: 24),
                    infoWidget,
                    const SizedBox(height: 24),
                    actionsWidget,
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildPlaceholderAvatar(String username) {
    final initial = username.isNotEmpty ? username.trim().characters.first.toUpperCase() : '?';
    final bgColor = _getRandomColor(username);

    return ColoredBox(
      color: bgColor,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Color _getRandomColor(String name) {
  if (name.isEmpty) return const Color(0xFF8083FF);
  final colors = [
    const Color(0xFF8083FF),
    const Color(0xFF00C896),
    const Color(0xFFFF6B6B),
    const Color(0xFFFCA311),
    const Color(0xFF9D4EDD),
    const Color(0xFF48CAE4),
  ];
  final hash = name.codeUnits.fold(0, (prev, curr) => prev + curr);
  return colors[hash % colors.length];
}

class _ProfilePhotoDialog extends StatefulWidget {
  const _ProfilePhotoDialog({
    required this.username,
    required this.avatarUrlController,
    required this.onRemove,
    required this.onUpload,
    required this.onSaveUrl,
  });

  final String username;
  final TextEditingController avatarUrlController;
  final VoidCallback onRemove;
  final Future<void> Function(Uint8List bytes, String fileName) onUpload;
  final void Function(String url) onSaveUrl;

  @override
  State<_ProfilePhotoDialog> createState() => _ProfilePhotoDialogState();
}

class _ProfilePhotoDialogState extends State<_ProfilePhotoDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _uploadSuccess = false;
  bool _removeSuccess = false;
  String? _errorMessage;

  // Hover states
  bool _isAvatarHovered = false;
  bool _isUploadHovered = false;
  bool _isRemoveHovered = false;
  bool _isCancelHovered = false;
  bool _isLinkHovered = false;

  // View state: 'main' or 'url'
  String _currentView = 'main';
  final _urlInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlInputController.text = widget.avatarUrlController.text;
  }

  @override
  void dispose() {
    _urlInputController.dispose();
    super.dispose();
  }

  Widget _buildPlaceholderAvatar(String username, double fontSize) {
    final initial = username.isNotEmpty ? username.trim().characters.first.toUpperCase() : '?';
    final bgColor = _getRandomColor(username);

    return ColoredBox(
      color: bgColor,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      XFile? image;
      try {
        image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 512,
          maxHeight: 512,
          imageQuality: 85,
        );
      } on PlatformException catch (pe) {
        debugPrint('image_picker failed, trying file_picker: $pe');
        final result = await FilePicker.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          final bytes = file.bytes;
          final name = file.name;
          if (bytes != null) {
            await _startUploadProgress(bytes, name);
            return;
          } else if (file.path != null) {
            final ioFile = File(file.path!);
            final bytesFromPath = await ioFile.readAsBytes();
            await _startUploadProgress(bytesFromPath, name);
            return;
          }
        }
        return;
      }

      if (image == null) return;
      final bytes = await image.readAsBytes();
      await _startUploadProgress(bytes, image.name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _startUploadProgress(Uint8List bytes, String fileName) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadSuccess = false;
      _errorMessage = null;
    });

    Timer? progressTimer;
    progressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_uploadProgress < 0.85) {
          _uploadProgress += 0.03;
        } else if (_uploadProgress < 0.95) {
          _uploadProgress += 0.005;
        }
      });
    });

    try {
      await widget.onUpload(bytes, fileName);
      progressTimer.cancel();

      if (!mounted) return;
      setState(() {
        _uploadProgress = 1.0;
        _uploadSuccess = true;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      progressTimer.cancel();
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed: $e';
      });
    }
  }

  void _handleRemove() {
    widget.onRemove();
    setState(() {
      _removeSuccess = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _handleSaveUrl() {
    final url = _urlInputController.text.trim();
    widget.onSaveUrl(url);
    setState(() {
      _uploadSuccess = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Widget _buildUploadProgress() {
    return Column(
      key: const ValueKey('progress_indicator'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Uploading...',
              style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: const TextStyle(color: EditProfileColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            color: Colors.white.withValues(alpha: 0.05),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _uploadProgress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessBanner(String msg) {
    return Container(
      key: const ValueKey('success_banner'),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 16),
          const SizedBox(width: 8),
          Text(
            msg,
            style: const TextStyle(
              color: Color(0xFF22C55E),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    final showUploadButton = !_isUploading && !_uploadSuccess && !_removeSuccess;

    return Row(
      children: [
        if (showUploadButton) ...[
          Expanded(
            flex: 2,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isUploadHovered = true),
              onExit: (_) => setState(() => _isUploadHovered = false),
              child: GestureDetector(
                onTap: _pickAndUpload,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C5CFF).withValues(alpha: _isUploadHovered ? 0.35 : 0.2),
                        blurRadius: _isUploadHovered ? 12 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Upload Photo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (widget.avatarUrlController.text.trim().isNotEmpty && showUploadButton) ...[
          Expanded(
            flex: 1,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isRemoveHovered = true),
              onExit: (_) => setState(() => _isRemoveHovered = false),
              child: GestureDetector(
                onTap: _handleRemove,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF788C).withValues(alpha: _isRemoveHovered ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF788C).withValues(alpha: 0.28),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Color(0xFFFFB7C8), size: 18),
                      SizedBox(width: 4),
                      Text(
                        'Remove',
                        style: TextStyle(
                          color: Color(0xFFFFD6E0),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (!_isUploading && !_uploadSuccess && !_removeSuccess)
          Expanded(
            flex: 1,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isCancelHovered = true),
              onExit: (_) => setState(() => _isCancelHovered = false),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _isCancelHovered ? 0.06 : 0.0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainView(bool isDesktop) {
    final avatarSize = isDesktop ? 180.0 : 140.0;
    final currentAvatar = widget.avatarUrlController.text.trim();
    final currentUsername = widget.username;

    return Column(
      key: const ValueKey('main_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Profile Photo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Manage your account avatar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: avatarSize + 12,
                height: avatarSize + 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              MouseRegion(
                onEnter: (_) => setState(() => _isAvatarHovered = true),
                onExit: (_) => setState(() => _isAvatarHovered = false),
                child: GestureDetector(
                  onTap: _isUploading || _uploadSuccess || _removeSuccess ? null : _pickAndUpload,
                  child: Hero(
                    tag: 'profile_avatar_hero',
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E293B),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Material(
                        type: MaterialType.transparency,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            currentAvatar.isNotEmpty
                                ? Image.network(
                                    currentAvatar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(currentUsername, isDesktop ? 64 : 48),
                                  )
                                : _buildPlaceholderAvatar(currentUsername, isDesktop ? 64 : 48),
                            AnimatedOpacity(
                              opacity: _isAvatarHovered ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.55),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
                                    SizedBox(height: 4),
                                    Text(
                                      'Change Photo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_isUploading)
          _buildUploadProgress()
        else if (_uploadSuccess)
          _buildSuccessBanner('✓ Profile photo updated successfully')
        else if (_removeSuccess)
          _buildSuccessBanner('✓ Profile photo removed successfully')
        else
          Column(
            children: [
              const Text(
                'PNG, JPG, WEBP\nMaximum file size: 5MB\nRecommended: 500x500px',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              MouseRegion(
                onEnter: (_) => setState(() => _isLinkHovered = true),
                onExit: (_) => setState(() => _isLinkHovered = false),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentView = 'url';
                    });
                  },
                  child: Text(
                    'Or paste an image URL instead',
                    style: TextStyle(
                      color: _isLinkHovered ? const Color(0xFFB388FF) : EditProfileColors.secondary,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: EditProfileColors.error, fontSize: 13),
          ),
        ],
        const SizedBox(height: 32),
        _buildActionButtons(isDesktop),
      ],
    );
  }

  Widget _buildUrlView() {
    return Column(
      key: const ValueKey('url_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Image URL',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Paste a direct link to your new avatar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _urlInputController,
          style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 14),
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'https://example.com/avatar.png',
            hintStyle: const TextStyle(color: EditProfileColors.textOutline),
            fillColor: Colors.white.withValues(alpha: 0.03),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: EditProfileColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isUploadHovered = true),
                onExit: (_) => setState(() => _isUploadHovered = false),
                child: GestureDetector(
                  onTap: _handleSaveUrl,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C5CFF).withValues(alpha: _isUploadHovered ? 0.35 : 0.2),
                          blurRadius: _isUploadHovered ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Save URL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isCancelHovered = true),
                onExit: (_) => setState(() => _isCancelHovered = false),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentView = 'main';
                    });
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _isCancelHovered ? 0.06 : 0.0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width >= 768;
    final dialogWidth = isDesktop ? 500.0 : mediaQuery.size.width * 0.9;
    final padding = isDesktop ? const EdgeInsets.all(32.0) : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0);

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: dialogWidth,
            padding: padding,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentView == 'main' ? _buildMainView(isDesktop) : _buildUrlView(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


