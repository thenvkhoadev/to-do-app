import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:to_do_app/core/utils/permission_helper.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelId;
  final String token;
  final String remoteUserName;
  final String? remoteAvatar;

  const VideoCallScreen({
    super.key,
    required this.channelId,
    required this.token,
    required this.remoteUserName,
    this.remoteAvatar,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with TickerProviderStateMixin {
  RtcEngine? _engine;
  bool _isJoined = false;
  int? _remoteUid;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = true;
  bool _initFailed = false;
  String? _initErrorMessage;

  // Simulated calling properties for fallback
  bool _isCallConnected = false;
  int _callDurationSeconds = 0;
  Timer? _simulatedConnectTimer;
  Timer? _durationTimer;
  late final AudioPlayer _player = AudioPlayer();
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _initCallEngine();
  }

  Future<void> _initCallEngine() async {
    // Agora is not supported on Windows inside our environment or web
    if (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _enableSimulatedCall('Agora không được hỗ trợ trên nền tảng Desktop hiện tại. Đang chạy ở chế độ giả lập.');
      return;
    }

    try {
      // 1. Request permissions
      final cameraGranted = await PermissionHelper.requestCamera();
      final micGranted = await PermissionHelper.requestMic();
      
      if (!cameraGranted || !micGranted) {
        _enableSimulatedCall('Quyền truy cập máy ảnh hoặc micro bị từ chối. Chuyển sang cuộc gọi giả lập.');
        return;
      }

      // 2. Initialize Agora Engine
      final engine = createAgoraRtcEngine();
      await engine.initialize(const RtcEngineContext(
        appId: 'YOUR_AGORA_APP_ID',
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // 3. Register Event Handlers
      engine.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _isJoined = true;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUid = null;
          });
          _endCall();
        },
      ));

      // 4. Enable Video
      await engine.enableVideo();
      await engine.startPreview();

      // 5. Join Channel
      await engine.joinChannel(
        token: widget.token.isEmpty ? 'TEMP_TOKEN' : widget.token,
        channelId: widget.channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      setState(() {
        _engine = engine;
        _initFailed = false;
      });
    } catch (e) {
      debugPrint('Agora initialize failed, using simulation mode: $e');
      _enableSimulatedCall('Agora initialization failed: $e');
    }
  }

  void _enableSimulatedCall(String message) async {
    setState(() {
      _initFailed = true;
      _initErrorMessage = message;
    });

    // Start simulated ringtone
    try {
      await _player.setUrl('https://tiengdong.com/wp-content/uploads/Nhac-chuong-cuoc-goi-Messenger-www_tiengdong_com.mp3');
      await _player.setLoopMode(LoopMode.one);
      await _player.play();
    } catch (e) {
      debugPrint('Simulated ringtone error: $e');
    }

    // Connect call automatically after 6 seconds
    _simulatedConnectTimer = Timer(const Duration(seconds: 6), () {
      _connectSimulatedCall();
    });
  }

  void _connectSimulatedCall() async {
    try {
      await _player.stop();
    } catch (_) {}

    setState(() {
      _isCallConnected = true;
    });

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationSeconds++;
      });
    });
  }

  // Tắt/bật mic
  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(_isMuted);
    }
    setState(() {});
  }

  // Tắt/bật camera
  Future<void> _toggleCamera() async {
    _isCameraOff = !_isCameraOff;
    if (_engine != null) {
      await _engine!.muteLocalVideoStream(_isCameraOff);
    }
    setState(() {});
  }

  // Đổi camera trước/sau
  Future<void> _flipCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
    }
  }

  // Loa ngoài / tai nghe
  Future<void> _toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    if (_engine != null) {
      await _engine!.setEnableSpeakerphone(_isSpeakerOn);
    }
    setState(() {});
  }

  // Kết thúc cuộc gọi
  Future<void> _endCall() async {
    _simulatedConnectTimer?.cancel();
    _durationTimer?.cancel();
    try {
      await _player.stop();
    } catch (_) {}

    if (_engine != null) {
      await _engine!.leaveChannel();
      await _engine!.release();
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _simulatedConnectTimer?.cancel();
    _durationTimer?.cancel();
    _pulseController.dispose();
    _player.dispose();
    if (_engine != null) {
      _engine!.leaveChannel();
      _engine!.release();
    }
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return _buildSimulatedCallScreen();
    }

    if (_engine == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote Video View (Full screen)
          _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channelId),
                  ),
                )
              : _buildWaitingView(),

          // Local Video Preview (Picture in Picture card)
          if (_isJoined && !_isCameraOff)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: _flipCamera,
                child: Container(
                  width: 100,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30, width: 1),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Top Header Info
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _remoteUid != null ? 'Cuộc gọi đang kết nối' : 'Đang gọi...',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Call Controls Bottom bar
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: _buildControlsBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingView() {
    return Container(
      color: const Color(0xFF0F0F10),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundImage: widget.remoteAvatar != null ? NetworkImage(widget.remoteAvatar!) : null,
              child: widget.remoteAvatar == null
                  ? Text(widget.remoteUserName[0].toUpperCase(), style: const TextStyle(fontSize: 36))
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              widget.remoteUserName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đang kết nối...',
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlBtn(
          icon: _isMuted ? Icons.mic_off : Icons.mic,
          label: _isMuted ? 'Mở tiếng' : 'Tắt tiếng',
          active: _isMuted,
          onTap: _toggleMute,
        ),
        _buildControlBtn(
          icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
          label: _isCameraOff ? 'Bật cam' : 'Tắt cam',
          active: _isCameraOff,
          onTap: _toggleCamera,
        ),
        _buildControlBtn(
          icon: _isSpeakerOn ? Icons.volume_up : Icons.hearing,
          label: _isSpeakerOn ? 'Loa ngoài' : 'Tai nghe',
          active: false,
          onTap: _toggleSpeaker,
        ),
        _buildControlBtn(
          icon: Icons.flip_camera_ios,
          label: 'Đổi cam',
          active: false,
          onTap: _flipCamera,
        ),
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBtn({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active ? Colors.white30 : Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSimulatedCallScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      body: Stack(
        children: [
          // Caller Details Center
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isCallConnected)
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 112 + (40 * _pulseController.value),
                            height: 112 + (40 * _pulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0084FF).withValues(alpha: 0.15 * (1 - _pulseController.value)),
                            ),
                          ),
                          Container(
                            width: 112 + (80 * _pulseController.value),
                            height: 112 + (80 * _pulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0084FF).withValues(alpha: 0.05 * (1 - _pulseController.value)),
                            ),
                          ),
                          child!,
                        ],
                      );
                    },
                    child: _buildAvatarCircle(),
                  )
                else
                  _buildAvatarCircle(),

                const SizedBox(height: 24),
                Text(
                  widget.remoteUserName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  !_isCallConnected
                      ? 'Đang kết nối (Giả lập)...'
                      : _formatDuration(_callDurationSeconds),
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                if (_initErrorMessage != null) ...[
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _initErrorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Bottom Control Actions
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlBtn(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  label: _isMuted ? 'Mở mic' : 'Tắt mic',
                  active: _isMuted,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                _buildControlBtn(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  label: _isCameraOff ? 'Bật cam' : 'Tắt cam',
                  active: _isCameraOff,
                  onTap: () => setState(() => _isCameraOff = !_isCameraOff),
                ),
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle() {
    return CircleAvatar(
      radius: 56,
      backgroundColor: const Color(0xFF333333),
      backgroundImage: widget.remoteAvatar != null ? NetworkImage(widget.remoteAvatar!) : null,
      child: widget.remoteAvatar == null
          ? Text(
              widget.remoteUserName[0].toUpperCase(),
              style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}
