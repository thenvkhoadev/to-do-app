import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';
import 'dart:ui' as java_dart_ui;

enum MusicViewType { home, categories, saved, categoryDetail, searchResults }

class StoryMusicDialog extends ConsumerStatefulWidget {
  const StoryMusicDialog({
    super.key,
    required this.onSongSelected,
    required this.onClose,
    required this.audioPlayer,
    this.isInline = false,
  });

  final void Function(StorySong song) onSongSelected;
  final VoidCallback onClose;
  final AudioPlayer audioPlayer;
  final bool isInline;

  @override
  ConsumerState<StoryMusicDialog> createState() => _StoryMusicDialogState();
}

class _StoryMusicDialogState extends ConsumerState<StoryMusicDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  MusicViewType _currentView = MusicViewType.home;
  String _searchQuery = '';
  String _selectedCategory = '';
  String? _playingSongId; // Tracks currently playing preview song
  late final AudioPlayer _audioPlayer;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    _animController.forward();
    _audioPlayer = widget.audioPlayer;
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _changeView(MusicViewType view, {String category = ''}) {
    setState(() {
      _currentView = view;
      if (category.isNotEmpty) {
        _selectedCategory = category;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDesktop = size.width >= 1200;

    final innerContent = Column(
      children: [
        // Header Bar (Search & Close)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        if (val.isNotEmpty) {
                          _currentView = MusicViewType.searchResults;
                        } else {
                          _currentView = MusicViewType.home;
                        }
                      });
                      ref.read(musicSearchQueryProvider.notifier).state = val;
                    },
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm bài hát, ca sĩ, album...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: .3), fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: .3), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .08),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Horizontal Categories Scroll Bar
        _buildCategorySelector(),

        // Tab Navigation
        if (_currentView == MusicViewType.home ||
            _currentView == MusicViewType.saved ||
            _currentView == MusicViewType.categories)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildTabButton(
                  label: 'Khám phá',
                  icon: Icons.explore_outlined,
                  isActive: _currentView == MusicViewType.home,
                  onTap: () => _changeView(MusicViewType.home),
                ),
                const SizedBox(width: 12),
                _buildTabButton(
                  label: 'Đã lưu',
                  icon: Icons.bookmark_border_rounded,
                  isActive: _currentView == MusicViewType.saved,
                  onTap: () => _changeView(MusicViewType.saved),
                ),
              ],
            ),
          ),

        // Content Area
        Expanded(
          child: ClipRRect(
            child: _buildViewContent(),
          ),
        ),
      ],
    );

    if (widget.isInline) {
      return Container(
        color: const Color(0xFF1E1C30),
        child: innerContent,
      );
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 20), // Slide up transition
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Stack(
        children: [
          // Fullscreen dark blurred background
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: .75),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: java_dart_ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: .8),
                      const Color(0xFF1E1C30).withValues(alpha: .8),
                      Colors.black.withValues(alpha: .9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Dialog Card centered on desktop, fullscreen on mobile
          Center(
            child: Container(
              width: isDesktop ? 600 : double.infinity,
              height: isDesktop ? size.height * 0.85 : double.infinity,
              margin: isDesktop ? const EdgeInsets.symmetric(vertical: 40) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .03),
                borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
                border: Border.all(
                  color: Colors.white.withValues(alpha: .08),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isDesktop ? 24 : 0),
                child: innerContent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['Pop', 'EDM', 'Rap', 'Rock', 'Kpop', 'Vpop', 'Lofi', 'Acoustic'];
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isActive = _currentView == MusicViewType.categoryDetail && _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isActive,
              onSelected: (selected) {
                if (selected) {
                  _changeView(MusicViewType.categoryDetail, category: cat);
                } else {
                  _changeView(MusicViewType.home);
                }
              },
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white.withValues(alpha: .06),
              selectedColor: const Color(0xFF7C5CFF),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: .12) : Colors.white.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isActive ? Colors.white.withValues(alpha: .08) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isActive ? const Color(0xFF7C5CFF) : Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewContent() {
    switch (_currentView) {
      case MusicViewType.home:
        return _buildHomeView();
      case MusicViewType.categories:
        return _buildHomeView();
      case MusicViewType.saved:
        return _buildSavedSongsView();
      case MusicViewType.categoryDetail:
        return _buildCategoryDetailView();
      case MusicViewType.searchResults:
        return _buildSearchResultsView();
    }
  }

  Widget _buildHomeView() {
    final songsAsync = ref.watch(mockSongsProvider);

    return songsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF))),
      error: (err, stack) => const Center(child: Text('Lỗi tải danh sách nhạc', style: TextStyle(color: Colors.white70))),
      data: (allSongs) {
        final trending = allSongs.where((s) => s.category == 'Dành cho bạn').toList();
        final recommended = allSongs.where((s) => s.category == 'Mới phát hành').toList();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _buildSectionHeader('Thịnh hành (Trending)', () => _changeView(MusicViewType.categoryDetail, category: 'Dành cho bạn')),
            ...trending.take(5).map(_buildSongRow),
            const SizedBox(height: 20),
            _buildSectionHeader('Gợi ý cho bạn', () => _changeView(MusicViewType.categoryDetail, category: 'Mới phát hành')),
            ...recommended.take(5).map(_buildSongRow),
          ],
        );
      },
    );
  }

  Widget _buildSavedSongsView() {
    final songsAsync = ref.watch(mockSongsProvider);
    final savedIds = ref.watch(savedMusicProvider);

    return songsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF))),
      error: (err, stack) => const Center(child: Text('Lỗi tải nhạc đã lưu', style: TextStyle(color: Colors.white70))),
      data: (allSongs) {
        final savedSongs = allSongs.where((s) => savedIds.contains(s.id)).toList();

        return Column(
          children: [
            _buildSubHeader('Danh sách đã lưu', () => _changeView(MusicViewType.home)),
            Expanded(
              child: savedSongs.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có bài hát nào được lưu',
                        style: TextStyle(color: Colors.white30, fontSize: 14),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: savedSongs.map(_buildSongRow).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDetailView() {
    final isPreset = _selectedCategory == 'Dành cho bạn' || _selectedCategory == 'Mới phát hành';
    final songsAsync = isPreset
        ? ref.watch(mockSongsProvider)
        : ref.watch(categorySongsProvider(_selectedCategory));

    return songsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF))),
      error: (err, stack) => const Center(child: Text('Lỗi tải danh mục', style: TextStyle(color: Colors.white70))),
      data: (allSongs) {
        final categorySongs = isPreset
            ? allSongs.where((s) => s.category == _selectedCategory).toList()
            : allSongs;

        return Column(
          children: [
            _buildSubHeader(_selectedCategory, () => _changeView(MusicViewType.home)),
            Expanded(
              child: categorySongs.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy bài hát trong danh mục này',
                        style: TextStyle(color: Colors.white30, fontSize: 13),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      children: categorySongs.map(_buildSongRow).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResultsView() {
    final searchAsync = ref.watch(musicSearchResultsProvider);

    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF7C5CFF))),
      error: (err, stack) => const Center(child: Text('Lỗi tìm kiếm', style: TextStyle(color: Colors.white70))),
      data: (filtered) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8.0),
              child: Text(
                'Kết quả tìm kiếm cho "${_searchQuery}"',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy bài hát nào',
                        style: TextStyle(color: Colors.white30, fontSize: 13),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: filtered.map(_buildSongRow).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'Xem tất cả',
                style: TextStyle(
                  color: Color(0xFF7C5CFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader(String title, VoidCallback onBack) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongRow(StorySong song) {
    final savedNotifier = ref.read(savedMusicProvider.notifier);
    final isSaved = ref.watch(savedMusicProvider).contains(song.id);
    final isPlaying = _playingSongId == song.id;

    String formatDuration(int sec) {
      final m = sec ~/ 60;
      final s = (sec % 60).toString().padLeft(2, '0');
      return '$m:$s';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: isPlaying ? Colors.white.withValues(alpha: .04) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => widget.onSongSelected(song),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              children: [
                // Cover Art with FadeIn
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    song.coverUrl,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: Colors.white10,
                      child: const Icon(Icons.music_note_rounded, color: Colors.white30, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title & Artist & Verified & Duration
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPlaying ? const Color(0xFF7C5CFF) : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (song.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, color: Color(0xFF00B2FF), size: 14),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formatDuration(song.durationSec),
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Bookmark 🔖 Button
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isSaved ? const Color(0xFF7C5CFF) : Colors.white30,
                    size: 20,
                  ),
                  onPressed: () {
                    savedNotifier.toggleSave(song.id);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),

                // Play/Pause ▶ Button
                GestureDetector(
                  onTap: () async {
                    if (isPlaying) {
                      await _audioPlayer.stop();
                      setState(() {
                        _playingSongId = null;
                      });
                    } else {
                      setState(() {
                        _playingSongId = song.id;
                      });
                      if (song.audioUrl.isNotEmpty) {
                        try {
                          await _audioPlayer.stop();
                          await _audioPlayer.setVolume(1.0);
                          await _audioPlayer.setUrl(song.audioUrl);
                          await _audioPlayer.play();
                        } catch (e) {
                          debugPrint('Error playing preview: $e');
                        }
                      }
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPlaying ? const Color(0xFF7C5CFF).withValues(alpha: .2) : Colors.white.withValues(alpha: .08),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: isPlaying ? const Color(0xFF7C5CFF) : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
