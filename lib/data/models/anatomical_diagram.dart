import 'package:anatomy_quiz_app/data/models/label.dart';

class AnatomicalDiagram {
  final int id;
  final int diagramNumber;
  final String title;
  final String imageAssetPath;
  final int unitId; 
  final List<Label> labels;

  AnatomicalDiagram({
    required this.id,
    required this.diagramNumber,
    required this.title,
    required this.imageAssetPath,
    required this.unitId,
    this.labels = const [],
  });

  factory AnatomicalDiagram.fromMap(Map<String, dynamic> map) {
    return AnatomicalDiagram(
      id: map['id'],
      title: map['title'],
      diagramNumber: map['number'],
      imageAssetPath: map['imageAssetPath'],
      unitId: map['unit_id'],
    );
  }
  
  AnatomicalDiagram copyWith({
    int? id,
    int? diagramNumber,
    String? title,
    String? imageAssetPath,
    int? unitId, 
    List<Label>? labels,
  }) {
    return AnatomicalDiagram(
      id: id ?? this.id,
      diagramNumber: diagramNumber ?? this.diagramNumber,
      title: title ?? this.title,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      unitId: unitId ?? this.unitId,
      labels: labels ?? this.labels,
    );
  }
}