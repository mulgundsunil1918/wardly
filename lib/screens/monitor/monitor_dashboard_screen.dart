import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/monitor_vitals.dart';
import '../../models/monitored_patient.dart';
import '../../providers/monitor_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/support_action.dart';
import '../subscription/paywall_screen.dart';
import 'patient_monitor_screen.dart';

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
