import 'monitor_vitals.dart';

class MonitoredPatient {
  final String id;
  final String name;
  final String gender;
  final String age;
  final String diagnosis;
  final String support;
  final String bed;
  final String ward;
  final String wardId;
  final String dutyPhone;
  final Map<VitalType, VitalThreshold> thresholds;
  final Map<VitalType, double> vitals;
  final Map<VitalType, SimConfig> sim;

  const MonitoredPatient({
    required this.id,
    required this.name,
    required this.gender,
    required this.age,
    required this.diagnosis,
    required this.support,
    required this.bed,
    required this.ward,
    this.wardId = '',
    this.dutyPhone = '',
    required this.thresholds,
    required this.vitals,
    required this.sim,
  });

  MonitoredPatient copyWith({
    Map<VitalType, VitalThreshold>? thresholds,
    Map<VitalType, double>? vitals,
  }) {
    return MonitoredPatient(
      id: id,
      name: name,
      gender: gender,
      age: age,
      diagnosis: diagnosis,
      support: support,
      bed: bed,
      ward: ward,
      wardId: wardId,
      dutyPhone: dutyPhone,
      thresholds: thresholds ?? this.thresholds,
      vitals: vitals ?? this.vitals,
      sim: sim,
    );
  }

  String get worstSeverity {
    String worst = 'stable';
    for (final vt in [VitalType.hr, VitalType.spo2, VitalType.rr, VitalType.sbp, VitalType.dbp, VitalType.map]) {
      final t = thresholds[vt];
      final v = vitals[vt];
      if (t == null || v == null) continue;
      final s = t.severity(v);
      if (s == 'critical') return 'critical';
      if (s == 'warning') worst = 'warning';
    }
    return worst;
  }

  double get mapValue => ((vitals[VitalType.sbp] ?? 0) + 2 * (vitals[VitalType.dbp] ?? 0)) / 3;
}
