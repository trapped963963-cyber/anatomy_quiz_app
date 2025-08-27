import 'package:anatomy_quiz_app/data/models/label.dart';

class AnatomicalDiagram {
  final int id;
  final int diagramNumber;
  final String title;
  final String imageAssetPath;
  final String labeledImageAssetPath;
  final int unitId; 
  final List<Label> labels;
  final int totalSteps; 

  AnatomicalDiagram({
    required this.id,
    required this.diagramNumber,
    required this.title,
    required this.imageAssetPath,
    required this.labeledImageAssetPath,
    required this.unitId,
    this.labels = const [],
    this.totalSteps = 0,
  });

  factory AnatomicalDiagram.fromMap(Map<String, dynamic> map) {
    return AnatomicalDiagram(
      id: map['id'],
      title: map['title'],
      diagramNumber: map['number'],
      imageAssetPath: map['imageAssetPath'],
      labeledImageAssetPath: map['labeledImageAssetPath'],
      unitId: map['unit_id'],
    );
  }
  
  AnatomicalDiagram copyWith({
    int? id,
    int? diagramNumber,
    String? title,
    String? imageAssetPath,
    String? labeledImageAssetPath,
    int? unitId, 
    List<Label>? labels,
    int? totalSteps, 

  }) {
    return AnatomicalDiagram(
      id: id ?? this.id,
      diagramNumber: diagramNumber ?? this.diagramNumber,
      title: title ?? this.title,
      imageAssetPath: imageAssetPath ?? this.imageAssetPath,
      labeledImageAssetPath: labeledImageAssetPath ?? this.labeledImageAssetPath,
      unitId: unitId ?? this.unitId,
      labels: labels ?? this.labels,
      totalSteps: totalSteps ?? this.totalSteps
    );
  }
}