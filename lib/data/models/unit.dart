class Unit {
  final int id;
  final String title;

  Unit({
    required this.id,
    required this.title,
  });

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      title: map['title'],
    );
  }
}