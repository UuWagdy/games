import '../entities/ludo_entities.dart';

class LudoState {
  final List<LudoPlayer> players;
  final int currentTurn;
  final int diceValue;
  final LudoGameState phase;
  final List<LudoToken> selectableTokens;
  final LudoToken? movingToken;
  final int remainingMoveSteps;
  final QuestionTriggerType? currentQuestionTrigger;
  final List<LudoToken>? targetedTokens;
  final int winPoints;
  final List<LudoColor> activeColors;
  
  final bool isTeamMode;
  final Map<LudoColor, int> playerTeams;
  
  final Map<QuestionTriggerType, List<int>> triggerCategories;
  final Map<QuestionTriggerType, bool> triggerEnabled;
  final Map<LudoColor, String> colorTeamNames;
  
  // Vision mode settings
  final bool isVisionModeEnabled;
  final VisionModeScope visionModeScope;
  
  // Exit numbers (e.g. 1, 3, 5)
  final List<int> exitNumbers;
  final bool isDoubleMoveEnabled;
  final bool hasUsedDoubleMoveInTurn;

  const LudoState({
    required this.players,
    required this.currentTurn,
    this.diceValue = 0,
    this.phase = LudoGameState.idle,
    this.selectableTokens = const [],
    this.movingToken,
    this.remainingMoveSteps = 0,
    this.currentQuestionTrigger,
    this.targetedTokens,
    this.winPoints = 100,
    this.activeColors = const [LudoColor.red, LudoColor.green, LudoColor.yellow, LudoColor.blue],
    this.isTeamMode = false,
    this.playerTeams = const {},
    this.triggerCategories = const {},
    this.triggerEnabled = const {
      QuestionTriggerType.exit: true,
      QuestionTriggerType.pass: true,
      QuestionTriggerType.attack: true,
      QuestionTriggerType.protect: true,
      QuestionTriggerType.vision: true,
    },
    this.colorTeamNames = const {},
    this.isVisionModeEnabled = true,
    this.visionModeScope = VisionModeScope.token,
    this.exitNumbers = const [1, 3, 5],
    this.isDoubleMoveEnabled = false,
    this.hasUsedDoubleMoveInTurn = false,
  });

  LudoPlayer get currentPlayer => players.isNotEmpty ? players[currentTurn] : LudoPlayer(color: LudoColor.red, tokens: []);

  LudoState copyWith({
    List<LudoPlayer>? players,
    int? currentTurn,
    int? diceValue,
    LudoGameState? phase,
    List<LudoToken>? selectableTokens,
    LudoToken? movingToken,
    int? remainingMoveSteps,
    QuestionTriggerType? currentQuestionTrigger,
    List<LudoToken>? targetedTokens,
    int? winPoints,
    List<LudoColor>? activeColors,
    bool? isTeamMode,
    Map<LudoColor, int>? playerTeams,
    Map<QuestionTriggerType, List<int>>? triggerCategories,
    Map<QuestionTriggerType, bool>? triggerEnabled,
    Map<LudoColor, String>? colorTeamNames,
    bool? isVisionModeEnabled,
    VisionModeScope? visionModeScope,
    List<int>? exitNumbers,
    bool? isDoubleMoveEnabled,
    bool? hasUsedDoubleMoveInTurn,
  }) {
    return LudoState(
      players: players ?? this.players,
      currentTurn: currentTurn ?? this.currentTurn,
      diceValue: diceValue ?? this.diceValue,
      phase: phase ?? this.phase,
      selectableTokens: selectableTokens ?? this.selectableTokens,
      movingToken: movingToken ?? this.movingToken,
      remainingMoveSteps: remainingMoveSteps ?? this.remainingMoveSteps,
      currentQuestionTrigger: currentQuestionTrigger ?? this.currentQuestionTrigger,
      targetedTokens: targetedTokens ?? this.targetedTokens,
      winPoints: winPoints ?? this.winPoints,
      activeColors: activeColors ?? this.activeColors,
      isTeamMode: isTeamMode ?? this.isTeamMode,
      playerTeams: playerTeams ?? this.playerTeams,
      triggerCategories: triggerCategories ?? this.triggerCategories,
      triggerEnabled: triggerEnabled ?? this.triggerEnabled,
      colorTeamNames: colorTeamNames ?? this.colorTeamNames,
      isVisionModeEnabled: isVisionModeEnabled ?? this.isVisionModeEnabled,
      visionModeScope: visionModeScope ?? this.visionModeScope,
      exitNumbers: exitNumbers ?? this.exitNumbers,
      isDoubleMoveEnabled: isDoubleMoveEnabled ?? this.isDoubleMoveEnabled,
      hasUsedDoubleMoveInTurn: hasUsedDoubleMoveInTurn ?? this.hasUsedDoubleMoveInTurn,
    );
  }
}
