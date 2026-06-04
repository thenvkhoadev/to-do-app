import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crop_your_image/crop_your_image.dart';
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
  bool _isCameraHovered = false;
  bool _isDialogOpen = false;

  void _removeAvatar() {
    widget.avatarUrlController.clear();
  }

  void _triggerAvatarChange(BuildContext context) async {
    setState(() {
      _isDialogOpen = true;
    });

    await showDialog<void>(
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

    if (mounted) {
      setState(() {
        _isDialogOpen = false;
      });
    }
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

            final avatarSize = isDesktop ? 160.0 : 120.0;
            final cameraSize = isDesktop ? 42.0 : 36.0;

            final avatarWidget = Center(
              child: SizedBox(
                width: avatarSize,
                height: avatarSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CFF).withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Hero(
                        tag: 'profile_avatar_hero',
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: EditProfileColors.cardBg,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GestureDetector(
                            onTap: () => _triggerAvatarChange(context),
                            child: Material(
                              type: MaterialType.transparency,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  currentAvatar.isNotEmpty
                                      ? Image.network(
                                          currentAvatar,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(currentUsername),
                                        )
                                      : _buildPlaceholderAvatar(currentUsername),
                                  AnimatedOpacity(
                                    opacity: _isDialogOpen ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _isCameraHovered = true),
                        onExit: (_) => setState(() => _isCameraHovered = false),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _triggerAvatarChange(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: cameraSize,
                            height: cameraSize,
                            transform: Matrix4.diagonal3Values(_isCameraHovered ? 1.08 : 1.0, _isCameraHovered ? 1.08 : 1.0, 1.0),
                            transformAlignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7C5CFF),
                              border: Border.all(
                                color: const Color(0xFF0B1020),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C5CFF).withValues(
                                    alpha: _isCameraHovered ? 0.65 : 0.45,
                                  ),
                                  blurRadius: _isCameraHovered ? 25 : 20,
                                  spreadRadius: _isCameraHovered ? 1 : 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedRotation(
                                turns: _isDialogOpen ? 0.25 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: const Icon(
                                  Icons.photo_camera,
                                  color: Colors.white,
                                  size: 20,
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

  Future<void> _cropAndProcessImage({
    required String? path,
    required Uint8List originalBytes,
    required String name,
  }) async {
    try {
      final croppedBytes = await showDialog<Uint8List?>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (context) => _CropImageDialog(imageBytes: originalBytes),
      );

      if (croppedBytes == null) {
        // Cancel Crop: close crop, do not change image, do not open confirmation dialog
        return;
      }

      await _handleImageSelection(croppedBytes, name);
    } catch (e) {
      debugPrint('Error cropping image: $e. Falling back to original image.');
      await _handleImageSelection(originalBytes, name);
    }
  }

  Future<void> _pickAndUpload() async {
    try {
      XFile? image;
      try {
        image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
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
            await _cropAndProcessImage(path: file.path, originalBytes: bytes, name: name);
            return;
          } else if (file.path != null) {
            final ioFile = File(file.path!);
            final bytesFromPath = await ioFile.readAsBytes();
            await _cropAndProcessImage(path: file.path, originalBytes: bytesFromPath, name: name);
            return;
          }
        }
        return;
      }

      if (image == null) return;
      final bytes = await image.readAsBytes();
      await _cropAndProcessImage(path: image.path, originalBytes: bytes, name: image.name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
    }
  }

  Future<void> _handleImageSelection(Uint8List bytes, String name) async {
    try {
      final ext = name.split('.').last.toLowerCase();
      if (ext != 'png' && ext != 'jpg' && ext != 'jpeg' && ext != 'webp') {
        setState(() {
          _errorMessage = 'Unsupported format: .$ext. Only PNG, JPG, JPEG, and WEBP are allowed.';
        });
        return;
      }

      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (img) => completer.complete(img));
      final uiImg = await completer.future;
      final width = uiImg.width;
      final height = uiImg.height;

      final format = ext.toUpperCase();
      final sizeString = _formatBytes(bytes.length);

      if (!mounted) return;

      // Close the photo picker dialog first
      Navigator.pop(context);

      // Open the preview confirmation dialog
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (ctx) => AvatarUploadConfirmationDialog(
          newBytes: bytes,
          newFileName: name,
          newFileSize: sizeString,
          newWidth: width,
          newHeight: height,
          newFormat: format,
          currentAvatarUrl: widget.avatarUrlController.text.trim(),
          username: widget.username,
          avatarUrlController: widget.avatarUrlController,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process selected image: $e';
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes Bytes';
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

  Widget _buildEmptyStateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EditProfileColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: EditProfileColors.primary,
              size: 48,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Profile Photo Yet',
            style: TextStyle(
              color: EditProfileColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add a photo to personalize your account.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EditProfileColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          MouseRegion(
            onEnter: (_) => setState(() => _isUploadHovered = true),
            onExit: (_) => setState(() => _isUploadHovered = false),
            child: GestureDetector(
              onTap: _pickAndUpload,
              child: Container(
                height: 48,
                width: 160,
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
                  'Upload Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    final showUploadButton = !_uploadSuccess && !_removeSuccess;
    final hasAvatar = widget.avatarUrlController.text.trim().isNotEmpty;

    return Row(
      children: [
        if (showUploadButton && hasAvatar) ...[
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
        if (hasAvatar && showUploadButton) ...[
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
        if (!_uploadSuccess && !_removeSuccess)
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
        if (currentAvatar.isEmpty)
          _buildEmptyStateCard()
        else
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
                    onTap: _uploadSuccess || _removeSuccess ? null : _pickAndUpload,
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
                              Image.network(
                                currentAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(currentUsername, isDesktop ? 64 : 48),
                              ),
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
        if (_uploadSuccess)
          _buildSuccessBanner('✓ Profile photo updated successfully')
        else if (_removeSuccess)
          _buildSuccessBanner('✓ Profile photo removed successfully')
        else if (currentAvatar.isNotEmpty)
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

enum AvatarDialogState {
  preview,
  uploading,
  success,
  error,
}

class AvatarUploadConfirmationDialog extends ConsumerStatefulWidget {
  const AvatarUploadConfirmationDialog({
    required this.newBytes,
    required this.newFileName,
    required this.newFileSize,
    required this.newWidth,
    required this.newHeight,
    required this.newFormat,
    required this.currentAvatarUrl,
    required this.username,
    required this.avatarUrlController,
    super.key,
  });

  final Uint8List newBytes;
  final String newFileName;
  final String newFileSize;
  final int newWidth;
  final int newHeight;
  final String newFormat;
  final String currentAvatarUrl;
  final String username;
  final TextEditingController avatarUrlController;

  @override
  ConsumerState<AvatarUploadConfirmationDialog> createState() => _AvatarUploadConfirmationDialogState();
}

class _AvatarUploadConfirmationDialogState extends ConsumerState<AvatarUploadConfirmationDialog> {
  late Uint8List _currentBytes;
  late String _currentFileName;
  late String _currentFileSize;
  late int _currentWidth;
  late int _currentHeight;
  late String _currentFormat;

  AvatarDialogState _currentState = AvatarDialogState.preview;
  double _uploadProgress = 0.0;
  String? _errorMessage;
  Timer? _progressTimer;
  bool _canPop = false;

  bool _isConfirmHovered = false;
  bool _isCancelHovered = false;
  bool _isRetryHovered = false;
  bool _isDoneHovered = false;
  bool _isUploadAnotherHovered = false;

  @override
  void initState() {
    super.initState();
    _currentBytes = widget.newBytes;
    _currentFileName = widget.newFileName;
    _currentFileSize = widget.newFileSize;
    _currentWidth = widget.newWidth;
    _currentHeight = widget.newHeight;
    _currentFormat = widget.newFormat;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startUpload() async {
    setState(() {
      _currentState = AvatarDialogState.uploading;
      _uploadProgress = 0.0;
      _errorMessage = null;
      _canPop = false;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      setState(() {
        if (_uploadProgress < 0.95) {
          _uploadProgress += 0.015;
        }
      });
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final imageUrl = await ref.read(profileRemoteDataSourceProvider).uploadAvatar(
        userId,
        _currentBytes,
        fileName: 'avatar_$userId${DateTime.now().millisecondsSinceEpoch}.${_currentFormat.toLowerCase()}',
      );

      if (imageUrl == null) throw Exception('Failed to upload avatar to storage');

      await ref.read(profileRemoteDataSourceProvider).updateProfileInfo(
        userId,
        avatarUrl: imageUrl,
      );

      widget.avatarUrlController.text = imageUrl;
      ref.invalidate(userProfileProvider);

      _progressTimer?.cancel();
      setState(() {
        _uploadProgress = 1.0;
        _currentState = AvatarDialogState.success;
        _canPop = true;
      });
    } catch (e) {
      _progressTimer?.cancel();
      setState(() {
        _errorMessage = e.toString();
        _currentState = AvatarDialogState.error;
        _canPop = true;
      });
    }
  }

  Future<void> _pickAnotherImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      XFile? image;
      try {
        image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
      } on PlatformException catch (pe) {
        debugPrint('image_picker failed in dialog, trying file_picker: $pe');
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
            await _handleNewSelection(bytes, name);
            return;
          } else if (file.path != null) {
            final ioFile = File(file.path!);
            final bytesFromPath = await ioFile.readAsBytes();
            await _handleNewSelection(bytesFromPath, name);
            return;
          }
        }
        return;
      }

      if (image == null) return;
      final bytes = await image.readAsBytes();
      await _handleNewSelection(bytes, image.name);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select image: $e';
        _currentState = AvatarDialogState.error;
      });
    }
  }

  Future<void> _handleNewSelection(Uint8List bytes, String name) async {
    final ext = name.split('.').last.toLowerCase();
    if (ext != 'png' && ext != 'jpg' && ext != 'jpeg' && ext != 'webp') {
      setState(() {
        _errorMessage = 'Unsupported format: .$ext. Only PNG, JPG, JPEG, and WEBP are allowed.';
        _currentState = AvatarDialogState.error;
      });
      return;
    }

    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => completer.complete(img));
    final uiImg = await completer.future;
    final width = uiImg.width;
    final height = uiImg.height;

    final format = ext.toUpperCase();
    final sizeString = _formatBytes(bytes.length);

    setState(() {
      _currentBytes = bytes;
      _currentFileName = name;
      _currentFileSize = sizeString;
      _currentWidth = width;
      _currentHeight = height;
      _currentFormat = format;
      _currentState = AvatarDialogState.preview;
      _uploadProgress = 0.0;
      _canPop = false;
      _errorMessage = null;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '$bytes Bytes';
    }
  }

  Future<bool> _showDiscardWarning() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: EditProfileColors.secondary,
                      size: 44,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Discard selected photo?',
                      style: TextStyle(
                        color: EditProfileColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your changes will not be saved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: EditProfileColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: EditProfileColors.textSecondary,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Keep Editing'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(true),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Discard',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return result ?? false;
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

  Widget _buildPreviewView(bool isDesktop) {
    final avatarSize = isDesktop ? 100.0 : 80.0;
    return Column(
      key: const ValueKey('preview_view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Confirm Profile Photo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Review your new profile photo before updating.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.currentAvatarUrl.isNotEmpty
                      ? Image.network(
                          widget.currentAvatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(widget.username, isDesktop ? 36 : 28),
                        )
                      : _buildPlaceholderAvatar(widget.username, isDesktop ? 36 : 28),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Current Avatar',
                  style: TextStyle(color: EditProfileColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.arrow_forward_rounded,
              color: EditProfileColors.textSecondary.withValues(alpha: 0.6),
              size: 28,
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: EditProfileColors.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: EditProfileColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(
                    _currentBytes,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'New Avatar',
                  style: TextStyle(color: EditProfileColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            spacing: 8,
            children: [
              _buildInfoRow('File Name', _currentFileName),
              _buildInfoRow('File Size', _currentFileSize),
              _buildInfoRow('Image Resolution', '$_currentWidth x $_currentHeight px'),
              _buildInfoRow('Format', _currentFormat),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your current profile photo will be replaced.',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'This action can be changed later.',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isCancelHovered = true),
                onExit: (_) => setState(() => _isCancelHovered = false),
                child: GestureDetector(
                  onTap: () async {
                    final shouldDiscard = await _showDiscardWarning();
                    if (shouldDiscard && mounted) {
                      setState(() {
                        _canPop = true;
                      });
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _isCancelHovered ? 0.06 : 0.0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
            const SizedBox(width: 12),
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isConfirmHovered = true),
                onExit: (_) => setState(() => _isConfirmHovered = false),
                child: GestureDetector(
                  onTap: _startUpload,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C5CFF).withValues(alpha: _isConfirmHovered ? 0.35 : 0.2),
                          blurRadius: _isConfirmHovered ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Confirm Upload',
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
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: EditProfileColors.textSecondary, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(color: EditProfileColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String label, int stepIndex) {
    String iconStr = '○';
    Color iconColor = EditProfileColors.textOutline.withValues(alpha: 0.5);
    double opacity = 0.5;

    if (stepIndex == 0) {
      if (_uploadProgress >= 0.20) {
        iconStr = '✓';
        iconColor = const Color(0xFF22C55E);
        opacity = 1.0;
      } else {
        iconStr = '⏳';
        iconColor = EditProfileColors.primary;
        opacity = 1.0;
      }
    } else if (stepIndex == 1) {
      if (_uploadProgress >= 0.40) {
        iconStr = '✓';
        iconColor = const Color(0xFF22C55E);
        opacity = 1.0;
      } else if (_uploadProgress >= 0.20) {
        iconStr = '⏳';
        iconColor = EditProfileColors.primary;
        opacity = 1.0;
      }
    } else if (stepIndex == 2) {
      if (_uploadProgress >= 0.80) {
        iconStr = '✓';
        iconColor = const Color(0xFF22C55E);
        opacity = 1.0;
      } else if (_uploadProgress >= 0.40) {
        iconStr = '⏳';
        iconColor = EditProfileColors.primary;
        opacity = 1.0;
      }
    } else if (stepIndex == 3) {
      if (_uploadProgress >= 0.95 || _currentState == AvatarDialogState.success) {
        iconStr = '✓';
        iconColor = const Color(0xFF22C55E);
        opacity = 1.0;
      } else if (_uploadProgress >= 0.80) {
        iconStr = '⏳';
        iconColor = EditProfileColors.primary;
        opacity = 1.0;
      }
    } else if (stepIndex == 4) {
      if (_currentState == AvatarDialogState.success) {
        iconStr = '✓';
        iconColor = const Color(0xFF22C55E);
        opacity = 1.0;
      } else if (_uploadProgress >= 0.95) {
        iconStr = '⏳';
        iconColor = EditProfileColors.primary;
        opacity = 1.0;
      }
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              child: Text(
                iconStr,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: opacity == 1.0 ? EditProfileColors.textPrimary : EditProfileColors.textSecondary,
                fontSize: 14,
                fontWeight: opacity == 1.0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingView() {
    return Column(
      key: const ValueKey('uploading_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: _uploadProgress),
                  duration: const Duration(milliseconds: 100),
                  builder: (context, value, _) {
                    return CustomPaint(
                      size: const Size(120, 120),
                      painter: GradientCircularProgressPainter(
                        progress: value,
                        colors: const [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                        strokeWidth: 8.0,
                      ),
                    );
                  },
                ),
                Text(
                  '${(_uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: EditProfileColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Uploading Profile Photo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Optimizing and syncing your avatar...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChecklistItem('Validating image', 0),
              _buildChecklistItem('Compressing image', 1),
              _buildChecklistItem('Uploading to cloud', 2),
              _buildChecklistItem('Updating profile', 3),
              _buildChecklistItem('Refreshing account', 4),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, val, child) {
              return Transform.scale(
                scale: val,
                child: child,
              );
            },
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '✓',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Profile Photo Updated',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your new avatar has been successfully uploaded and synced across your account.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Column(
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF7C5CFF).withValues(alpha: 0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C5CFF).withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  _currentBytes,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Synced Successfully',
                    style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.currentAvatarUrl.isEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCA311).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFCA311).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '🏆',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identity Verified',
                        style: TextStyle(
                          color: EditProfileColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Added a profile photo to your account.',
                        style: TextStyle(
                          color: EditProfileColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isUploadAnotherHovered = true),
                onExit: (_) => setState(() => _isUploadAnotherHovered = false),
                child: GestureDetector(
                  onTap: _pickAnotherImage,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _isUploadAnotherHovered ? 0.06 : 0.0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Upload Another',
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
            const SizedBox(width: 12),
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isDoneHovered = true),
                onExit: (_) => setState(() => _isDoneHovered = false),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    showPremiumToast(
                      context,
                      icon: '🖼',
                      title: 'Avatar Updated',
                      message: 'Your profile photo has been updated successfully.',
                    );
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C5CFF).withValues(alpha: _isDoneHovered ? 0.35 : 0.2),
                          blurRadius: _isDoneHovered ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Done',
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
          ],
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      key: const ValueKey('error_view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        const Center(
          child: Icon(
            Icons.error,
            color: Color(0xFFEF4444),
            size: 72,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Unable to upload profile photo.\nPlease try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: EditProfileColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EditProfileColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isCancelHovered = true),
                onExit: (_) => setState(() => _isCancelHovered = false),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: _isCancelHovered ? 0.06 : 0.0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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
            const SizedBox(width: 12),
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _isRetryHovered = true),
                onExit: (_) => setState(() => _isRetryHovered = false),
                child: GestureDetector(
                  onTap: _startUpload,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C5CFF), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C5CFF).withValues(alpha: _isRetryHovered ? 0.35 : 0.2),
                          blurRadius: _isRetryHovered ? 12 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Retry',
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

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_currentState == AvatarDialogState.uploading) {
          return;
        }
        final shouldDiscard = await _showDiscardWarning();
        if (shouldDiscard && context.mounted) {
          setState(() {
            _canPop = true;
          });
          Navigator.of(context).pop();
        }
      },
      child: Center(
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
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                            ),
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentView(isDesktop),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(bool isDesktop) {
    switch (_currentState) {
      case AvatarDialogState.preview:
        return _buildPreviewView(isDesktop);
      case AvatarDialogState.uploading:
        return _buildUploadingView();
      case AvatarDialogState.success:
        return _buildSuccessView();
      case AvatarDialogState.error:
        return _buildErrorView();
    }
  }
}

// -----------------------------------------------------------------------------
// Premium Sweep Gradient Circular Progress Painter
// -----------------------------------------------------------------------------
class GradientCircularProgressPainter extends CustomPainter {
  GradientCircularProgressPainter({
    required this.progress,
    required this.colors,
    this.strokeWidth = 8.0,
  });

  final double progress;
  final List<Color> colors;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    // Draw progress arc with sweep gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    paint.shader = SweepGradient(
      colors: colors,
      startAngle: 0.0,
      endAngle: 2 * 3.1415926535,
      transform: const GradientRotation(-1.57079632679), // -pi/2
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -1.57079632679, // -pi/2 (top)
      2 * 3.1415926535 * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.colors != colors || oldDelegate.strokeWidth != strokeWidth;
  }
}

// -----------------------------------------------------------------------------
// Premium Overlay Toast System
// -----------------------------------------------------------------------------
void showPremiumToast(
  BuildContext context, {
  required String icon,
  required String title,
  required String message,
}) {
  final overlayState = Navigator.of(context).overlay;
  if (overlayState == null) return;

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      final isDesktop = mediaQuery.size.width >= 768;

      final toastContent = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: isDesktop ? 360 : mediaQuery.size.width * 0.9,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111827).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: EditProfileColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: const TextStyle(
                            color: EditProfileColors.textSecondary,
                            fontSize: 12,
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
      );

      return _AnimatedToastWidget(
        isDesktop: isDesktop,
        mediaQuery: mediaQuery,
        overlayEntry: overlayEntry,
        child: toastContent,
      );
    },
  );

  overlayState.insert(overlayEntry);
}

class _AnimatedToastWidget extends StatefulWidget {
  const _AnimatedToastWidget({
    required this.isDesktop,
    required this.mediaQuery,
    required this.overlayEntry,
    required this.child,
  });

  final bool isDesktop;
  final MediaQueryData mediaQuery;
  final OverlayEntry overlayEntry;
  final Widget child;

  @override
  State<_AnimatedToastWidget> createState() => _AnimatedToastWidgetState();
}

class _AnimatedToastWidgetState extends State<_AnimatedToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.isDesktop ? const Offset(1.0, 0.0) : const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.overlayEntry.remove();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget animatedToast = SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );

    if (widget.isDesktop) {
      return Positioned(
        top: 24 + widget.mediaQuery.padding.top,
        right: 24,
        child: animatedToast,
      );
    } else {
      return Positioned(
        bottom: 24 + widget.mediaQuery.padding.bottom,
        left: widget.mediaQuery.size.width * 0.05,
        child: animatedToast,
      );
    }
  }
}

class _CropImageDialog extends StatefulWidget {
  const _CropImageDialog({
    required this.imageBytes,
  });

  final Uint8List imageBytes;

  @override
  State<_CropImageDialog> createState() => _CropImageDialogState();
}

class _CropImageDialogState extends State<_CropImageDialog> {
  final _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0B1020),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 500,
          height: 600,
          color: const Color(0xFF0B1020),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Crop Avatar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Cropper
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Crop(
                      image: widget.imageBytes,
                      controller: _cropController,
                      onCropped: (result) {
                        if (!mounted) return;
                        setState(() => _isCropping = false);
                        if (result is CropSuccess) {
                          Navigator.pop(context, result.croppedImage);
                        } else if (result is CropFailure) {
                          debugPrint('Crop error: ${result.cause}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to crop image')),
                          );
                        }
                      },
                      aspectRatio: 1.0,
                      interactive: false,
                      cornerDotBuilder: (size, edgeAlignment) => const DotControl(
                        color: Color(0xFF7C5CFF),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Footer Actions
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isCropping
                          ? null
                          : () {
                              setState(() => _isCropping = true);
                              _cropController.crop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C5CFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isCropping
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
