import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_app/theme/design_tokens.dart';
import 'package:to_do_app/features/profile/data/models/user_profile_model.dart';
import 'package:to_do_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:to_do_app/features/tasks/domain/entities/task.dart';
import 'package:to_do_app/features/tasks/presentation/providers/tasks_provider.dart';
import 'package:to_do_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:to_do_app/features/social/presentation/providers/feed_provider.dart';
import 'package:to_do_app/widgets/dashboard/dashboard_shared.dart';

class PostComposerModal extends ConsumerStatefulWidget {
  const PostComposerModal({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<PostComposerModal> createState() => _PostComposerModalState();
}

class _PostComposerModalState extends ConsumerState<PostComposerModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _contentController = TextEditingController();
  
  // Tab 0: Image Attachment
  XFile? _selectedImage;
  bool _isUploadingImage = false;

  // Tab 1: Task Attachment
  NexusTask? _selectedTask;

  // Tab 2: Achievement Attachment
  String? _selectedAchievement;

  // Tab 3: Survey/Poll Creator
  final List<TextEditingController> _pollOptionControllers = [
    TextEditingController(text: ''),
    TextEditingController(text: ''),
  ];

  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _contentController.dispose();
    for (var controller in _pollOptionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  void _addPollOption() {
    if (_pollOptionControllers.length < 4) {
      setState(() {
        _pollOptionControllers.add(TextEditingController());
      });
    }
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length > 2) {
      setState(() {
        final controller = _pollOptionControllers.removeAt(index);
        controller.dispose();
      });
    }
  }

  Future<void> _submitPost() async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null) return;

    final content = _contentController.text.trim();
    if (content.isEmpty && _selectedImage == null && _selectedTask == null && _selectedAchievement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nội dung bài viết')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      String type = 'text';
      String? mediaUrl;
      String? referenceId;
      Map<String, dynamic>? metaData;

      // Handle Image Upload
      if (_selectedImage != null) {
        type = 'photo';
        // Let's upload photo using storage
        final fileBytes = await _selectedImage!.readAsBytes();
        final name = 'post_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = '${currentUser.id}/$name';
        
        await Supabase.instance.client.storage.from('avatars').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );
        mediaUrl = Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
      }

      // Handle Task attachment
      if (_tabController.index == 1 && _selectedTask != null) {
        type = 'task';
        referenceId = _selectedTask!.id;
        metaData = {
          'taskTitle': _selectedTask!.title,
          'taskStatus': _selectedTask!.status,
          'taskPriority': _selectedTask!.priority,
        };
      }

      // Handle Achievement attachment
      if (_tabController.index == 2 && _selectedAchievement != null) {
        type = 'achievement';
        metaData = {
          'achievementTitle': _selectedAchievement,
          'achievementDesc': 'Hoàn thành các cột mốc trong NEXUS AI',
        };
      }

      // Handle Poll attachment
      if (_tabController.index == 3) {
        final options = _pollOptionControllers
            .map((c) => c.text.trim())
            .where((opt) => opt.isNotEmpty)
            .toList();

        if (options.length >= 2) {
          type = 'poll';
          metaData = {
            'pollOptions': options,
            'votes': <String, String>{}, // userId: option
          };
        }
      }

      final feedService = ref.read(feedServiceProvider);
      await feedService.createPost(
        userId: currentUser.id,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        referenceId: referenceId,
        metaData: metaData,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng bài viết thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng bài: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(userTasksProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: .6),
      body: Center(
        child: Container(
          width: 580,
          constraints: const BoxConstraints(maxHeight: 640),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: DesignTokens.bgCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusCard),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .5),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tạo bài viết',
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
              const Divider(color: DesignTokens.borderSubtle, height: 1),

              // User Info
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    profileAsync.when(
                      data: (profile) => CircleAvatar(
                        radius: 20,
                        backgroundImage: profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty
                            ? NetworkImage(profile.avatarUrl!)
                            : null,
                        backgroundColor: Colors.grey.shade800,
                      ),
                      loading: () => const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                      error: (_, __) => const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileAsync.when(
                          data: (profile) => Text(
                            profile?.fullName ?? profile?.username ?? 'Bạn',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const Text('Loading...', style: TextStyle(color: Colors.white)),
                          error: (_, __) => const Text('Lỗi tải', style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.public, color: Colors.white.withValues(alpha: .5), size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'Công khai',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .5),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Text Input Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _contentController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Bạn đang nghĩ gì? Chia sẻ tiến độ...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: .4)),
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Tab Selector
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF7C5CFF),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(text: 'Ảnh'),
                  Tab(text: 'Task'),
                  Tab(text: 'Thành tích'),
                  Tab(text: 'Khảo sát'),
                ],
              ),

              // Tab Views
              Expanded(
                child: Container(
                  color: Colors.black.withValues(alpha: .2),
                  padding: const EdgeInsets.all(16),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 0: Image Upload
                      _buildImageTab(),
                      // Tab 1: Task Select
                      _buildTaskTab(tasksAsync),
                      // Tab 2: Achievement Select
                      _buildAchievementTab(profileAsync),
                      // Tab 3: Poll/Survey Creator
                      _buildPollTab(),
                    ],
                  ),
                ),
              ),

              // Footer Post Button
              const Divider(color: DesignTokens.borderSubtle, height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: DesignTokens.gradientPrimary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Đăng bài',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTab() {
    return Center(
      child: _selectedImage != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_selectedImage!.path),
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black.withValues(alpha: .8),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 12, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: _pickImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 36, color: Colors.white.withValues(alpha: .5)),
                    const SizedBox(height: 8),
                    const Text('Chọn một bức ảnh', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTaskTab(AsyncValue<List<NexusTask>> tasksAsync) {
    return tasksAsync.when(
      data: (tasks) {
        final incompleteTasks = tasks.where((t) => t.status != 'completed' && t.status != 'done').toList();
        if (incompleteTasks.isEmpty) {
          return const Center(child: Text('Không có công việc nào để chia sẻ', style: TextStyle(color: Colors.white60)));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Đính kèm công việc:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<NexusTask>(
              value: _selectedTask,
              dropdownColor: DesignTokens.bgCard,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: .04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              hint: const Text('Chọn một công việc', style: TextStyle(color: Colors.white38)),
              items: incompleteTasks.map((t) {
                return DropdownMenuItem<NexusTask>(
                  value: t,
                  child: Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 14), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTask = val;
                });
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (_, __) => const Center(child: Text('Lỗi tải công việc', style: TextStyle(color: Colors.red))),
    );
  }

  Widget _buildAchievementTab(AsyncValue<UserProfileModel?> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        final list = ['Rank: ${profile.rankTitle}', 'Level ${profile.level} reached!', 'Focus Score: ${profile.focusScore}%'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Khoe thành tích:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAchievement,
              dropdownColor: DesignTokens.bgCard,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: .04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              hint: const Text('Chọn thành tích để chia sẻ', style: TextStyle(color: Colors.white38)),
              items: list.map((a) {
                return DropdownMenuItem<String>(
                  value: a,
                  child: Text(a, style: const TextStyle(color: Colors.white, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedAchievement = val;
                });
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (_, __) => const Center(child: Text('Lỗi tải thành tích', style: TextStyle(color: Colors.red))),
    );
  }

  Widget _buildPollTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tùy chọn bình chọn:', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            if (_pollOptionControllers.length < 4)
              TextButton.icon(
                icon: const Icon(Icons.add, size: 14, color: Color(0xFFA78BFA)),
                label: const Text('Thêm tùy chọn', style: TextStyle(color: Color(0xFFA78BFA), fontSize: 12)),
                onPressed: _addPollOption,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _pollOptionControllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _pollOptionControllers[index],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Lựa chọn ${index + 1}',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: .04),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    if (_pollOptionControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                        onPressed: () => _removePollOption(index),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
