/// A single body weight / composition measurement at a point in time.
class BodyMetric {
  final int id;
  final double weight;
  final double? bodyFatPercent;
  final DateTime recordedAt;

  const BodyMetric({
    required this.id,
    required this.weight,
    this.bodyFatPercent,
    required this.recordedAt,
  });
}
