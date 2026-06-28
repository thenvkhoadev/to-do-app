import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

enum ImageFitType { cover, fit }

// Screens inside story creator
enum CreatorScreenType { select, text, image, video }

// Overlay model for texts on photo stories
class TextOverlay {
  final String id;
  final String text;
  final Color color;
  final double x; // offset X ratio
  final double y; // offset Y ratio
  final double scale;

  TextOverlay({
    required this.id,
    required this.text,
    required this.color,
    this.x = 0.5,
    this.y = 0.5,
    this.scale = 1.0,
  });

  TextOverlay copyWith({
    String? id,
    String? text,
    Color? color,
    double? x,
    double? y,
    double? scale,
  }) {
    return TextOverlay(
      id: id ?? this.id,
      text: text ?? this.text,
      color: color ?? this.color,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'color': color.value,
        'x': x,
        'y': y,
        'scale': scale,
      };

  factory TextOverlay.fromJson(Map<String, dynamic> json) => TextOverlay(
        id: json['id'] as String,
        text: json['text'] as String,
        color: Color(json['color'] as int),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        scale: (json['scale'] as num).toDouble(),
      );
}

// Music overlay model
class MusicOverlay {
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final double x;
  final double y;
  final double scale;
  final int startTimeSec;
  final int durationSec;
  final int layoutStyle; // 0, 1, 2, 3
  final double volume; // Added music volume (0.0 to 1.0, default 1.0)
  final double originalVolume; // Original video volume (0.0 to 1.0, default 1.0)

  MusicOverlay({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    this.x = 0.5,
    this.y = 0.6,
    this.scale = 1.0,
    this.startTimeSec = 0,
    this.durationSec = 15,
    this.layoutStyle = 0,
    this.volume = 1.0,
    this.originalVolume = 1.0,
  });

  MusicOverlay copyWith({
    String? title,
    String? artist,
    String? coverUrl,
    String? audioUrl,
    double? x,
    double? y,
    double? scale,
    int? startTimeSec,
    int? durationSec,
    int? layoutStyle,
    double? volume,
    double? originalVolume,
  }) {
    return MusicOverlay(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      startTimeSec: startTimeSec ?? this.startTimeSec,
      durationSec: durationSec ?? this.durationSec,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      volume: volume ?? this.volume,
      originalVolume: originalVolume ?? this.originalVolume,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'artist': artist,
        'coverUrl': coverUrl,
        'audioUrl': audioUrl,
        'x': x,
        'y': y,
        'scale': scale,
        'startTimeSec': startTimeSec,
        'durationSec': durationSec,
        'layoutStyle': layoutStyle,
        'volume': volume,
        'originalVolume': originalVolume,
      };

  factory MusicOverlay.fromJson(Map<String, dynamic> json) => MusicOverlay(
        title: json['title'] as String,
        artist: json['artist'] as String,
        coverUrl: json['coverUrl'] as String,
        audioUrl: json['audioUrl'] as String? ?? '',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        scale: (json['scale'] as num).toDouble(),
        startTimeSec: json['startTimeSec'] as int,
        durationSec: json['durationSec'] as int,
        layoutStyle: json['layoutStyle'] as int? ?? 0,
        volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
        originalVolume: (json['originalVolume'] as num?)?.toDouble() ?? 1.0,
      );
}

// Story Creator State
class StoryCreatorState {
  final CreatorScreenType screenType;
  final XFile? imageFile;
  final XFile? videoFile;
  final double zoom;
  final double rotation; // 0, 90, 180, 270 degrees
  final double panX;
  final double panY;
  final String text;
  final String fontFamily;
  final int backgroundColorIndex;
  final List<TextOverlay> textOverlays;
  final MusicOverlay? musicOverlay;
  final String altText;
  final bool isAltTextAI; // true if using AI detect, false if custom text
  final ImageFitType imageFit;

  StoryCreatorState({
    this.screenType = CreatorScreenType.select,
    this.imageFile,
    this.videoFile,
    this.zoom = 1.0,
    this.rotation = 0.0,
    this.panX = 0.0,
    this.panY = 0.0,
    this.text = '',
    this.fontFamily = 'Gọn Gàng',
    this.backgroundColorIndex = 0,
    this.textOverlays = const [],
    this.musicOverlay,
    this.altText = '',
    this.isAltTextAI = true,
    this.imageFit = ImageFitType.fit,
  });

  StoryCreatorState copyWith({
    CreatorScreenType? screenType,
    XFile? imageFile,
    XFile? videoFile,
    double? zoom,
    double? rotation,
    double? panX,
    double? panY,
    String? text,
    String? fontFamily,
    int? backgroundColorIndex,
    List<TextOverlay>? textOverlays,
    MusicOverlay? musicOverlay,
    String? altText,
    bool? isAltTextAI,
    ImageFitType? imageFit,
  }) {
    return StoryCreatorState(
      screenType: screenType ?? this.screenType,
      imageFile: imageFile ?? this.imageFile,
      videoFile: videoFile ?? this.videoFile,
      zoom: zoom ?? this.zoom,
      rotation: rotation ?? this.rotation,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      text: text ?? this.text,
      fontFamily: fontFamily ?? this.fontFamily,
      backgroundColorIndex: backgroundColorIndex ?? this.backgroundColorIndex,
      textOverlays: textOverlays ?? this.textOverlays,
      musicOverlay: musicOverlay ?? this.musicOverlay,
      altText: altText ?? this.altText,
      isAltTextAI: isAltTextAI ?? this.isAltTextAI,
      imageFit: imageFit ?? this.imageFit,
    );
  }
}

class StoryCreatorNotifier extends StateNotifier<StoryCreatorState?> {
  StoryCreatorNotifier() : super(null);

  void startCreating() {
    state = StoryCreatorState(screenType: CreatorScreenType.select);
  }

  void reset() => state = null;

  void updateState(StoryCreatorState newState) => state = newState;

  void setScreenType(CreatorScreenType type) {
    if (state == null) return;
    state = state!.copyWith(screenType: type);
  }

  void setImageFile(XFile file) => state = StoryCreatorState(
        imageFile: file,
        screenType: CreatorScreenType.image,
        zoom: 1.0,
        rotation: 0.0,
        panX: 0.0,
        panY: 0.0,
        textOverlays: [],
        musicOverlay: null,
        imageFit: ImageFitType.fit,
      );

  void setVideoFile(XFile file) => state = StoryCreatorState(
        videoFile: file,
        screenType: CreatorScreenType.video,
        zoom: 1.0,
        rotation: 0.0,
        panX: 0.0,
        panY: 0.0,
        textOverlays: [],
        musicOverlay: null,
        imageFit: ImageFitType.fit,
      );

  void setZoom(double val) {
    if (state == null) return;
    state = state!.copyWith(zoom: val);
  }

  void setRotation(double val) {
    if (state == null) return;
    state = state!.copyWith(rotation: val);
  }

  void setPan(double x, double y) {
    if (state == null) return;
    state = state!.copyWith(panX: x, panY: y);
  }

  void setImageFit(ImageFitType fit) {
    if (state == null) return;
    state = state!.copyWith(imageFit: fit);
  }

  void setText(String val) {
    if (state == null) return;
    state = state!.copyWith(text: val);
  }

  void setFontFamily(String val) {
    if (state == null) return;
    state = state!.copyWith(fontFamily: val);
  }

  void setBackgroundColorIndex(int val) {
    if (state == null) return;
    state = state!.copyWith(backgroundColorIndex: val);
  }

  void addTextOverlay(TextOverlay overlay) {
    if (state == null) return;
    state = state!.copyWith(
      textOverlays: [...state!.textOverlays, overlay],
    );
  }

  void updateTextOverlay(TextOverlay overlay) {
    if (state == null) return;
    state = state!.copyWith(
      textOverlays: state!.textOverlays
          .map((o) => o.id == overlay.id ? overlay : o)
          .toList(),
    );
  }

  void removeTextOverlay(String id) {
    if (state == null) return;
    state = state!.copyWith(
      textOverlays: state!.textOverlays.where((o) => o.id != id).toList(),
    );
  }

  void setMusicOverlay(MusicOverlay? overlay) {
    if (state == null) return;
    if (overlay == null) {
      state = StoryCreatorState(
        screenType: state!.screenType,
        imageFile: state!.imageFile,
        videoFile: state!.videoFile,
        zoom: state!.zoom,
        rotation: state!.rotation,
        panX: state!.panX,
        panY: state!.panY,
        text: state!.text,
        fontFamily: state!.fontFamily,
        backgroundColorIndex: state!.backgroundColorIndex,
        textOverlays: state!.textOverlays,
        musicOverlay: null, // Clear music overlay
        altText: state!.altText,
        isAltTextAI: state!.isAltTextAI,
        imageFit: state!.imageFit,
      );
    } else {
      state = state!.copyWith(musicOverlay: overlay);
    }
  }

  void setAltText(String val, bool isAI) {
    if (state == null) return;
    state = state!.copyWith(altText: val, isAltTextAI: isAI);
  }
}

final storyCreatorProvider =
    StateNotifierProvider<StoryCreatorNotifier, StoryCreatorState?>((ref) {
  return StoryCreatorNotifier();
});

// Story Viewer State
class StoryViewerState {
  final String? activeAuthorId;
  final int activeStoryIndex;
  final bool isPlaying;

  StoryViewerState({
    this.activeAuthorId,
    this.activeStoryIndex = 0,
    this.isPlaying = true,
  });

  StoryViewerState copyWith({
    String? activeAuthorId,
    int? activeStoryIndex,
    bool? isPlaying,
  }) {
    return StoryViewerState(
      activeAuthorId: activeAuthorId ?? this.activeAuthorId,
      activeStoryIndex: activeStoryIndex ?? this.activeStoryIndex,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}

class StoryViewerNotifier extends StateNotifier<StoryViewerState?> {
  StoryViewerNotifier() : super(null);

  void openViewer(String authorId, int initialIndex) {
    state = StoryViewerState(
      activeAuthorId: authorId,
      activeStoryIndex: initialIndex,
      isPlaying: true,
    );
  }

  void closeViewer() => state = null;

  void nextStory(int totalStoriesForAuthor, VoidCallback onNextAuthor) {
    if (state == null) return;
    if (state!.activeStoryIndex < totalStoriesForAuthor - 1) {
      state = state!.copyWith(activeStoryIndex: state!.activeStoryIndex + 1);
    } else {
      // Finished all stories for this author
      onNextAuthor();
    }
  }

  void prevStory(VoidCallback onPrevAuthor) {
    if (state == null) return;
    if (state!.activeStoryIndex > 0) {
      state = state!.copyWith(activeStoryIndex: state!.activeStoryIndex - 1);
    } else {
      // Go to previous author
      onPrevAuthor();
    }
  }

  void selectStoryIndex(int index) {
    if (state == null) return;
    state = state!.copyWith(activeStoryIndex: index);
  }

  void setPlaying(bool val) {
    if (state == null) return;
    state = state!.copyWith(isPlaying: val);
  }
}

final storyViewerStateProvider =
    StateNotifierProvider<StoryViewerNotifier, StoryViewerState?>((ref) {
  return StoryViewerNotifier();
});

// Story Privacy State
final storyPrivacyProvider = StateProvider<String>((ref) => 'public');

// Mock Song class
class StorySong {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String audioUrl;
  final String category;
  final int durationSec;
  final bool isVerified;

  StorySong({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.audioUrl,
    required this.category,
    this.durationSec = 30,
    this.isVerified = false,
  });
}

// Fallback Mock Songs
final List<StorySong> _defaultMockSongsList = [
  StorySong(
    id: '1',
    title: 'Come My Way',
    artist: 'Sơn Tùng M-TP, Tyga',
    coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    category: 'Mới phát hành',
  ),
  StorySong(
    id: '2',
    title: 'Dai Dai',
    artist: 'Shakira, Burna Boy',
    coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    category: 'Mới phát hành',
  ),
  StorySong(
    id: '3',
    title: 'NO ERA AMOR',
    artist: 'DJ Asul',
    coverUrl: 'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    category: 'Dành cho bạn',
  ),
  StorySong(
    id: '4',
    title: 'Beautiful Things',
    artist: 'Benson Boone',
    coverUrl: 'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    category: 'Pop',
  ),
  StorySong(
    id: '5',
    title: 'Flowers',
    artist: 'Miley Cyrus',
    coverUrl: 'https://images.unsplash.com/photo-1498038432885-c6f3f1b912ee?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    category: 'Pop',
  ),
  StorySong(
    id: '6',
    title: 'Cruel Summer',
    artist: 'Taylor Swift',
    coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    category: 'Tình yêu',
  ),
  StorySong(
    id: '7',
    title: 'As It Was',
    artist: 'Harry Styles',
    coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    category: 'Buổi sáng',
  ),
  StorySong(
    id: '8',
    title: 'Stay',
    artist: 'The Kid LAROI, Justin Bieber',
    coverUrl: 'https://images.unsplash.com/photo-1487180142328-0c4e37023af5?w=150&auto=format&fit=crop&q=80',
    audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    category: 'Hip Hop',
  ),
  StorySong(
    id: '9',
    title: 'Blinding Lights',
    artist: 'The Weeknd',
    coverUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=150&auto=format&fit=crop&q=80',
    audioUrl: '',
    category: 'R&B và Soul',
  ),
  StorySong(
    id: '10',
    title: 'Dynamite',
    artist: 'BTS',
    coverUrl: 'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=150&auto=format&fit=crop&q=80',
    audioUrl: '',
    category: 'Cuối tuần',
  ),
  StorySong(
    id: '11',
    title: 'Sinh Nhật Vui Vẻ',
    artist: 'Phan Đinh Tùng',
    coverUrl: 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=150&auto=format&fit=crop&q=80',
    audioUrl: '',
    category: 'Sinh nhật',
  ),
  StorySong(
    id: '12',
    title: 'Date Night Jazz',
    artist: 'Jazz Master Trio',
    coverUrl: 'https://images.unsplash.com/photo-1486591978090-58e619d37fe7?w=150&auto=format&fit=crop&q=80',
    audioUrl: '',
    category: 'Buổi tối hẹn hò',
  ),
  StorySong(
    id: '13',
    title: 'Gia Đình Nhỏ, Hạnh Phúc To',
    artist: 'Nguyễn Văn Chung',
    coverUrl: 'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?w=150&auto=format&fit=crop&q=80',
    audioUrl: '',
    category: 'Gia đình',
  ),
  StorySong(
    id: '14',
    title: 'Sweet Rock',
    artist: 'The Hardcore Kids',
    coverUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=150&auto=format&fit=crop&q=80',
    audioUrl: '',
    category: 'Rock',
  ),
];

// Map of Deezer Category Radios
const Map<String, int> _deezerCategoryRadios = {
  'Pop': 132,
  'EDM': 106,
  'Rap': 116,
  'Rock': 152,
};

// Mock Music Library (Now fetching from Deezer Charts API)
final mockSongsProvider = FutureProvider<List<StorySong>>((ref) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));
  try {
    final response = await dio.get('https://api.deezer.com/chart/0/tracks?limit=50');
    final results = response.data['data'] as List<dynamic>;

    final List<StorySong> list = [];
    int index = 0;
    for (final item in results) {
      final id = item['id']?.toString() ?? index.toString();
      final title = item['title'] as String? ?? 'Bài hát không tên';
      final artist = item['artist']?['name'] as String? ?? 'Ca sĩ ẩn danh';
      final coverUrl = item['album']?['cover_medium'] as String? ?? '';
      final audioUrl = item['preview'] as String? ?? '';
      final duration = item['duration'] as int? ?? 30;

      if (audioUrl.isEmpty) continue;

      // Assign categories for homepage listing
      String category = 'Dành cho bạn';
      if (index < 12) {
        category = 'Dành cho bạn';
      } else {
        category = 'Mới phát hành';
      }

      list.add(StorySong(
        id: id,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        audioUrl: audioUrl,
        category: category,
        durationSec: duration,
        isVerified: true,
      ));
      index++;
    }
    return list.isNotEmpty ? list : _defaultMockSongsList;
  } catch (e) {
    debugPrint('Error fetching Deezer charts: $e');
    return _defaultMockSongsList;
  }
});

// Search State & Provider for Deezer Search
final musicSearchQueryProvider = StateProvider<String>((ref) => '');

final musicSearchResultsProvider = FutureProvider<List<StorySong>>((ref) async {
  final query = ref.watch(musicSearchQueryProvider);
  if (query.trim().isEmpty) return [];

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));
  try {
    final response = await dio.get('https://api.deezer.com/search?q=${Uri.encodeComponent(query)}&limit=25');
    final results = response.data['data'] as List<dynamic>;

    final List<StorySong> list = [];
    for (final item in results) {
      final id = item['id']?.toString() ?? '';
      final title = item['title'] as String? ?? 'Bài hát không tên';
      final artist = item['artist']?['name'] as String? ?? 'Ca sĩ ẩn danh';
      final coverUrl = item['album']?['cover_medium'] as String? ?? '';
      final audioUrl = item['preview'] as String? ?? '';
      final duration = item['duration'] as int? ?? 30;

      if (audioUrl.isNotEmpty) {
        list.add(StorySong(
          id: id,
          title: title,
          artist: artist,
          coverUrl: coverUrl,
          audioUrl: audioUrl,
          category: 'Tìm kiếm',
          durationSec: duration,
          isVerified: true,
        ));
      }
    }
    return list;
  } catch (e) {
    debugPrint('Error searching Deezer: $e');
    return [];
  }
});

// Dynamic Radio Category Songs Provider family
final categorySongsProvider = FutureProvider.family<List<StorySong>, String>((ref, categoryName) async {
  final radioId = _deezerCategoryRadios[categoryName];
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 3),
    receiveTimeout: const Duration(seconds: 3),
  ));

  try {
    final List<dynamic> results;
    if (radioId != null) {
      final response = await dio.get('https://api.deezer.com/radio/$radioId/tracks?limit=25');
      results = response.data['data'] as List<dynamic>;
    } else {
      // For Vpop, Kpop, Lofi, Acoustic etc. search query fallback
      final response = await dio.get('https://api.deezer.com/search?q=${Uri.encodeComponent(categoryName)}&limit=25');
      results = response.data['data'] as List<dynamic>;
    }

    final List<StorySong> list = [];
    for (final item in results) {
      final id = item['id']?.toString() ?? '';
      final title = item['title'] as String? ?? 'Bài hát không tên';
      final artist = item['artist']?['name'] as String? ?? 'Ca sĩ ẩn danh';
      final coverUrl = item['album']?['cover_medium'] as String? ?? '';
      final audioUrl = item['preview'] as String? ?? '';
      final duration = item['duration'] as int? ?? 30;

      if (audioUrl.isNotEmpty) {
        list.add(StorySong(
          id: id,
          title: title,
          artist: artist,
          coverUrl: coverUrl,
          audioUrl: audioUrl,
          category: categoryName,
          durationSec: duration,
          isVerified: true,
        ));
      }
    }
    return list;
  } catch (e) {
    debugPrint('Error fetching category songs from Deezer: $e');
    return [];
  }
});

// Saved music state (list of saved song IDs)
class SavedMusicNotifier extends StateNotifier<Set<String>> {
  SavedMusicNotifier() : super({'3', '6'}); // Default save some songs for testing

  void toggleSave(String songId) {
    if (state.contains(songId)) {
      state = state.where((id) => id != songId).toSet();
    } else {
      state = {...state, songId};
    }
  }

  bool isSaved(String songId) => state.contains(songId);
}

final savedMusicProvider =
    StateNotifierProvider<SavedMusicNotifier, Set<String>>((ref) {
  return SavedMusicNotifier();
});

// Gradient list for text story background swatches
final storyGradientsList = Provider<List<LinearGradient>>((ref) {
  return const [
    LinearGradient(
      colors: [Color(0xFF1877F2), Color(0xFF00C6FF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    LinearGradient(
      colors: [Color(0xFFC678DD), Color(0xFFE96FA0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF10B981), Color(0xFF059669)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
    LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Row 2
    LinearGradient(
      colors: [Color(0xFF00F260), Color(0xFF0575E6)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFEB3349), Color(0xFFF45C43)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFA8C0FF), Color(0xFF3F2B96)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF3A6073), Color(0xFF3A7BD5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF232526), Color(0xFF414345)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    // Extra swatches for expanded state
    LinearGradient(
      colors: [Color(0xFFFF0844), Color(0xFFFFB199)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF7028E4), Color(0xFFE5B2CA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF184E68), Color(0xFF57CA85)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFAD961), Color(0xFFF76B1C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF30CFD0), Color(0xFF330867)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF00FF87), Color(0xFF60EFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFF4E50), Color(0xFFF9D423)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];
});
