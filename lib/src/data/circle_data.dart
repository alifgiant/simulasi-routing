import 'package:flutter/material.dart';

class CircleData {
  final int id;
  Offset position;

  CircleData(this.id, this.position);

  @override
  String toString() => 'Node($id)';
}
