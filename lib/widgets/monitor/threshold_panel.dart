import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    {'vt': VitalType.hr,   'label': 'Heart Rate',  'unit': 'bpm'},
    {'vt': VitalType.spo2, 'label': 'SpO₂',        'unit': '%'},
    {'vt': VitalType.rr,   'label': 'Resp. Rate',  'unit': 'br/min'},
    {'vt': VitalType.sbp,  'label': 'Blood Pressure', 'unit': 'mmHg'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zone legend
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              _chip('🔴', 'Critical', AppColors.critical),
              const SizedBox(width: 12),
              _chip('🟡', 'Watch', AppColors.warningColor),
              const SizedBox(width: 12),
              _chip('🟢', 'Stable', AppColors.stable),
            ],
          ),
        ),

        // Vital selector
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

        // Content for selected vital
        if (_tab == VitalType.sbp) ...[
          _vitalBlock(VitalType.sbp,  'Systolic (SBP)'),
          const SizedBox(height: 20),
          _vitalBlock(VitalType.dbp,  'Diastolic (DBP)'),
          const SizedBox(height: 20),
          _vitalBlock(VitalType.map,  'Mean Arterial (MAP)'),
        ] else
          _vitalBlock(_tab, null),
      ],
    );
  }

  Widget _chip(String emoji, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _vitalBlock(VitalType vt, String? subtitle) {
    final meta   = vitalMeta[vt]!;
    final thr    = widget.patient.thresholds[vt] ?? const VitalThreshold();
    final current = widget.patient.vitals[vt] ?? 0;
    final isSpo2  = vt == VitalType.spo2;
    final sev     = thr.severity(current);
    final sevColor = sev == 'critical'
        ? AppColors.critical
        : sev == 'warning'
            ? AppColors.warningColor
            : AppColors.stable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with live value
        Row(
          children: [
            if (subtitle != null) ...[
              Text(subtitle,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: sevColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Now: ${current.round()} ${meta.unit}',
                style: GoogleFonts.dmSans(
                    color: sevColor, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Zone bar
        _ZoneBar(thr: thr, current: current, meta: meta, isSpo2: isSpo2),

        const SizedBox(height: 16),

        // Threshold inputs — 2 columns
        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Critical Low',
                sublabel: 'Alert me urgently',
                color: AppColors.critical,
                icon: Icons.arrow_downward,
                value: thr.critLow,
                unit: meta.unit,
                onSave: (v) => widget.onSet(widget.patient.id, vt, 'critLow', v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isSpo2
                  ? const SizedBox.shrink()
                  : _Field(
                      label: 'Critical High',
                      sublabel: 'Alert me urgently',
                      color: AppColors.critical,
                      icon: Icons.arrow_upward,
                      value: thr.critHigh,
                      unit: meta.unit,
                      onSave: (v) => widget.onSet(widget.patient.id, vt, 'critHigh', v),
                    ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _Field(
                label: 'Watch Low',
                sublabel: 'Needs monitoring',
                color: AppColors.warningColor,
                icon: Icons.arrow_downward,
                value: thr.warnLow,
                unit: meta.unit,
                onSave: (v) => widget.onSet(widget.patient.id, vt, 'warnLow', v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isSpo2
                  ? const SizedBox.shrink()
                  : _Field(
                      label: 'Watch High',
                      sublabel: 'Needs monitoring',
                      color: AppColors.warningColor,
                      icon: Icons.arrow_upward,
                      value: thr.warnHigh,
                      unit: meta.unit,
                      onSave: (v) => widget.onSet(widget.patient.id, vt, 'warnHigh', v),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Zone bar ──────────────────────────────────────────────────────────────────

class _ZoneBar extends StatelessWidget {
  final VitalThreshold thr;
  final double current;
  final VitalMeta meta;
  final bool isSpo2;

  const _ZoneBar({
    required this.thr,
    required this.current,
    required this.meta,
    required this.isSpo2,
  });

  @override
  Widget build(BuildContext context) {
    final min   = meta.absMin;
    final max   = meta.absMax;
    final range = max - min;

    double frac(double? v) =>
        v == null ? 0 : ((v - min) / range).clamp(0.0, 1.0);

    final critLow  = frac(thr.critLow);
    final warnLow  = frac(thr.warnLow);
    final warnHigh = isSpo2 ? 1.0 : frac(thr.warnHigh);
    final critHigh = isSpo2 ? 1.0 : frac(thr.critHigh);
    final cur      = frac(current);

    final sev = thr.severity(current);
    final curColor = sev == 'critical'
        ? AppColors.critical
        : sev == 'warning'
            ? AppColors.warningColor
            : AppColors.stable;

    return LayoutBuilder(builder: (context, bc) {
      final w = bc.maxWidth;
      return Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 20,
                  width: w,
                  child: Row(children: [
                    if (thr.critLow != null)
                      _seg(w * critLow, AppColors.critical),
                    if (thr.warnLow != null)
                      _seg(w * (warnLow - critLow), AppColors.warningColor),
                    _seg(w * ((isSpo2 ? 1.0 : warnHigh) - warnLow), AppColors.stable),
                    if (!isSpo2 && thr.warnHigh != null)
                      _seg(w * (critHigh - warnHigh), AppColors.warningColor),
                    if (!isSpo2 && thr.critHigh != null)
                      _seg(w * (1.0 - critHigh), AppColors.critical),
                  ]),
                ),
              ),
              // Current value needle
              Positioned(
                left: (w * cur - 1.5).clamp(0.0, w - 3),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: curColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: curColor.withOpacity(0.7),
                          blurRadius: 5,
                          spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${min.round()} ${meta.unit}',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 9)),
              Row(children: [
                Icon(Icons.circle, size: 7, color: curColor),
                const SizedBox(width: 3),
                Text('${current.round()} ${meta.unit}',
                    style: GoogleFonts.dmSans(
                        color: curColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ]),
              Text('${max.round()} ${meta.unit}',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 9)),
            ],
          ),
        ],
      );
    });
  }

  Widget _seg(double width, Color color) {
    if (width <= 0) return const SizedBox.shrink();
    return Container(width: width, color: color.withOpacity(0.28));
  }
}

// ── Single threshold input field ──────────────────────────────────────────────

class _Field extends StatefulWidget {
  final String label;
  final String sublabel;
  final Color color;
  final IconData icon;
  final double? value;
  final String unit;
  final void Function(double) onSave;

  const _Field({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.icon,
    required this.value,
    required this.unit,
    required this.onSave,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value != null ? widget.value!.round().toString() : '');
    _focus = FocusNode()
      ..addListener(() {
        final focused = _focus.hasFocus;
        if (focused != _hasFocus) {
          setState(() => _hasFocus = focused);
          if (!focused) _submit();
        }
      });
  }

  @override
  void didUpdateWidget(_Field old) {
    super.didUpdateWidget(old);
    // Only update from outside when the field is NOT being edited
    if (!_hasFocus) {
      final newText =
          widget.value != null ? widget.value!.round().toString() : '';
      if (_ctrl.text != newText) _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final v = double.tryParse(_ctrl.text);
    if (v != null) widget.onSave(v);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasFocus
              ? widget.color
              : widget.color.withOpacity(0.25),
          width: _hasFocus ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, size: 12, color: widget.color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                      color: widget.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.sublabel,
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 9),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      color: widget.color,
                      fontSize: 24,
                      fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  widget.unit,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
