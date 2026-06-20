import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/monitor_vitals.dart';
import '../../providers/monitor_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/app_theme.dart';

class VitalTrendsScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const VitalTrendsScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<VitalTrendsScreen> createState() => _VitalTrendsScreenState();
}

class _VitalTrendsScreenState extends State<VitalTrendsScreen> {
  VitalType _selected = VitalType.hr;
  String _range = '12h';

  Duration get _duration {
    switch (_range) {
      case '1h': return const Duration(hours: 1);
      case '6h': return const Duration(hours: 6);
      case '12h': return const Duration(hours: 12);
      default: return const Duration(hours: 12);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<MonitorProvider>();
    context.watch<ThemeProvider>();
    final meta = vitalMeta[_selected]!;

    final cutoff = DateTime.now().subtract(_duration);
    final allHistory = monitor.historyFor(widget.patientId);
    final data = allHistory
        .where((s) => s.time.isAfter(cutoff) && s.vitals[_selected] != null)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.appBarBg,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text('Vital Trends', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, color: AppColors.primary)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.card,
            child: Text(widget.patientName,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          ),

          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [VitalType.hr, VitalType.spo2, VitalType.rr, VitalType.sbp].map((vt) {
                final m = vitalMeta[vt]!;
                final sel = vt == _selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m.label, style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textSecondary,
                    )),
                    selected: sel,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.card,
                    onSelected: (_) => setState(() => _selected = vt),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['1h', '6h', '12h'].map((r) {
                final sel = r == _range;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _range = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r, style: GoogleFonts.dmSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : AppColors.textSecondary,
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: data.isEmpty
                ? Center(child: Text('No data for this range',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 14)))
                : Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 20, 24),
                    child: _buildChart(data, meta),
                  ),
          ),

          if (data.isNotEmpty) _statsRow(data, meta),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChart(List<VitalSnapshot> data, VitalMeta meta) {
    final threshold = defaultAdultThresholds[_selected];
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].vitals[_selected]!));
    }

    final values = spots.map((s) => s.y).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) - 5;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 5;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (val) => FlLine(
            color: AppColors.textSecondary.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (data.length / 5).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                return Text(
                  DateFormat('HH:mm').format(data[idx].time),
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 9),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (threshold?.critHigh != null)
              HorizontalLine(
                y: threshold!.critHigh!,
                color: AppColors.critical.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: GoogleFonts.dmSans(color: AppColors.critical, fontSize: 9),
                  labelResolver: (_) => 'Crit High',
                ),
              ),
            if (threshold?.critLow != null)
              HorizontalLine(
                y: threshold!.critLow!,
                color: AppColors.critical.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.bottomRight,
                  style: GoogleFonts.dmSans(color: AppColors.critical, fontSize: 9),
                  labelResolver: (_) => 'Crit Low',
                ),
              ),
            if (threshold?.warnHigh != null)
              HorizontalLine(
                y: threshold!.warnHigh!,
                color: AppColors.warningColor.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            if (threshold?.warnLow != null)
              HorizontalLine(
                y: threshold!.warnLow!,
                color: AppColors.warningColor.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final idx = s.x.toInt();
              final time = idx >= 0 && idx < data.length
                  ? DateFormat('HH:mm:ss').format(data[idx].time)
                  : '';
              return LineTooltipItem(
                '${s.y.toStringAsFixed(1)} ${meta.unit}\n$time',
                GoogleFonts.dmSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: data.length < 50,
              getDotPainter: (spot, xPercent, bar, idx) => FlDotCirclePainter(
                radius: 2.5,
                color: AppColors.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(List<VitalSnapshot> data, VitalMeta meta) {
    final values = data.map((s) => s.vitals[_selected]!).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final latest = values.last;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          _stat('Min', '${min.round()}', meta.unit),
          Container(width: 1, height: 32, color: AppColors.textSecondary.withValues(alpha: 0.15)),
          _stat('Max', '${max.round()}', meta.unit),
          Container(width: 1, height: 32, color: AppColors.textSecondary.withValues(alpha: 0.15)),
          _stat('Avg', '${avg.round()}', meta.unit),
          Container(width: 1, height: 32, color: AppColors.textSecondary.withValues(alpha: 0.15)),
          _stat('Latest', '${latest.round()}', meta.unit),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
          Text(unit, style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 9)),
        ],
      ),
    );
  }
}
