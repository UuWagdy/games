import 'dart:typed_data';

enum QuestionType {
  essay,
  multipleChoice,
  trueFalse,
  grid,
}

class Question {
  final int? id;
  final String text;
  final String answer;
  final QuestionType type;
  final List<int> categoryIds;
  final List<int> usedInCategoryIds;
  final String? imagePath;
  final Uint8List? imageData;
  final List<String>? options;
  final List<int>? correctOptionIndices; // For MCQ single/multiple
  final bool? tfValue; // For True/False
  final Map<String, dynamic>? gridData; // For Grid (rows, cols, correctCells)
  final bool isMultiple; // For MCQ and Grid: Single vs Multiple choice

  Question({
    this.id,
    required this.text,
    required this.answer,
    this.type = QuestionType.essay,
    this.categoryIds = const [],
    this.usedInCategoryIds = const [],
    this.imagePath,
    this.imageData,
    this.options,
    this.correctOptionIndices,
    this.tfValue,
    this.gridData,
    this.isMultiple = false,
  });

  bool isUsedIn(int categoryId) => usedInCategoryIds.contains(categoryId);

  Question copyWith({
    int? id,
    String? text,
    String? answer,
    QuestionType? type,
    List<int>? categoryIds,
    List<int>? usedInCategoryIds,
    String? imagePath,
    Uint8List? imageData,
    List<String>? options,
    List<int>? correctOptionIndices,
    bool? tfValue,
    Map<String, dynamic>? gridData,
    bool? isMultiple,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      answer: answer ?? this.answer,
      type: type ?? this.type,
      categoryIds: categoryIds ?? this.categoryIds,
      usedInCategoryIds: usedInCategoryIds ?? this.usedInCategoryIds,
      imagePath: imagePath ?? this.imagePath,
      imageData: imageData ?? this.imageData,
      options: options ?? this.options,
      correctOptionIndices: correctOptionIndices ?? this.correctOptionIndices,
      tfValue: tfValue ?? this.tfValue,
      gridData: gridData ?? this.gridData,
      isMultiple: isMultiple ?? this.isMultiple,
    );
  }
}
