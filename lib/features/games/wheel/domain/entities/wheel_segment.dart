class WheelSegment {
  final int? id;
  final String text;
  final int points;
  final bool isQuestion;
  final int? categoryId;

  WheelSegment({
    this.id,
    required this.text,
    required this.points,
    this.isQuestion = false,
    this.categoryId,
  });
}
