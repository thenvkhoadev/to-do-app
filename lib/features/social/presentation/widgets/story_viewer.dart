import 'package:to_do_app/features/social/presentation/widgets/premium_toast.dart';
import 'package:flutter/material.dart';
import 'package:to_do_app/features/social/data/models/story_model.dart';

class StoryViewer extends StatefulWidget {
  const StoryViewer({
    super.key,
    required this.stories,
    required this.onClose,
    this.onStorySeen,
    this.onSendReply,
  });

  final List<StoryModel> stories;
  final VoidCallback onClose;
  final ValueChanged<String>? onStorySeen;
  final void Function(String reply)? onSendReply;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animController;
  int _currentIndex = 0;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animController = AnimationController(vsync: this);

    // Start with the first unseen story, if any
    int initialIndex = 0;
    for (int i = 0; i < widget.stories.length; i++) {
      if (widget.stories[i].viewedByUserIds.isEmpty) {
        initialIndex = i;
        break;
      }
    }
    _currentIndex = initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(initialIndex);
      }
      _loadStory(story: widget.stories[_currentIndex], animateToPage: false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _loadStory({required StoryModel story, bool animateToPage = true}) {
    _animController.stop();
    _animController.reset();
    _animController.duration = const Duration(seconds: 5);
    _animController.forward();

    if (animateToPage) {
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (widget.onStorySeen != null) {
      widget.onStorySeen!(story.id);
    }
  }

  void _onTapDown(TapDownDetails details) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double dx = details.globalPosition.dx;

    if (dx < screenWidth / 3) {
      // Tap left: Go back
      setState(() {
        if (_currentIndex > 0) {
          _currentIndex--;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          // At first story, close
          widget.onClose();
        }
      });
    } else {
      // Tap right: Go forward
      setState(() {
        if (_currentIndex < widget.stories.length - 1) {
          _currentIndex++;
          _loadStory(story: widget.stories[_currentIndex]);
        } else {
          // At last story, close
          widget.onClose();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) return const SizedBox.shrink();

    final activeStory = widget.stories[_currentIndex];

    // Trigger next story when animation finishes
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            if (_currentIndex < widget.stories.length - 1) {
              _currentIndex++;
              _loadStory(story: widget.stories[_currentIndex]);
            } else {
              widget.onClose();
            }
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTapDown: _onTapDown,
          onVerticalDragUpdate: (details) {
            // Drag down to close
            if (details.delta.dy > 10) {
              widget.onClose();
            }
          },
          child: Stack(
            children: [
              // Content PageView
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.stories.length,
                itemBuilder: (context, index) {
                  final story = widget.stories[index];
                  return Center(
                    child: _buildStoryContent(story),
                  );
                },
              ),

              // UI Overlay
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress Bars
                    Row(
                      children: List.generate(
                        widget.stories.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: _buildProgressBar(index),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Author Header Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: activeStory.authorAvatarUrl.isNotEmpty
                              ? NetworkImage(activeStory.authorAvatarUrl)
                              : null,
                          backgroundColor: Colors.grey.shade800,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              activeStory.authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _timeAgo(activeStory.createdAt),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
                          onPressed: widget.onClose,
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Reply Box
                    _buildReplyBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(int index) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        double val = 0.0;
        if (index < _currentIndex) {
          val = 1.0;
        } else if (index == _currentIndex) {
          val = _animController.value;
        }
        return LinearProgressIndicator(
          value: val,
          backgroundColor: Colors.white.withValues(alpha: .3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 3.5,
          borderRadius: BorderRadius.circular(4),
        );
      },
    );
  }

  Widget _buildStoryContent(StoryModel story) {
    switch (story.contentType) {
      case StoryContentType.photo:
        return story.mediaUrl != null && story.mediaUrl!.isNotEmpty
            ? Image.network(
                story.mediaUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              )
            : const Center(
                child: Text('Không có hình ảnh', style: TextStyle(color: Colors.white)),
              );

      case StoryContentType.taskSummary:
        final int taskCount = story.autoData?['taskCount'] as int? ?? 0;
        final int xp = story.autoData?['xp'] as int? ?? 0;
        return _buildStatCard(
          title: 'HÀNH TRÌNH HÔM NAY ⚡',
          subtitle: 'Hoàn thành xuất sắc mục tiêu ngày',
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statText: '$taskCount',
          statLabel: 'Công việc hoàn thành',
          xpText: '+$xp XP tích lũy',
          icon: Icons.check_circle_outline_rounded,
        );

      case StoryContentType.streak:
        final int streak = story.autoData?['streakCount'] as int? ?? 0;
        return _buildStatCard(
          title: 'CHUỖI PHÁT TRIỂN 🔥',
          subtitle: 'Duy trì năng suất liên tục',
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statText: '$streak',
          statLabel: 'ngày liên tiếp',
          xpText: 'Tiếp tục giữ vững chuỗi!',
          icon: Icons.local_fire_department_rounded,
        );

      case StoryContentType.achievement:
        final String title = story.autoData?['title'] as String? ?? 'Thành tựu';
        final String desc = story.autoData?['desc'] as String? ?? '';
        return _buildStatCard(
          title: 'THÀNH TỰU ĐẠT ĐƯỢC 🏆',
          subtitle: title,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          statText: '🏆',
          statLabel: desc,
          xpText: 'Mở khóa thành công!',
          icon: Icons.military_tech_rounded,
        );
    }
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required Gradient gradient,
    required String statText,
    required String statLabel,
    required String xpText,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      height: 480,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.white),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .85),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 40),
          if (statText == '🏆')
            const SizedBox.shrink()
          else
            Text(
              statText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 84,
                fontWeight: FontWeight.w900,
              ),
            ),
          Text(
            statLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              xpText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    return Container(
      height: 52,
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              onTap: () {
                // Pause timer while typing
                _animController.stop();
              },
              onSubmitted: (text) {
                // Resume timer
                _animController.forward();
                if (text.isNotEmpty) {
                  if (widget.onSendReply != null) {
                    widget.onSendReply!(text);
                  }
                  _replyController.clear();
                  PremiumToast.show(context, 'Đã gửi phản hồi!');
                }
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Trả lời tin...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: .5)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: .15),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: Colors.red),
            onPressed: () {
              if (widget.onSendReply != null) {
                widget.onSendReply!('❤️');
              }
              PremiumToast.show(context, 'Đã thả tim!');
            },
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours >= 1) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
