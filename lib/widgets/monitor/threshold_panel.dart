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
  VitalType _tab = VitalType.hr;

  static const _tabs = [
    {'vt': VitalType.hr,   'label': 'Heart Rate'},
    {'vt': VitalType.spo2, 'label': 'SpO₂'},
    {'vt': VitalType.rr,   'label': 'Resp. Rate'},
    {'vt': VitalType.sbp,  'label': 'Blood Pressure'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Vital tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _tabs.map((t) {
              final vt = t['vt'] as VitalType;
              final active = _tab == vt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _tab = vt),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      t['label'] as String,
                      style: GoogleFonts.dmSans(
                        color: active ? Colors.white : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        if (_tab == VitalType.sbp) ...[
          _vitalBlock(context, VitalType.sbp,  'Systolic (SBP)'),
          const SizedBox(height: 20),
          _vitalBlock(context, VitalType.dbp,  'Diastolic (DBP)'),
          const SizedBox(height: 20),
          _vitalBlock(context, VitalType.map,  'Mean Arterial (MAP)'),
        ] else
          _vitalBlock(context, _tab, null),
      ],
    );
  }

  Widget _vitalBlock(BuildContext context, VitalType vt, String? subtitle) {
    final meta    = vitalMeta[vt]!;
    final thr     = widget.patient.thresholds[vt] ?? const VitalThreshold();
    final current = widget.patient.vitals[vt] ?? 0;
    final isSpo2  = vt == VitalType.spo2;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + live value
          Row(
            children: [
              if (subtitle != null)
                Text(subtitle,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                '${current.round()} ${meta.unit}',
                style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),

          if (subtitle != null) const SizedBox(height: 14),

          // Critical Low slider
          _slider(
            context,
            label: '🔴  Critical Low',
            sublabel: 'Below this → urgent alert',
            value: thr.critLow,
            min: meta.absMin,
            max: meta.absMax * 0.65,
            unit: meta.unit,
            color: AppColors.critical,
            onChanged: (v) => widget.onSet(widget.patient.id, vt, 'critLow', v),
          ),

          const SizedBox(height: 16),

          // Critical High slider (hidden for SpO₂)
          if (!isSpo2)
            _slider(
              context,
              label: '🔴  Critical High',
              sublabel: 'Above this → urgent alert',
              value: thr.critHigh,
              min: meta.absMax * 0.35,
              max: meta.absMax,
              unit: meta.unit,
              color: AppColors.critical,
              onChanged: (v) => widget.onSet(widget.patient.id, vt, 'critHigh', v),
            ),
        ],
      ),
    );
  }

  Widget _slider(
    BuildContext context, {
    required String label,
    required String sublabel,
    required double? value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required void Function(double) onChanged,
  }) {
    final current = (value ?? min).clamp(min, max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.dmSans(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text(sublabel,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value != null ? '${value.round()} $unit' : 'Off',
                style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.15),
            thumbColor: color,
            overlayColor: color.withOpacity(0.15),
          ),
          child: Slider(
            value: current,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (v) => onChanged(v.roundToDouble()),
          ),
        ),
      ],
    );
  }
}
