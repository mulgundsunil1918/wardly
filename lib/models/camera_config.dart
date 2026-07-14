import 'monitor_vitals.dart';

/// Normalized rectangle on the camera frame (0.0 – 1.0 for both axes).
/// Used to define which region of the camera image to crop for OCR per vital.
class RoiRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const RoiRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  RoiRect clamp() => RoiRect(
        left: left.clamp(0.0, 1.0),
        top: top.clamp(0.0, 1.0),
        width: width.clamp(0.01, 1.0 - left.clamp(0.0, 1.0)),
        height: height.clamp(0.01, 1.0 - top.clamp(0.0, 1.0)),
      );

  Map<String, dynamic> toJson() =>
      {'l': left, 't': top, 'w': width, 'h': height};

  factory RoiRect.fromJson(Map<String, dynamic> j) => RoiRect(
        left: (j['l'] as num).toDouble(),
        top: (j['t'] as num).toDouble(),
        width: (j['w'] as num).toDouble(),
        height: (j['h'] as num).toDouble(),
      );
}

class CameraConfig {
  final String id;
  final String label;
  final String brand;
  final String ip;
  final int port;
  final String username;
  final String password;
  final String customRtsp;
  final String patientId;
  final String patientName;
  final String bedLabel;
  final bool isEnabled;
  final Map<VitalType, RoiRect> roi;

  const CameraConfig({
    required this.id,
    required this.label,
    required this.brand,
    required this.ip,
    this.port = 554,
    this.username = 'admin',
    required this.password,
    this.customRtsp = '',
    this.patientId = '',
    this.patientName = '',
    this.bedLabel = '',
    this.isEnabled = true,
    this.roi = const {},
  });

  String get rtspUrl {
    if (customRtsp.isNotEmpty) return customRtsp;
    final cred = '${Uri.encodeComponent(username)}:${Uri.encodeComponent(password)}';
    final base = 'rtsp://$cred@$ip:$port';
    switch (brand) {
      case 'TrueView':
        return '$base/ch0_0.264';
      case 'Hikvision':
        return '$base/Streaming/Channels/101';
      case 'Dahua':
        return '$base/cam/realmonitor?channel=1&subtype=0';
      case 'CP Plus':
        return '$base/stream1';
      default:
        return '$base/stream1';
    }
  }

  bool get hasRoi => roi.isNotEmpty;

  int get roiZoneCount => roi.length;

  CameraConfig copyWith({
    String? id,
    String? label,
    String? brand,
    String? ip,
    int? port,
    String? username,
    String? password,
    String? customRtsp,
    String? patientId,
    String? patientName,
    String? bedLabel,
    bool? isEnabled,
    Map<VitalType, RoiRect>? roi,
  }) {
    return CameraConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      brand: brand ?? this.brand,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      customRtsp: customRtsp ?? this.customRtsp,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      bedLabel: bedLabel ?? this.bedLabel,
      isEnabled: isEnabled ?? this.isEnabled,
      roi: roi ?? this.roi,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'brand': brand,
        'ip': ip,
        'port': port,
        'username': username,
        'password': password,
        'customRtsp': customRtsp,
        'patientId': patientId,
        'patientName': patientName,
        'bedLabel': bedLabel,
        'isEnabled': isEnabled,
        'roi': roi.map((vt, r) => MapEntry(vt.name, r.toJson())),
      };

  factory CameraConfig.fromJson(Map<String, dynamic> j) {
    final roiRaw = (j['roi'] as Map<String, dynamic>?) ?? {};
    final roi = <VitalType, RoiRect>{};
    for (final entry in roiRaw.entries) {
      try {
        final vt = VitalType.values.firstWhere((v) => v.name == entry.key);
        roi[vt] = RoiRect.fromJson(Map<String, dynamic>.from(entry.value as Map));
      } catch (_) {}
    }
    return CameraConfig(
      id: j['id'] as String,
      label: j['label'] as String? ?? '',
      brand: j['brand'] as String? ?? 'CP Plus',
      ip: j['ip'] as String? ?? '',
      port: (j['port'] as num?)?.toInt() ?? 554,
      username: j['username'] as String? ?? 'admin',
      password: j['password'] as String? ?? '',
      customRtsp: j['customRtsp'] as String? ?? '',
      patientId: j['patientId'] as String? ?? '',
      patientName: j['patientName'] as String? ?? '',
      bedLabel: j['bedLabel'] as String? ?? '',
      isEnabled: j['isEnabled'] as bool? ?? true,
      roi: roi,
    );
  }
}
