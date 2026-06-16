import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';

import '../../models/monitor_vitals.dart';
import '../../models/monitored_patient.dart';
import '../../providers/monitor_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';

class PatientMonitorScreen extends StatelessWidget {
  final String patientId;
  const PatientMonitorScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    context.watch<ThemeProvider>();
    final patient = monitor.patientById(patientId);

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient not found')),
        body: const Center(child: Text('Patient not found')),
      );
    }

    final sev = patient.worstSeverity;
    final sevColor = sev == 'critical' ? AppColors.danger : sev == 'warning' ? AppColors.warning : AppColors.accent;
    final alerts = monitor.alertsFor(patientId);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Monitor', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: AppColors.primary)),
        actions: [
          TextButton.icon(
            onPressed: () => monitor.toggleSound(),
            icon: Icon(monitor.soundEnabled ? Icons.volume_up : Icons.volume_off, size: 18,
              color: monitor.soundEnabled ? AppColors.primary : AppColors.textSecondary),
            label: Text(monitor.soundEnabled ? 'Sound ON' : 'Sound OFF',
              style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                color: monitor.soundEnabled ? AppColors.primary : AppColors.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => _callWard(patient.dutyPhone),
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Patient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.card,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${patient.name} · ${patient.gender} · ${patient.age}',
                        style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('${patient.diagnosis} · ${patient.support} · ${patient.bed} · ${patient.ward}',
                        style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
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
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Camera placeholder
                  _cameraPlaceholder(patient),
                  const SizedBox(height: 16),

                  // Vitals
                  Text('LIVE VITALS', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _vitalsGrid(patient),
                  const SizedBox(height: 16),

                  // Alerts
                  _alertLog(alerts),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cameraPlaceholder(MonitoredPatient patient) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam, color: Colors.white30, size: 40),
                const SizedBox(height: 8),
                Text('${patient.ward} Camera · ${patient.bed}',
                  style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
                Text('Stream connected · tap to expand',
                  style: GoogleFonts.dmSans(color: Colors.white30, fontSize: 11)),
              ],
            ),
          ),
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
              child: Text('LIVE', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vitalsGrid(MonitoredPatient patient) {
    return LayoutBuilder(builder: (context, constraints) {
      final crossCount = constraints.maxWidth > 500 ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
        children: [
          _vitalCard(VitalType.hr, patient),
          _vitalCard(VitalType.spo2, patient),
          _vitalCard(VitalType.rr, patient),
          _bpCard(patient),
        ],
      );
    });
  }

  Widget _vitalCard(VitalType type, MonitoredPatient patient) {
    final meta = vitalMeta[type]!;
    final val = patient.vitals[type] ?? 0;
    final thr = patient.thresholds[type] ?? const VitalThreshold();
    final sev = thr.severity(val);
    final color = sev == 'critical' ? AppColors.danger : sev == 'warning' ? AppColors.warning : AppColors.accent;
    final bg = sev == 'critical'
        ? AppColors.danger.withOpacity(0.08)
        : sev == 'warning'
            ? AppColors.warning.withOpacity(0.08)
            : AppColors.card;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(meta.icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(meta.label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
            ],
          ),
          const Spacer(),
          Text('${val.round()}', style: GoogleFonts.dmSans(color: color, fontSize: 32, fontWeight: FontWeight.w800)),
          Text(meta.unit, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(
              sev == 'critical' ? 'Critical' : sev == 'warning' ? 'Warning' : 'Normal',
              style: GoogleFonts.dmSans(color: color, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bpCard(MonitoredPatient patient) {
    final sbp = patient.vitals[VitalType.sbp]?.round() ?? 0;
    final dbp = patient.vitals[VitalType.dbp]?.round() ?? 0;
    final map = patient.vitals[VitalType.map]?.round() ?? 0;

    String worst = 'stable';
    for (final vt in [VitalType.sbp, VitalType.dbp, VitalType.map]) {
      final s = patient.thresholds[vt]?.severity(patient.vitals[vt] ?? 0) ?? 'stable';
      if (s == 'critical') { worst = 'critical'; break; }
      if (s == 'warning') worst = 'warning';
    }

    final color = worst == 'critical' ? AppColors.danger : worst == 'warning' ? AppColors.warning : AppColors.accent;
    final bg = worst == 'critical'
        ? AppColors.danger.withOpacity(0.08)
        : worst == 'warning'
            ? AppColors.warning.withOpacity(0.08)
            : AppColors.card;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_vert, size: 14, color: color),
              const SizedBox(width: 6),
              Text('Blood Pressure', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          RichText(text: TextSpan(children: [
            TextSpan(text: '$sbp', style: GoogleFonts.dmSans(color: color, fontSize: 28, fontWeight: FontWeight.w800)),
            TextSpan(text: '/$dbp', style: GoogleFonts.dmSans(color: color, fontSize: 22, fontWeight: FontWeight.w600)),
          ])),
          Text('MAP $map mmHg', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(
              worst == 'critical' ? 'Critical' : worst == 'warning' ? 'Warning' : 'Normal',
              style: GoogleFonts.dmSans(color: color, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertLog(List alerts) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final shown = alerts.take(10).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alert log', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
              Text('${alerts.length} total', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          ...shown.map((a) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: a.severity == 'critical' ? AppColors.danger : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(a.message, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 12))),
                Text(timeago.format(a.time), style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  void _callWard(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
