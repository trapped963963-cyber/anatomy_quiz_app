class Label {
  final int id;
  final int diagramId;
  final int labelNumber;
  final String title;
  final String definition;

  Label({
    required this.id,
    required this.diagramId,
    required this.labelNumber,
    required this.title,
    required this.definition,
  });

  factory Label.fromMap(Map<String, dynamic> map) {
    return Label(
      id: map['id'],
      diagramId: map['diagram_id'],
      labelNumber: map['label_number'],
      title: map['title'],
      definition: map['definition'],
    );
  }

  // It's good practice to add a copyWith for immutability, though not strictly required for this step
  Label copyWith({
    int? id,
    int? diagramId,
    int? labelNumber,
    String? title,
    String? definition,
  }) {
    return Label(
      id: id ?? this.id,
      diagramId: diagramId ?? this.diagramId,
      labelNumber: labelNumber ?? this.labelNumber,
      title: title ?? this.title,
      definition: definition ?? this.definition,
    );
  }
}