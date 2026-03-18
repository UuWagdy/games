class Question {
  final int? id;
  final String text;
  final String answer;
  final int categoryId;

  Question({
    this.id,
    required this.text,
    required this.answer,
    required this.categoryId,
  });
}
