enum LudoColor { red, green, yellow, blue }

enum LudoGameState {
  idle,
  rolling,
  result, // Viewing the result
  choosingToken,
  answeringQuestion,
  moving,
  gameOver,
}

enum QuestionTriggerType {
  exit,
  pass,
  protect, // Safe Zone (Star)
  attack,  // Capture Opponent
  vision,  // Moving to home directly
}

// Global settings for Vision Mode scope
enum VisionModeScope {
  token,  // Each token can use it independently
  player, // Only once per player for the whole game
}

extension QuestionTriggerExtension on QuestionTriggerType {
  String get categoryLabel {
    switch (this) {
      case QuestionTriggerType.exit: return "سؤال الخروج";
      case QuestionTriggerType.pass: return "سؤال العبور";
      case QuestionTriggerType.protect: return "سؤال الحماية";
      case QuestionTriggerType.attack: return "سؤال الهجوم";
      case QuestionTriggerType.vision: return "سؤال الرؤية";
    }
  }
}

class LudoToken {
  final int id;
  final LudoColor color;
  final int position; // -1: Base, 0-51: Main path, 52-56: Home path, 57: Finished
  final bool isProtected;
  final bool isVisionModeUnlocked;

  LudoToken({
    required this.id,
    required this.color,
    required this.position,
    this.isProtected = false,
    this.isVisionModeUnlocked = false,
  });

  LudoToken copyWith({
    int? position,
    bool? isProtected,
    bool? isVisionModeUnlocked,
  }) {
    return LudoToken(
      id: id,
      color: color,
      position: position ?? this.position,
      isProtected: isProtected ?? this.isProtected,
      isVisionModeUnlocked: isVisionModeUnlocked ?? this.isVisionModeUnlocked,
    );
  }
}

class LudoPlayer {
  final LudoColor color;
  final List<LudoToken> tokens;
  final int score;
  final bool hasUsedVision; // Used for "Per Player" vision scope
  final bool isComputer;

  LudoPlayer({
    required this.color,
    required this.tokens,
    this.score = 0,
    this.hasUsedVision = false,
    this.isComputer = false,
  });

  bool get isWinner => tokens.every((t) => t.position == 57);

  LudoPlayer copyWith({
    List<LudoToken>? tokens,
    int? score,
    bool? hasUsedVision,
    bool? isComputer,
  }) {
    return LudoPlayer(
      color: color,
      tokens: tokens ?? this.tokens,
      score: score ?? this.score,
      hasUsedVision: hasUsedVision ?? this.hasUsedVision,
      isComputer: isComputer ?? this.isComputer,
    );
  }
}
