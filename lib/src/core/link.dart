import 'dart:convert';

class Link {
  final int source, target;
  final int fiber, lambda;

  const Link({
    required this.source,
    required this.target,
    required this.fiber,
    required this.lambda,
  });

  @override
  bool operator ==(covariant Link other) {
    return source == other.source &&
        target == other.target &&
        fiber == other.fiber &&
        lambda == other.lambda;
  }

  @override
  int get hashCode =>
      source.hashCode ^ target.hashCode & fiber.hashCode ^ lambda.hashCode;

  @override
  String toString() {
    return jsonEncode({
      'source': source,
      'target': target,
      'fiber': fiber,
      'lambda': lambda,
    });
  }
}