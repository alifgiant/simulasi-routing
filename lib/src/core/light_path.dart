import 'dart:convert';

class LightPath {
  final int source, target;
  final int fiber, lambda;
  bool isUsed;

  LightPath({
    required this.source,
    required this.target,
    required this.fiber,
    required this.lambda,
    this.isUsed = false,
  });

  @override
  bool operator ==(covariant LightPath other) {
    return source == other.source &&
        target == other.target &&
        fiber == other.fiber &&
        lambda == other.lambda &&
        isUsed == other.isUsed;
  }

  @override
  int get hashCode =>
      source.hashCode ^
      target.hashCode & fiber.hashCode ^
      lambda.hashCode ^
      isUsed.hashCode;

  @override
  String toString() {
    return jsonEncode({
      'source': source,
      'target': target,
      'fiber': fiber,
      'lambda': lambda,
      'isUsed': isUsed,
    });
  }
}

class LightPathRequest {
  final int id;
  final double holdTime;

  const LightPathRequest({
    required this.id,
    required this.holdTime,
  });
}

class LightPathResult {
  final bool isSucess;

  const LightPathResult({required this.isSucess});
}
