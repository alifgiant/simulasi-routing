import 'package:flutter/material.dart';

class CircleData {
  final int id;
  Offset position;

  CircleData(this.id, this.position);

  @override
  String toString() => 'Node($id)';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'position': '${position.dx},${position.dy}',
    };
  }

  factory CircleData.fromJson(Map<String, dynamic> json) {
    final pos = (json['position'] as String)
        .split(
          ',',
        )
        .map(double.parse)
        .toList();
    return CircleData(
      json['id'],
      Offset(pos[0], pos[1]),
    );
  }
}
