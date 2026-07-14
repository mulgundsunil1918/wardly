import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/camera_config.dart';
import '../../models/monitor_vitals.dart';
import '../../providers/camera_provider.dart';
import '../../services/patient_service.dart';
import '../../utils/app_theme.dart';
import 'edge_setup_screen.dart';
import 'roi_editor_screen.dart';

// ─────────────────────────────────────────────
//  Wardly Edge Hub
//  Manage all configured cameras — add, edit,
//  toggle, define ROI, delete.
// ─────────────────────────────────────────────

class WardlyEdgeScreen extends StatelessWidget {
  const WardlyEdgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cameras = context.watch<CameraProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        title: Row(
          children: [
            const Icon(Icons.settings_input_antenna, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Wardly Edge',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 18)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _openSetup(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Camera'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
      body: cameras.cameras.isEmpty
          ? _emptyState(context)
          : _cameraList(context, cameras),
      floatingActionButton: cameras.cameras.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'edge_add_camera',
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Add Camera'),
              onPressed: () => _openSetup(context),
            )
          : null,
    );
  }

  void _openSetup(BuildContext context) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const EdgeSetupScreen()));
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.videocam_off_outlined,
                  color: AppColors.primary, size: 38),
            ),
            const SizedBox(height: 20),
            Text('No cameras configured',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Connect an IP CCTV camera to automatically read '
              'vitals from your bedside monitors.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openSetup(context),
                icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                label: Text('Set Up First Camera',
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _HowItWorksCard(),
          ],
        ),
      ),
    );
  }

  Widget _cameraList(BuildContext context, CameraProvider cameras) {
    final list = cameras.cameras;
    return CustomScrollView(
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: _StatsHeader(cameras: cameras),
        ),

        // How it works (collapsed)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _HowItWorksCard(collapsed: true),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _CameraCard(camera: list[i]),
              childCount: list.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ─── Stats Header ─────────────────────────────

class _StatsHeader extends StatelessWidget {
  final CameraProvider cameras;
  const _StatsHeader({required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A5C8A), Color(0xFF0E7C5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _chip('${cameras.cameras.length}', 'Total'),
          _chip('${cameras.activeCount}', 'Active'),
          _chip('${cameras.withRoiCount}', 'ROI Set'),
          _chip('${cameras.cameras.length - cameras.withRoiCount}', 'ROI Needed'),
        ],
      ),
    );
  }

  Widget _chip(String num, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(num,
              style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─── Camera Card ──────────────────────────────

class _CameraCard extends StatelessWidget {
  final CameraConfig camera;
  const _CameraCard({required this.camera});

  @override
  Widget build(BuildContext context) {
    final cp = context.read<CameraProvider>();
    final color = camera.isEnabled ? AppColors.stable : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // Main info row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Camera icon with brand color
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: (camera.isEnabled ? AppColors.primary : AppColors.textSecondary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.videocam_outlined,
                    color: camera.isEnabled ? AppColors.primary : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              camera.label.isEmpty ? 'Unnamed Camera' : camera.label,
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 14),
                            ),
                          ),
                          _statusPill(camera.isEnabled),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${camera.brand} · ${camera.ip}:${camera.port}',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                      if (camera.patientName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(camera.patientName,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                            if (camera.bedLabel.isNotEmpty) ...[
                              Text(' · ${camera.bedLabel}',
                                  style: GoogleFonts.dmSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 11)),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ROI zones row
          _roiZonesRow(context, camera, cp),

          // Actions row
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _actionBtn(
                  context,
                  icon: Icons.crop_free,
                  label: camera.hasRoi ? 'Edit Zones' : 'Define Zones',
                  color: camera.hasRoi ? AppColors.stable : AppColors.warningColor,
                  onTap: () => _openRoiEditor(context, camera, cp),
                ),
                _divider(),
                _actionBtn(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  color: AppColors.primary,
                  onTap: () => _openEdit(context, camera, cp),
                ),
                _divider(),
                _actionBtn(
                  context,
                  icon: Icons.cast_outlined,
                  label: 'Remote',
                  color: const Color(0xFF7B1FA2),
                  onTap: () => _setRemoteUrl(context, camera),
                ),
                _divider(),
                _actionBtn(
                  context,
                  icon: camera.isEnabled ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  label: camera.isEnabled ? 'Pause' : 'Enable',
                  color: AppColors.textSecondary,
                  onTap: () => cp.toggleEnabled(camera.id),
                ),
                _divider(),
                _actionBtn(
                  context,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  color: AppColors.danger,
                  onTap: () => _confirmDelete(context, camera, cp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roiZonesRow(BuildContext context, CameraConfig cam, CameraProvider cp) {
    if (!cam.hasRoi) {
      return GestureDetector(
        onTap: () => _openRoiEditor(context, cam, cp),
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.warningColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.warningColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_outlined,
                  size: 14, color: AppColors.warningColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No vital zones defined — tap to draw zones for auto-reading',
                  style: GoogleFonts.dmSans(
                      color: AppColors.warningColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.warningColor),
            ],
          ),
        ),
      );
    }

    const vitalColors = {
      VitalType.hr:   Color(0xFFE53935),
      VitalType.spo2: Color(0xFF1976D2),
      VitalType.rr:   Color(0xFF388E3C),
      VitalType.sbp:  Color(0xFF7B1FA2),
    };
    const vitalLabels = {
      VitalType.hr:   'HR',
      VitalType.spo2: 'SpO₂',
      VitalType.rr:   'RR',
      VitalType.sbp:  'BP',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Row(
        children: [
          Icon(Icons.crop_free, size: 13, color: AppColors.stable),
          const SizedBox(width: 6),
          Text('Zones: ',
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 11)),
          Expanded(
            child: Wrap(
              spacing: 4,
              children: [
                VitalType.hr, VitalType.spo2, VitalType.rr, VitalType.sbp,
              ].map((vt) {
                final defined = cam.roi.containsKey(vt);
                final color = vitalColors[vt]!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: defined ? color.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: defined ? color : AppColors.divider),
                  ),
                  child: Text(
                    vitalLabels[vt]!,
                    style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: defined ? color : AppColors.textSecondary,
                        fontWeight:
                            defined ? FontWeight.w700 : FontWeight.w400),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (enabled ? AppColors.stable : AppColors.textSecondary)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: enabled ? AppColors.stable : AppColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            enabled ? 'Active' : 'Paused',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: enabled ? AppColors.stable : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 3),
              Text(label,
                  style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: AppColors.divider);

  Future<void> _setRemoteUrl(BuildContext context, CameraConfig cam) async {
    if (cam.patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assign this camera to a patient first (Edit → patient).')),
      );
      return;
    }
    final ctrl = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remote Stream URL',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste the HLS URL from your Cloudflare tunnel + MediaMTX.\n\n'
              'Format: https://your-tunnel.trycloudflare.com/stream/index.m3u8',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              style: GoogleFonts.dmSans(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://…/stream/index.m3u8',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text('Clear URL', style: TextStyle(color: AppColors.danger)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (url == null) return;
    try {
      await PatientService().saveHlsUrl(cam.patientId, url);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(url.isEmpty ? 'Remote URL cleared.' : 'Remote stream URL saved.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _openRoiEditor(BuildContext context, CameraConfig cam, CameraProvider cp) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoiEditorScreen(
          camera: cam,
          onSave: (updates) => cp.saveRoi(cam.id, updates),
        ),
      ),
    );
  }

  void _openEdit(BuildContext context, CameraConfig cam, CameraProvider cp) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => _EditCameraSheet(camera: cam, onSave: cp.update)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CameraConfig cam, CameraProvider cp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete camera?',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text(
            'This will remove "${cam.label.isEmpty ? "Unnamed Camera" : cam.label}" '
            'and all its zone definitions.',
            style: GoogleFonts.dmSans()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) cp.remove(cam.id);
  }
}

// ─── Edit Camera Sheet ────────────────────────

class _EditCameraSheet extends StatefulWidget {
  final CameraConfig camera;
  final void Function(CameraConfig) onSave;
  const _EditCameraSheet({required this.camera, required this.onSave});

  @override
  State<_EditCameraSheet> createState() => _EditCameraSheetState();
}

class _EditCameraSheetState extends State<_EditCameraSheet> {
  late final TextEditingController _label;
  late final TextEditingController _ip;
  late final TextEditingController _port;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _bed;
  bool _passVisible = false;

  @override
  void initState() {
    super.initState();
    final c = widget.camera;
    _label = TextEditingController(text: c.label);
    _ip = TextEditingController(text: c.ip);
    _port = TextEditingController(text: '${c.port}');
    _user = TextEditingController(text: c.username);
    _pass = TextEditingController(text: c.password);
    _bed = TextEditingController(text: c.bedLabel);
  }

  @override
  void dispose() {
    for (final c in [_label, _ip, _port, _user, _pass, _bed]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        title: Text('Edit Camera',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('Save',
                style: GoogleFonts.dmSans(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _field('Camera Label', _label, Icons.label_outline),
            const SizedBox(height: 12),
            _field('IP Address', _ip, Icons.router_outlined,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('Port', _port, Icons.settings_ethernet,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('Username', _user, Icons.person_outline),
            const SizedBox(height: 12),
            TextField(
              controller: _pass,
              obscureText: !_passVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_passVisible ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _passVisible = !_passVisible),
                ),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            _field('Bed / Location', _bed, Icons.bed_outlined),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.dmSans(color: AppColors.textSecondary),
      ),
    );
  }

  void _save() {
    widget.onSave(widget.camera.copyWith(
      label: _label.text.trim(),
      ip: _ip.text.trim(),
      port: int.tryParse(_port.text.trim()) ?? 554,
      username: _user.text.trim(),
      password: _pass.text,
      bedLabel: _bed.text.trim(),
    ));
    Navigator.pop(context);
  }
}

// ─── How It Works Card ─────────────────────────

class _HowItWorksCard extends StatefulWidget {
  final bool collapsed;
  const _HowItWorksCard({this.collapsed = false});

  @override
  State<_HowItWorksCard> createState() => _HowItWorksCardState();
}

class _HowItWorksCardState extends State<_HowItWorksCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.collapsed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('How Wardly Edge works',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontSize: 13)),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _step(Icons.videocam_outlined, 'Camera captures',
                      'CCTV camera streams RTSP video of the bedside monitor screen'),
                  _step(Icons.crop_free, 'Zones define where',
                      'You draw boxes around each vital number on the monitor screen'),
                  _step(Icons.computer, 'Edge PC processes',
                      'This PC (Wardly Edge) captures a frame every 30 seconds, crops the zones'),
                  _step(Icons.cloud_upload_outlined, 'Cloud reads the numbers',
                      'Cropped images go to Cloud Vision API → extracts vital values'),
                  _step(Icons.monitor_heart_outlined, 'Wardly shows results',
                      'Values appear in your Monitor dashboard — no manual charting needed'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _step(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 12)),
                Text(body,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
