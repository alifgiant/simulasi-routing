import 'circle_data.dart';

class Node {
  final int id;

  Node({required this.id});
  Node.fromCircle(CircleData circle) : id = circle.id;

  @override
  String toString() => 'Node($id)';
}
