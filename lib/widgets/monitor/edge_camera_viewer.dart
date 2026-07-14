import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:provider/provider.dart';

import '../../models/camera_config.dart';
import '../../providers/camera_provider.dart';
import '../../providers/monitor_provider.dart';
import '../../services/frame_capture_service.dart';
import '../../services/vitals_ocr_service.dart';
import '../../services/vlm_server_manager.dart';
import '../../services/vlm_vitals_service.dart';
import '../../utils/app_theme.dart';

class EdgeCameraViewer extends StatefulWidget {
  final String patientId;
  final String patientName;

  const EdgeCameraViewer({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<EdgeCameraViewer> createState() => _EdgeCameraViewerState();
}

class _EdgeCameraViewerState extends State<EdgeCameraViewer> {
  late final Player _player;
  late final VideoController _controller;
  CameraConfig? _camera;
  String? _error;
  bool _playing = false;
  bool _timedOut = false;
  bool _muted = false;

  final _frameCapture = FrameCaptureService();
  final _ocr = VitalsOcrService();
  final _vlm = VlmVitalsService();
  bool _vlmOnline = false;
  Timer? _vlmHealthTimer;
  String? _ocrStatus; // last reader result line shown in overlay

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);

    _player.stream.playing.listen((v) {
      if (mounted) setState(() => _playing = v);
    });
    _player.stream.error.listen((e) {
      if (mounted && e.isNotEmpty) setState(() => _error = e);
    });

    _findCameraAndStart();
  }

  void _findCameraAndStart() {
    final cameras = context.read<CameraProvider>().cameras;
    var match = cameras.where((c) => c.patientId == widget.patientId && c.isEnabled);
    if (match.isEmpty) {
      match = cameras.where((c) => c.patientName == widget.patientName && c.isEnabled);
    }
    if (match.isNotEmpty) {
      _camera = match.first;
      _player.open(Media(_camera!.rtspUrl));
      _scheduleTimeout();
      _startOcr();
    }
  }

  void _startOcr() {
    _frameCapture.startPeriodicCapture(
      _camera!,
      interval: const Duration(seconds: 8),
    );
    _frameCapture.frameNotifier.addListener(_onNewFrame);

    // Boot the embedded AI engine if it isn't up yet, then prefer it over
    // regex OCR; re-probe periodically so engine restarts just work.
    VlmServerManager.instance.ensureRunning();
    _checkVlmHealth();
    _vlmHealthTimer = Timer.periodic(
        const Duration(seconds: 45), (_) => _checkVlmHealth());
  }

  Future<void> _checkVlmHealth() async {
    final ok = await _vlm.isAvailable();
    if (mounted && ok != _vlmOnline) setState(() => _vlmOnline = ok);
  }

  Future<void> _onNewFrame() async {
    final raw = _frameCapture.frameNotifier.value;
    if (raw == null) return;
    final path = raw.split('?').first;
    final file = File(path);
    if (!file.existsSync()) return;

    // ── Primary: local VLM (reads any monitor brand, alarm-limit aware).
    // One read can take minutes on CPU — skip frames while it works.
    if (_vlmOnline) {
      if (_vlm.isBusy) return;
      setState(() => _ocrStatus = 'AI reading frame…');
      final vlm = await _vlm.processFile(file);
      if (!mounted) return;
      if (vlm != null && vlm.hasAnyVital) {
        context
            .read<MonitorProvider>()
            .injectOcrVitals(widget.patientId, vlm.toVitalMap());
        setState(() => _ocrStatus = 'AI  $vlm');
        return;
      }
      // Read failed (server gone? unreadable frame?) — re-probe and fall
      // through to the regex OCR so vitals keep flowing.
      unawaited(_checkVlmHealth());
    }

    // ── Fallback: on-device text recognition + regex parsing.
    final parsed = await _ocr.processFile(file);
    if (parsed == null || !parsed.hasAnyVital) return;

    if (!mounted) return;
    context.read<MonitorProvider>().injectOcrVitals(widget.patientId, parsed.toVitalMap());
    setState(() => _ocrStatus = 'OCR  $parsed');
  }

  void _scheduleTimeout() {
    Future.delayed(const Duration(seconds: 20), () {
      if (!mounted || _playing) return;
      setState(() => _timedOut = true);
    });
  }

  void _retry() {
    if (_camera == null) return;
    setState(() { _error = null; _playing = false; _timedOut = false; });
    _player.open(Media(_camera!.rtspUrl));
    _scheduleTimeout();
  }

  @override
  void dispose() {
    _vlmHealthTimer?.cancel();
    _frameCapture.frameNotifier.removeListener(_onNewFrame);
    _frameCapture.dispose();
    _ocr.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_camera == null) return _placeholder('No Edge camera assigned');

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live video — always in the stack; hidden by overlays when not ready
            Video(controller: _controller, controls: NoVideoControls),

            // ROI rectangles over the live feed
            if (_camera!.hasRoi) CustomPaint(painter: _RoiOverlayPainter(_camera!.roi)),

            // Mute button
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() => _muted = !_muted);
                  _player.setVolume(_muted ? 0 : 100);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _muted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ),

            // LIVE badge
            Positioned(
              top: 12, left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('LIVE', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ]),
              ),
            ),

            // AI badge — shown while the local VLM server is reachable
            if (_vlmOnline)
              Positioned(
                top: 12, left: 72,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome, color: Colors.white, size: 11),
                    const SizedBox(width: 4),
                    Text('AI', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),

            // Patient info + OCR status
            Positioned(
              bottom: 12, left: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.patientName, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('${_camera!.brand} · ${_camera!.ip}', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10)),
                  if (_ocrStatus != null) ...[
                    const SizedBox(height: 2),
                    Text(_ocrStatus!, style: GoogleFonts.dmSans(color: Colors.tealAccent.withValues(alpha: 0.7), fontSize: 9)),
                  ],
                ],
              ),
            ),

            // Error overlay (covers video)
            if (_error != null)
              _errorOverlay(
                icon: Icons.videocam_off,
                title: 'Stream error',
                detail: _error!.length > 120 ? '${_error!.substring(0, 120)}…' : _error!,
              ),

            // Timeout overlay
            if (_timedOut && !_playing && _error == null)
              _errorOverlay(
                icon: Icons.wifi_off,
                title: 'Cannot reach camera',
                detail: 'Check: camera ON, same network, RTSP enabled\nClose other apps using this stream (VLC, IPCam)',
              ),

            // Loading overlay (waiting for first frame)
            if (!_playing && _error == null && !_timedOut)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white30, strokeWidth: 2),
                    ),
                    const SizedBox(height: 10),
                    Text('Connecting to ${_camera!.brand}…', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(_camera!.ip, style: GoogleFonts.dmSans(color: Colors.white24, fontSize: 11)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _errorOverlay({required IconData icon, required String title, required String detail}) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.orange.shade300, size: 36),
              const SizedBox(height: 10),
              Text(title, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(detail, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white54),
                label: Text('Retry', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String message) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.videocam_off, color: Colors.white30, size: 32),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _RoiOverlayPainter extends CustomPainter {
  final Map<dynamic, RoiRect> roi;
  _RoiOverlayPainter(this.roi);

  static const _colors = {
    'hr': Colors.red,
    'spo2': Colors.blue,
    'rr': Colors.green,
    'sbp': Colors.purple,
    'dbp': Colors.purple,
  };

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in roi.entries) {
      final r = entry.value;
      final color = _colors[entry.key.toString().split('.').last] ?? Colors.amber;
      final fill = Paint()..color = color.withValues(alpha: 0.25)..style = PaintingStyle.fill;
      final border = Paint()..color = color.withValues(alpha: 0.7)..style = PaintingStyle.stroke..strokeWidth = 1.5;
      final rect = Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    }
  }

  @override
  bool shouldRepaint(covariant _RoiOverlayPainter old) => true;
}
