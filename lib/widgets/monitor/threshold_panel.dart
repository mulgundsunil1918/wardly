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
  String _tab = 'hr';

  static const _tabs = [
    {'key': 'hr',   'label': 'HR'},
    {'key': 'spo2', 'label': 'SpO₂'},
    {'key': 'rr',   'label': 'RR'},
    {'key': 'bp',   'label': 'BP'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.tune, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Alert Thresholds',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('changes apply instantly',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),

          // Zone legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _legendChip('🔴 Critical', AppColors.critical),
                const SizedBox(width: 8),
                _legendChip('🟡 Watch', AppColors.warningColor),
                const SizedBox(width: 8),
                _legendChip('🟢 Stable', AppColors.stable),
              ],
            ),
          ),

          // Vital tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: _tabs.map((t) {
                final active = _tab == t['key'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = t['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        t['label']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          color: active
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Threshold content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _tab == 'bp'
                ? Column(
                    children: [
                      _vitalSection('SBP — Systolic', VitalType.sbp),
                      const SizedBox(height: 20),
                      _vitalSection('DBP — Diastolic', VitalType.dbp),
                      const SizedBox(height: 20),
                      _vitalSection('MAP — Mean Arterial', VitalType.map),
                    ],
                  )
                : _vitalSection(
                    null, _vitalTypeFromTab(_tab)),
          ),
        ],
      ),
    );
  }

  Widget _legendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _vitalSection(String? title, VitalType vt) {
    final meta = vitalMeta[vt]!;
    final thr = widget.patient.thresholds[vt] ?? const VitalThreshold();
    final current = widget.patient.vitals[vt] ?? 0;
    final isSpo2 = vt == VitalType.spo2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(title,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3)),
          const SizedBox(height: 10),
        ],

        // Visual zone bar
        _ZoneBar(thr: thr, current: current, meta: meta, isSpo2: isSpo2),

        const SizedBox(height: 16),

        // Editable threshold fields in a grid
        Row(
          children: [
            _ThresholdField(
              label: 'Critical Low',
              color: AppColors.critical,
              value: thr.critLow,
              unit: meta.unit,
              onChanged: (v) =>
                  widget.onSet(widget.patient.id, vt, 'critLow', v),
            ),
            const SizedBox(width: 8),
            _ThresholdField(
              label: 'Watch Low',
              color: AppColors.warningColor,
              value: thr.warnLow,
              unit: meta.unit,
              onChanged: (v) =>
                  widget.onSet(widget.patient.id, vt, 'warnLow', v),
            ),
            if (!isSpo2) ...[
              const SizedBox(width: 8),
              _ThresholdField(
                label: 'Watch High',
                color: AppColors.warningColor,
                value: thr.warnHigh,
                unit: meta.unit,
                onChanged: (v) =>
                    widget.onSet(widget.patient.id, vt, 'warnHigh', v),
              ),
              const SizedBox(width: 8),
              _ThresholdField(
                label: 'Critical High',
                color: AppColors.critical,
                value: thr.critHigh,
                unit: meta.unit,
                onChanged: (v) =>
                    widget.onSet(widget.patient.id, vt, 'critHigh', v),
              ),
            ],
          ],
        ),
      ],
    );
  }

  VitalType _vitalTypeFromTab(String tab) {
    switch (tab) {
      case 'spo2': return VitalType.spo2;
      case 'rr':   return VitalType.rr;
      default:     return VitalType.hr;
    }
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
    final min = meta.absMin;
    final max = meta.absMax;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zone bar
        LayoutBuilder(builder: (context, bc) {
          final w = bc.maxWidth;
          return Stack(
            children: [
              // Background zones
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 18,
                  width: w,
                  child: Row(
                    children: [
                      // Critical low zone
                      if (thr.critLow != null)
                        _zone(w * critLow, AppColors.critical),
                      // Warning low zone
                      if (thr.warnLow != null)
                        _zone(w * (warnLow - critLow), AppColors.warningColor),
                      // Stable zone
                      _zone(
                        w * ((isSpo2 ? 1.0 : warnHigh) - warnLow),
                        AppColors.stable,
                      ),
                      // Warning high zone
                      if (!isSpo2 && thr.warnHigh != null)
                        _zone(
                          w * (critHigh - warnHigh),
                          AppColors.warningColor,
                        ),
                      // Critical high zone
                      if (!isSpo2 && thr.critHigh != null)
                        _zone(w * (1.0 - critHigh), AppColors.critical),
                    ],
                  ),
                ),
              ),
              // Current value indicator
              Positioned(
                left: (w * cur - 1).clamp(0.0, w - 2),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: curColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                          color: curColor.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 4),
        // Min / current / max labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${min.round()} ${meta.unit}',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 9)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: curColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${current.round()} ${meta.unit}',
                style: GoogleFonts.dmSans(
                    color: curColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Text('${max.round()} ${meta.unit}',
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _zone(double width, Color color) {
    if (width <= 0) return const SizedBox.shrink();
    return Container(width: width, color: color.withOpacity(0.25));
  }
}

// ── Editable threshold field ──────────────────────────────────────────────────

class _ThresholdField extends StatefulWidget {
  final String label;
  final Color color;
  final double? value;
  final String unit;
  final void Function(double) onChanged;

  const _ThresholdField({
    required this.label,
    required this.color,
    required this.value,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<_ThresholdField> createState() => _ThresholdFieldState();
}

class _ThresholdFieldState extends State<_ThresholdField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value != null ? widget.value!.round().toString() : '');
  }

  @override
  void didUpdateWidget(_ThresholdField old) {
    super.didUpdateWidget(old);
    final newText =
        widget.value != null ? widget.value!.round().toString() : '';
    if (_ctrl.text != newText && !_ctrl.selection.isValid) {
      _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: widget.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                color: widget.color,
                fontSize: 16,
                fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              filled: true,
              fillColor: widget.color.withOpacity(0.07),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    BorderSide(color: widget.color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.color, width: 1.5),
              ),
              suffixText: widget.unit,
              suffixStyle: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 9),
            ),
            onSubmitted: (v) {
              final parsed = double.tryParse(v);
              if (parsed != null) widget.onChanged(parsed);
            },
            onEditingComplete: () {
              final parsed = double.tryParse(_ctrl.text);
              if (parsed != null) widget.onChanged(parsed);
              FocusScope.of(context).unfocus();
            },
          ),
        ],
      ),
    );
  }
}
