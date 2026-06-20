import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/monitor_vitals.dart';
import '../../models/monitored_patient.dart';
import '../../utils/app_theme.dart';

class ThresholdPanel extends StatefulWidget {
  final MonitoredPatient patient;
  final void Function(String patientId, VitalType vital, String key, double value) onSet;

  const ThresholdPanel({super.key, required this.patient, required this.onSet});

  @override
  State<ThresholdPanel> createState() => _ThresholdPanelState();
}

class _ThresholdPanelState extends State<ThresholdPanel> {
  String _tab = 'hr';

  static const _tabs = [
    {'key': 'hr', 'label': 'HR'},
    {'key': 'spo2', 'label': 'SpO₂'},
    {'key': 'rr', 'label': 'RR'},
    {'key': 'bp', 'label': 'BP'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alert thresholds', style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              Text('changes apply instantly', style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: _tabs.map((t) {
              final active = _tab == t['key'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tab = t['key']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      t['label']!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: active ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (_tab == 'bp') ...[
            _bpSection('SBP — systolic', VitalType.sbp),
            const SizedBox(height: 12),
            _bpSection('DBP — diastolic', VitalType.dbp),
            const SizedBox(height: 12),
            _bpSection('MAP — mean arterial', VitalType.map),
          ] else
            ..._rowsForVital(_vitalTypeFromTab(_tab)),
        ],
      ),
    );
  }

  Widget _bpSection(String title, VitalType vt) {
    final val = widget.patient.vitals[vt] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title · current: ${val.round()} mmHg',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        ..._buildThrRows(vt, widget.patient.thresholds[vt]),
      ],
    );
  }

  List<Widget> _rowsForVital(VitalType vt) {
    final meta = vitalMeta[vt]!;
    final val = widget.patient.vitals[vt] ?? 0;
    return [
      Text(
        '${meta.label} · current: ${val.round()} ${meta.unit}',
        style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12),
      ),
      const SizedBox(height: 8),
      ..._buildThrRows(vt, widget.patient.thresholds[vt]),
    ];
  }

  List<Widget> _buildThrRows(VitalType vt, VitalThreshold? thr) {
    if (thr == null) return [];
    final meta = vitalMeta[vt]!;
    final rows = <Widget>[];

    void addRow(String key, String label, String sev, double? val, double sliderMin, double sliderMax) {
      if (vt == VitalType.spo2 && (key == 'warnHigh' || key == 'critHigh')) return;
      final current = val ?? sliderMin;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
                  Text(
                    val != null ? '${key.contains('Low') ? '< ' : '> '}${val.round()}' : 'Off',
                    style: GoogleFonts.dmSans(
                      color: sev == 'critical' ? AppColors.critical : AppColors.warningColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  activeTrackColor: sev == 'critical' ? AppColors.critical : AppColors.warningColor,
                  inactiveTrackColor: AppColors.divider,
                  thumbColor: sev == 'critical' ? AppColors.critical : AppColors.warningColor,
                ),
                child: Slider(
                  value: current.clamp(sliderMin, sliderMax),
                  min: sliderMin,
                  max: sliderMax,
                  divisions: ((sliderMax - sliderMin)).round(),
                  onChanged: (v) => widget.onSet(widget.patient.id, vt, key, v.roundToDouble()),
                ),
              ),
            ],
          ),
        ),
      );
    }

    addRow('critLow', 'Call me — critical low', 'critical', thr.critLow, meta.min, meta.max * 0.6);
    addRow('warnLow', 'Notify — warning low', 'warning', thr.warnLow, meta.min, meta.max * 0.7);
    addRow('warnHigh', 'Notify — warning high', 'warning', thr.warnHigh, meta.max * 0.4, meta.max * 0.9);
    addRow('critHigh', 'Call me — critical high', 'critical', thr.critHigh, meta.max * 0.5, meta.max);

    return rows;
  }

  VitalType _vitalTypeFromTab(String tab) {
    switch (tab) {
      case 'hr': return VitalType.hr;
      case 'spo2': return VitalType.spo2;
      case 'rr': return VitalType.rr;
      default: return VitalType.hr;
    }
  }
}
