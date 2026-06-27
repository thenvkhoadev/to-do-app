import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:to_do_app/features/social/presentation/providers/story_state_providers.dart';

enum MusicViewType { home, categories, saved, categoryDetail, searchResults }

class StoryMusicDialog extends ConsumerStatefulWidget {
  const StoryMusicDialog({
    super.key,
    required this.onSongSelected,
    required this.onClose,
  });

  final void Function(StorySong song) onSongSelected;
  final VoidCallback onClose;

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
  late AudioPlayer _audioPlayer;

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
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value, 0),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: MediaQuery.sizeOf(context).width >= 600 ? 380 : double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF242526),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          children: [
            // Search & Close Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(20),
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
                          hintText: 'Tìm kiếm nhạc',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: .4), fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: .4), size: 18),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .06),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Buttons: [🔖 Đã lưu] [≡ Lướt xem]
            if (_currentView == MusicViewType.home ||
                _currentView == MusicViewType.categories ||
                _currentView == MusicViewType.saved)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildTabButton(
                      label: 'Đã lưu',
                      icon: Icons.bookmark_border_rounded,
                      isActive: _currentView == MusicViewType.saved,
                      onTap: () => _changeView(MusicViewType.saved),
                    ),
                    const SizedBox(width: 10),
                    _buildTabButton(
                      label: 'Lướt xem',
                      icon: Icons.list_rounded,
                      isActive: _currentView == MusicViewType.categories,
                      onTap: () => _changeView(MusicViewType.categories),
                    ),
                  ],
                ),
              ),

            // Content Area based on current view
            Expanded(
              child: _buildViewContent(),
            ),
          ],
        ),
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
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withValues(alpha: .15) : Colors.white.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? Colors.white.withValues(alpha: .1) : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
        return _buildCategoriesView();
      case MusicViewType.saved:
        return _buildSavedSongsView();
      case MusicViewType.categoryDetail:
        return _buildCategoryDetailView();
      case MusicViewType.searchResults:
        return _buildSearchResultsView();
    }
  }

  // View: HOME (Recommended / Latest release lists)
  Widget _buildHomeView() {
    final songsAsync = ref.watch(mockSongsProvider);

    return songsAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
      )),
      error: (err, stack) => const Center(child: Text('Lỗi tải nhạc', style: TextStyle(color: Colors.white70))),
      data: (allSongs) {
        final recommended = allSongs.where((s) => s.category == 'Dành cho bạn').toList();
        final latest = allSongs.where((s) => s.category == 'Mới phát hành').toList();

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 8),
            _buildSectionHeader('Dành cho bạn', () => _changeView(MusicViewType.categoryDetail, category: 'Dành cho bạn')),
            ...recommended.take(3).map(_buildSongRow),
            const SizedBox(height: 16),
            _buildSectionHeader('Mới phát hành', () => _changeView(MusicViewType.categoryDetail, category: 'Mới phát hành')),
            ...latest.take(3).map(_buildSongRow),
          ],
        );
      },
    );
  }

  // View: BROWSE CATEGORIES (image9)
  Widget _buildCategoriesView() {
    final categories = [
      'Cuối tuần',
      'Sinh nhật',
      'Buổi tối hẹn hò',
      'Gia đình',
      'Tình yêu',
      'Buổi sáng',
      'R&B và Soul',
      'Pop',
      'Hip Hop',
      'Rock',
    ];

    return Column(
      children: [
        _buildSubHeader('Lướt xem hạng mục', () => _changeView(MusicViewType.home)),
        Expanded(
          child: ListView.separated(
            itemCount: categories.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () => _changeView(MusicViewType.categoryDetail, category: category),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Text(
                        category,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // View: SAVED MUSIC (image10)
  Widget _buildSavedSongsView() {
    final songsAsync = ref.watch(mockSongsProvider);
    final savedIds = ref.watch(savedMusicProvider);

    return songsAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
      )),
      error: (err, stack) => const Center(child: Text('Lỗi tải nhạc', style: TextStyle(color: Colors.white70))),
      data: (allSongs) {
        final savedSongs = allSongs.where((s) => savedIds.contains(s.id)).toList();

        return Column(
          children: [
            _buildSubHeader('Nhạc đã lưu', () => _changeView(MusicViewType.home)),
            Expanded(
              child: savedSongs.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có nhạc đã lưu',
                        style: TextStyle(color: Colors.white30, fontSize: 14),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: savedSongs.map(_buildSongRow).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  // View: CATEGORY DETAILS (image11)
  Widget _buildCategoryDetailView() {
    final songsAsync = ref.watch(mockSongsProvider);

    return songsAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
      )),
      error: (err, stack) => const Center(child: Text('Lỗi tải nhạc', style: TextStyle(color: Colors.white70))),
      data: (allSongs) {
        final categorySongs = allSongs.where((s) => s.category == _selectedCategory).toList();

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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: categorySongs.map(_buildSongRow).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  // View: SEARCH RESULTS
  Widget _buildSearchResultsView() {
    final searchAsync = ref.watch(musicSearchResultsProvider);

    return searchAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: Color(0xFF7C5CFF)),
      )),
      error: (err, stack) => const Center(child: Text('Lỗi tải kết quả', style: TextStyle(color: Colors.white70))),
      data: (filtered) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      padding: const EdgeInsets.only(top: 8.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 1.5),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: () => widget.onSongSelected(song),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                // Cover Art
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    song.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

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
                ),

                // Play ▶ Button
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
                          await _audioPlayer.play(UrlSource(song.audioUrl));
                        } catch (_) {}
                      }
                    }
                  },
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .15),
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 16,
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
