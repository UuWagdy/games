class Category {
  final int? id;
  final String name;
  final int? questionsCount;

  Category({this.id, required this.name, this.questionsCount});

  Category copyWith({
    int? id,
    String? name,
    int? questionsCount,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      questionsCount: questionsCount ?? this.questionsCount,
    );
  }
}
