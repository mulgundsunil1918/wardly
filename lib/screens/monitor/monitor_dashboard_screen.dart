import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/monitor_vitals.dart';
import '../../models/monitored_patient.dart';
import '../../providers/camera_provider.dart';
import '../../providers/monitor_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/support_action.dart';
import '../subscription/paywall_screen.dart';
import 'bedside_sender_screen.dart';
import 'edge_setup_screen.dart';
import 'patient_monitor_screen.dart';
import 'wardly_edge_screen.dart';

class MonitorDashboardScreen extends StatelessWidget {
  const MonitorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    if (!sub.isPro) {
      return _lockedState(context);
    }

    return _dashboard(context);
  }

  Widget _lockedState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Monitor', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800)),
        actions: const [SupportAppBarAction()],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.monitor_heart, color: AppColors.primary, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                'Live Patient Monitoring',
                style: GoogleFonts.dmSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Watch your patients\' vitals in real time.\nGet alerted when thresholds are breached.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  ),
                  icon: const Icon(Icons.star, size: 20),
                  label: const Text('Upgrade to Wardly Pro'),
                  style: ElevatedButton.styleFrom(
                    textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboard(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    context.watch<ThemeProvider>();
    final patients = monitor.patients;
    final critCount = patients.where((p) => p.worstSeverity == 'critical').length;
    final warnCount = patients.where((p) => p.worstSeverity == 'warning').length;
    final stableCount = patients.where((p) => p.worstSeverity == 'stable').length;
    final critAlerts = monitor.alerts.where((a) => a.severity == 'critical').length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bedside_cam_fab',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.videocam),
        label: const Text('Bedside Camera'),
        onPressed: () => _showBedsideSetup(context, patients),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.appBarBg,
            title: Row(
              children: [
                Text('Monitor', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('PRO', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.accent)),
                ),
              ],
            ),
            actions: [
              if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS ||
                  defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.linux))
                IconButton(
                  icon: const Icon(Icons.settings_input_antenna, size: 22),
                  color: AppColors.textSecondary,
                  tooltip: 'Wardly Edge',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WardlyEdgeScreen())),
                ),
              Stack(
                children: [
                  IconButton(icon: Icon(Icons.notifications_outlined, color: AppColors.textSecondary), onPressed: () {}),
                  if (critAlerts > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        child: Text('$critAlerts', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
              const SupportAppBarAction(),
            ],
          ),

          // Demo / dev mode disclaimer
          const SliverToBoxAdapter(child: _MonitorDevBanner()),

          // Stats row
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                  _statChip('${patients.length}', 'Patients', Colors.white),
                  if (critCount > 0) _statChip('$critCount', 'Critical', AppColors.danger),
                  if (warnCount > 0) _statChip('$warnCount', 'Watch', AppColors.warning),
                  _statChip('$stableCount', 'Stable', AppColors.accent),
                ],
              ),
            ),
          ),

          // Edge cameras section (desktop only)
          if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.windows ||
              defaultTargetPlatform == TargetPlatform.linux))
            SliverToBoxAdapter(
              child: _EdgeSection(context: context),
            ),

          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Monitored Patients', style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),

          // Patient cards
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _patientCard(context, patients[index], monitor),
                childCount: patients.length,
              ),
            ),
          ),

          // Recent Alerts
          if (monitor.alerts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active, size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Text('Recent Alerts', style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${monitor.alerts.length}', style: GoogleFonts.dmSans(
                        color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final alert = monitor.alerts[index];
                    final patient = monitor.patientById(alert.patientId);
                    final isCrit = alert.severity == 'critical';
                    final ago = DateTime.now().difference(alert.time);
                    final timeStr = ago.inMinutes < 1 ? 'now' : ago.inMinutes < 60 ? '${ago.inMinutes}m ago' : '${ago.inHours}h ago';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: (isCrit ? AppColors.danger : AppColors.warning).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: (isCrit ? AppColors.danger : AppColors.warning).withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber, size: 16, color: isCrit ? AppColors.danger : AppColors.warning),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(alert.message, style: GoogleFonts.dmSans(
                                  color: isCrit ? AppColors.danger : AppColors.warning,
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                                if (patient != null)
                                  Text('${patient.name} · ${patient.bed}', style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text(timeStr, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10)),
                        ],
                      ),
                    );
                  },
                  childCount: monitor.alerts.length > 8 ? 8 : monitor.alerts.length,
                ),
              ),
            ),
          ],

          // Latest Orders & Notes
          if (monitor.comments.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.assignment, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Latest Orders & Notes', style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final comment = monitor.comments[index];
                    final patient = monitor.patientById(comment.patientId);
                    final isOrder = comment.type == 'order';
                    final ago = DateTime.now().difference(comment.time);
                    final timeStr = ago.inMinutes < 60 ? '${ago.inMinutes}m ago' : '${ago.inHours}h ago';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOrder ? AppColors.primary.withOpacity(0.12) : AppColors.accent.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(isOrder ? 'Order' : 'Note', style: GoogleFonts.dmSans(
                                  color: isOrder ? AppColors.primary : AppColors.accent,
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                              ),
                              if (patient != null) ...[
                                const SizedBox(width: 8),
                                Text(patient.name, style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                              const Spacer(),
                              Text(timeStr, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(comment.text, style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary, fontSize: 13, height: 1.4)),
                          const SizedBox(height: 4),
                          Text(comment.author, style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    );
                  },
                  childCount: monitor.comments.length > 6 ? 6 : monitor.comments.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _statChip(String num, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(num, style: GoogleFonts.dmSans(color: color == Colors.white ? Colors.white : color, fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _patientCard(BuildContext context, MonitoredPatient p, MonitorProvider monitor) {
    final sev = p.worstSeverity;
    final sevColor = sev == 'critical' ? AppColors.danger : sev == 'warning' ? AppColors.warning : AppColors.accent;
    final alerts = monitor.alertsFor(p.id);
    final lastAlert = alerts.isNotEmpty ? alerts.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PatientMonitorScreen(patientId: p.id))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: sevColor, width: 4)),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('${p.gender} · ${p.age} · ${p.ward}', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: sevColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    sev == 'critical' ? 'Critical' : sev == 'warning' ? 'Watch' : 'Stable',
                    style: GoogleFonts.dmSans(color: sevColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${p.diagnosis} · ${p.support} · ${p.bed}', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
            const SizedBox(height: 10),
            Row(
              children: [
                _miniVital('HR', p.vitals[VitalType.hr]?.round().toString() ?? '-', p.thresholds[VitalType.hr]?.severity(p.vitals[VitalType.hr] ?? 0) ?? 'stable'),
                _miniVital('SpO₂', '${p.vitals[VitalType.spo2]?.round() ?? '-'}%', p.thresholds[VitalType.spo2]?.severity(p.vitals[VitalType.spo2] ?? 0) ?? 'stable'),
                _miniVital('RR', p.vitals[VitalType.rr]?.round().toString() ?? '-', p.thresholds[VitalType.rr]?.severity(p.vitals[VitalType.rr] ?? 0) ?? 'stable'),
                _miniVitalBP(p),
              ],
            ),
            if (lastAlert != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.warning_amber, size: 12, color: lastAlert.severity == 'critical' ? AppColors.danger : AppColors.warning),
                  const SizedBox(width: 4),
                  Expanded(child: Text(lastAlert.message, style: GoogleFonts.dmSans(color: lastAlert.severity == 'critical' ? AppColors.danger : AppColors.warning, fontSize: 11), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text('Tap to monitor →', style: GoogleFonts.dmSans(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _miniVital(String label, String value, String sev) {
    final color = sev == 'critical' ? AppColors.danger : sev == 'warning' ? AppColors.warning : AppColors.textPrimary;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.dmSans(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _showBedsideSetup(BuildContext context, List<MonitoredPatient> patients) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set up bedside camera', style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Select a patient to start streaming vitals from their bedside monitor.',
              style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            ...patients.map((p) => ListTile(
              leading: Icon(Icons.person, color: AppColors.primary),
              title: Text(p.name, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.ward} · ${p.bed}', style: GoogleFonts.dmSans(fontSize: 12)),
              trailing: const Icon(Icons.videocam, color: AppColors.accent),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BedsideSenderScreen(
                    patientId: p.id,
                    patientName: p.name,
                    wardId: p.wardId,
                  ),
                ));
              },
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _miniVitalBP(MonitoredPatient p) {
    final sbp = p.vitals[VitalType.sbp]?.round() ?? 0;
    final dbp = p.vitals[VitalType.dbp]?.round() ?? 0;
    final map = p.vitals[VitalType.map]?.round() ?? 0;
    String bpSev = 'stable';
    for (final vt in [VitalType.sbp, VitalType.dbp, VitalType.map]) {
      final s = p.thresholds[vt]?.severity(p.vitals[vt] ?? 0) ?? 'stable';
      if (s == 'critical') { bpSev = 'critical'; break; }
      if (s == 'warning') bpSev = 'warning';
    }
    final color = bpSev == 'critical' ? AppColors.danger : bpSev == 'warning' ? AppColors.warning : AppColors.textPrimary;
    return Expanded(
      child: Column(
        children: [
          Text('BP', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('$sbp/$dbp', style: GoogleFonts.dmSans(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
          Text('MAP $map', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }
}

// ─── Edge Section (provider-aware) ───────────

class _EdgeSection extends StatelessWidget {
  final BuildContext context;
  const _EdgeSection({required this.context});

  @override
  Widget build(BuildContext ctx) {
    final cameras = ctx.watch<CameraProvider>();
    final hasAny = cameras.hasAny;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const WardlyEdgeScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              const Color(0xFF0E7C5F).withValues(alpha: 0.06)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.settings_input_antenna,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wardly Edge',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                  Text(
                    hasAny
                        ? '${cameras.cameras.length} camera${cameras.cameras.length > 1 ? 's' : ''} · '
                          '${cameras.activeCount} active · ${cameras.withRoiCount} with zones'
                        : 'No cameras yet — tap to connect your first CCTV camera',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hasAny ? AppColors.surface : AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                border: hasAny
                    ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
                    : null,
              ),
              child: Text(
                hasAny ? 'Manage' : 'Setup',
                style: GoogleFonts.dmSans(
                    color: hasAny ? AppColors.primary : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitorDevBanner extends StatefulWidget {
  const _MonitorDevBanner();

  @override
  State<_MonitorDevBanner> createState() => _MonitorDevBannerState();
}

class _MonitorDevBannerState extends State<_MonitorDevBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFFB71C1C),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DEMO / DEVELOPMENT MODE',
                      style: GoogleFonts.dmSans(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  const SizedBox(height: 2),
                  Text(
                    'Vitals shown are simulated. Do NOT use for real clinical decisions.',
                    style: GoogleFonts.dmSans(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _dismissed = true),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
