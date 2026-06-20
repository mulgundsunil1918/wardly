import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/video_call_service.dart';
import '../../utils/app_theme.dart';

class RemoteVideoViewer extends StatefulWidget {
  final String patientId;
  final String patientName;
  final String ward;
  final String bed;

  const RemoteVideoViewer({
    super.key,
    required this.patientId,
    required this.patientName,
    required this.ward,
    required this.bed,
  });

  @override
  State<RemoteVideoViewer> createState() => _RemoteVideoViewerState();
}

class _RemoteVideoViewerState extends State<RemoteVideoViewer> {
  final VideoCallService _video = VideoCallService();
  bool _connecting = false;
  bool _connected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _video.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);

    _video.onRemoteJoined = () {
      if (mounted) setState(() => _connected = true);
    };
    _video.onRemoteLeft = () {
      if (mounted) setState(() => _connected = false);
    };
    _video.onError = () {
      if (mounted) setState(() => _error = 'Stream error');
    };

    final ok = await _video.initialize();
    if (!ok) {
      if (mounted) setState(() { _connecting = false; _error = 'Camera permission required'; });
      return;
    }

    final channel = VideoCallService.channelForPatient(widget.patientId);
    await _video.joinAsViewer(channel);
    if (mounted) setState(() => _connecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (_connected && _video.remoteUid != null && _video.engine != null)
              AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: _video.engine!,
                  canvas: VideoCanvas(uid: _video.remoteUid!),
                  connection: RtcConnection(
                    channelId: VideoCallService.channelForPatient(widget.patientId),
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_connecting)
                      const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white30, strokeWidth: 2),
                      )
                    else if (_error != null) ...[
                      const Icon(Icons.error_outline, color: Colors.white30, size: 32),
                      const SizedBox(height: 8),
                      Text(_error!, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
                    ] else ...[
                      const Icon(Icons.videocam, color: Colors.white30, size: 40),
                      const SizedBox(height: 8),
                      Text('${widget.ward} Camera · ${widget.bed}',
                          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
                      Text('Waiting for bedside stream...',
                          style: GoogleFonts.dmSans(color: Colors.white30, fontSize: 11)),
                    ],
                  ],
                ),
              ),
            // LIVE badge
            if (_connected)
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('LIVE', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            // Patient info
            Positioned(
              bottom: 12, left: 12,
              child: Text(widget.patientName,
                  style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
