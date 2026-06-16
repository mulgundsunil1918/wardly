import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/monitor_vitals.dart';

class ParsedVitals {
  final double? hr;
  final double? spo2;
  final double? rr;
  final double? sbp;
  final double? dbp;
  final DateTime timestamp;
  final int confidence;

  const ParsedVitals({
    this.hr,
    this.spo2,
    this.rr,
    this.sbp,
    this.dbp,
    required this.timestamp,
    this.confidence = 0,
  });

  double? get map => (sbp != null && dbp != null)
      ? ((sbp! + 2 * dbp!) / 3).roundToDouble()
      : null;

  Map<VitalType, double> toVitalMap() {
    final m = <VitalType, double>{};
    if (hr != null) m[VitalType.hr] = hr!;
    if (spo2 != null) m[VitalType.spo2] = spo2!;
    if (rr != null) m[VitalType.rr] = rr!;
    if (sbp != null) m[VitalType.sbp] = sbp!;
    if (dbp != null) m[VitalType.dbp] = dbp!;
    final mapVal = map;
    if (mapVal != null) m[VitalType.map] = mapVal;
    return m;
  }

  bool get hasAnyVital => hr != null || spo2 != null || rr != null || sbp != null;

  @override
  String toString() => 'HR:$hr SpO2:$spo2 RR:$rr BP:$sbp/$dbp MAP:$map (conf:$confidence)';
}

class VitalsOcrService {
  final TextRecognizer _recognizer = TextRecognizer();
  bool _isProcessing = false;

  bool get isProcessing => _isProcessing;

  Future<ParsedVitals?> processFrame(CameraImage image, CameraDescription camera) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image, camera);
      if (inputImage == null) return null;

      final result = await _recognizer.processImage(inputImage);
      final parsed = _parseVitals(result);
      return parsed;
    } catch (_) {
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  Future<ParsedVitals?> processFile(File imageFile) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _recognizer.processImage(inputImage);
      return _parseVitals(result);
    } catch (_) {
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image, CameraDescription camera) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw as int);
    if (format == null) return null;

    final rotation = _rotationFromCamera(camera);

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: ui.Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromCamera(CameraDescription camera) {
    switch (camera.sensorOrientation) {
      case 0: return InputImageRotation.rotation0deg;
      case 90: return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default: return InputImageRotation.rotation0deg;
    }
  }

  /// Parse OCR text to extract vital signs.
  ///
  /// Strategy: scan all recognized text blocks for patterns that match
  /// vital sign readings. Common patterns on bedside monitors:
  ///
  /// - HR / heart rate: a number near "HR", "♥", or green colored, typically 40-220
  /// - SpO2: a number near "SpO2", "SPO2", "O2", typically 50-100, often with %
  /// - RR / resp rate: a number near "RR", "RESP", typically 4-60
  /// - BP: pattern like "120/80" or numbers near "SYS", "DIA", "NIBP"
  ParsedVitals _parseVitals(RecognizedText result) {
    double? hr, spo2, rr, sbp, dbp;
    int confidence = 0;

    final allText = result.text.toUpperCase();
    final blocks = result.blocks;

    for (final block in blocks) {
      final text = block.text.toUpperCase().trim();

      // Try BP pattern: "120/80" or "120 / 80"
      final bpMatch = RegExp(r'(\d{2,3})\s*/\s*(\d{2,3})').firstMatch(text);
      if (bpMatch != null) {
        final sys = double.tryParse(bpMatch.group(1)!);
        final dia = double.tryParse(bpMatch.group(2)!);
        if (sys != null && dia != null && sys > 30 && sys < 260 && dia > 15 && dia < 160 && sys > dia) {
          sbp = sys;
          dbp = dia;
          confidence += 25;
        }
      }

      // Scan each line in the block
      for (final line in block.lines) {
        final lineText = line.text.toUpperCase().trim();

        // HR detection
        if (hr == null && _containsLabel(lineText, ['HR', 'HEART', 'PULSE', 'BPM'])) {
          final val = _extractNumber(lineText, min: 30, max: 220);
          if (val != null) { hr = val; confidence += 25; }
        }

        // SpO2 detection
        if (spo2 == null && _containsLabel(lineText, ['SPO2', 'SP02', 'O2', 'SAT', 'SPO'])) {
          final val = _extractNumber(lineText, min: 50, max: 100);
          if (val != null) { spo2 = val; confidence += 25; }
        }

        // RR detection
        if (rr == null && _containsLabel(lineText, ['RR', 'RESP', 'BREATHS'])) {
          final val = _extractNumber(lineText, min: 4, max: 60);
          if (val != null) { rr = val; confidence += 25; }
        }

        // SBP/DBP from labeled lines
        if (sbp == null && _containsLabel(lineText, ['SYS', 'NIBP', 'ART'])) {
          final val = _extractNumber(lineText, min: 40, max: 260);
          if (val != null) { sbp = val; confidence += 15; }
        }
        if (dbp == null && _containsLabel(lineText, ['DIA'])) {
          final val = _extractNumber(lineText, min: 15, max: 160);
          if (val != null) { dbp = val; confidence += 10; }
        }
      }
    }

    // Fallback: if no labeled matches, try positional heuristic.
    // On most monitors, the largest/most prominent numbers are HR and SpO2.
    if (hr == null || spo2 == null) {
      final numbers = _extractAllNumbers(allText);
      for (final n in numbers) {
        if (hr == null && n >= 40 && n <= 220) {
          hr = n;
          confidence += 10;
        } else if (spo2 == null && n >= 70 && n <= 100) {
          spo2 = n;
          confidence += 10;
        } else if (rr == null && n >= 6 && n <= 50) {
          rr = n;
          confidence += 5;
        }
      }
    }

    return ParsedVitals(
      hr: hr,
      spo2: spo2,
      rr: rr,
      sbp: sbp,
      dbp: dbp,
      timestamp: DateTime.now(),
      confidence: confidence.clamp(0, 100),
    );
  }

  bool _containsLabel(String text, List<String> labels) {
    for (final label in labels) {
      if (text.contains(label)) return true;
    }
    return false;
  }

  double? _extractNumber(String text, {required double min, required double max}) {
    final matches = RegExp(r'\d+\.?\d*').allMatches(text);
    for (final m in matches) {
      final val = double.tryParse(m.group(0)!);
      if (val != null && val >= min && val <= max) return val;
    }
    return null;
  }

  List<double> _extractAllNumbers(String text) {
    final nums = <double>[];
    final matches = RegExp(r'\b\d{2,3}\b').allMatches(text);
    for (final m in matches) {
      final val = double.tryParse(m.group(0)!);
      if (val != null) nums.add(val);
    }
    return nums;
  }

  void dispose() {
    _recognizer.close();
  }
}
