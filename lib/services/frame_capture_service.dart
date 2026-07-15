import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/camera_config.dart';

class FrameCaptureService {
  Timer? _timer;
  bool _capturing = false;
  String? _lastFramePath;
  final ValueNotifier<String?> frameNotifier = ValueNotifier(null);
  final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  bool get isRunning => _timer != null;

  String _framesDir() {
    final dir = Directory('${Directory.systemTemp.path}/wardly_edge_frames');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  Future<String?> captureFrame(CameraConfig camera) async {
    if (_capturing) return _lastFramePath;
    _capturing = true;
    errorNotifier.value = null;

    try {
      final dir = _framesDir();
      final outPath = '$dir/${camera.id}.jpg';
      final ffmpeg = Platform.isMacOS ? '/usr/local/bin/ffmpeg' : 'ffmpeg';

      // Webcam test phase: grab from the built-in camera (avfoundation
      // device 0) instead of an RTSP stream.
      final args = camera.isWebcam
          ? [
              '-f', 'avfoundation',
              '-framerate', '30',
              '-i', '0',
              '-frames:v', '1',
              '-update', '1',
              '-y',
              outPath,
            ]
          : [
              '-rtsp_transport', 'tcp',
              '-i', camera.rtspUrl,
              '-frames:v', '1',
              '-update', '1',
              '-y',
              outPath,
            ];

      final process = await Process.start(ffmpeg, args);

      final stderrBuf = StringBuffer();
      process.stderr.transform(utf8.decoder).listen((s) => stderrBuf.write(s));

      // Hard kill after 15s — prevents infinite hang
      final killer = Timer(const Duration(seconds: 15), () => process.kill());
      final exitCode = await process.exitCode;
      killer.cancel();

      if (exitCode == 0 && File(outPath).existsSync()) {
        _lastFramePath = outPath;
        frameNotifier.value = '$outPath?t=${DateTime.now().millisecondsSinceEpoch}';
        return outPath;
      } else {
        final lines = stderrBuf.toString().trim().split('\n');
        final lastMeaningful = lines.lastWhere(
          (l) => l.isNotEmpty && !l.startsWith('ffmpeg version') && !l.startsWith('built'),
          orElse: () => 'ffmpeg failed (exit $exitCode)',
        );
        errorNotifier.value = lastMeaningful;
        return null;
      }
    } catch (e) {
      errorNotifier.value = e.toString();
      return null;
    } finally {
      _capturing = false;
    }
  }

  void startPeriodicCapture(CameraConfig camera, {Duration interval = const Duration(seconds: 1)}) {
    stop();
    captureFrame(camera);
    _timer = Timer.periodic(interval, (_) => captureFrame(camera));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    frameNotifier.dispose();
    errorNotifier.dispose();
  }
}
