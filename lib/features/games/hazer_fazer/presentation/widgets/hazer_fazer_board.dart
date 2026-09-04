import 'package:flutter/material.dart';
import '../../domain/entities/saint_picture.dart';

class HazerFazerBoard extends StatelessWidget {
  final SaintPicture saint;
  final int tileCount;
  final Set<int> revealedTiles;
  final bool isWon;
  final ValueChanged<int> onTileTap;
  final bool isInteractive;
  final bool isActiveTeam;
  final String? teamNameLabel;
  final Color? teamColor;

  const HazerFazerBoard({
    super.key,
    required this.saint,
    required this.tileCount,
    required this.revealedTiles,
    required this.isWon,
    required this.onTileTap,
    this.isInteractive = true,
    this.isActiveTeam = true,
    this.teamNameLabel,
    this.teamColor,
  });

  (int, int) _getGridDimensions() {
    switch (tileCount) {
      case 4:
        return (2, 2);
      case 6:
        return (2, 3); // 2 rows, 3 cols
      case 9:
        return (3, 3);
      case 12:
        return (3, 4); // 3 rows, 4 cols
      case 16:
        return (4, 4);
      case 20:
        return (4, 5); // 4 rows, 5 cols
      case 25:
        return (5, 5);
      default:
        return (3, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dims = _getGridDimensions();
    final rows = dims.$1;
    final cols = dims.$2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = constraints.maxHeight.isFinite ? (constraints.maxHeight - 12) : 550.0;
        final availableW = constraints.maxWidth.isFinite ? (constraints.maxWidth - 24) : 550.0;
        final targetRatio = cols / rows;

        double boardWidth;
        double boardHeight;
        if (availableW / availableH > targetRatio) {
          boardHeight = availableH.clamp(160.0, 700.0);
          boardWidth = boardHeight * targetRatio;
        } else {
          boardWidth = availableW.clamp(160.0, 700.0);
          boardHeight = boardWidth / targetRatio;
        }

        final activeColor = teamColor ?? Colors.amberAccent;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team Badge Header for Multi-Board View
            if (teamNameLabel != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isActiveTeam ? activeColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActiveTeam ? activeColor : Colors.white24,
                    width: isActiveTeam ? 2 : 1,
                  ),
                  boxShadow: isActiveTeam
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isActiveTeam) ...[
                      const Icon(Icons.star_rounded, color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      teamNameLabel!,
                      style: TextStyle(
                        color: isActiveTeam ? Colors.amberAccent : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${revealedTiles.length} من $tileCount)',
                      style: TextStyle(
                        color: isActiveTeam ? Colors.white : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // The Board Container - Always 100% opaque to prevent any transparency leaks
            Center(
              child: Container(
                width: boardWidth,
                height: boardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isWon
                        ? Colors.amberAccent
                        : (isActiveTeam ? activeColor : Colors.white24),
                    width: isWon ? 4 : (isActiveTeam ? 3 : 1.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isWon
                          ? Colors.amberAccent.withValues(alpha: 0.35)
                          : (isActiveTeam
                              ? activeColor.withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.3)),
                      blurRadius: isWon || isActiveTeam ? 28 : 14,
                      spreadRadius: isWon || isActiveTeam ? 3 : 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Base Layer: Saint Picture stretched to fill container completely
                      saint.buildImage(fit: BoxFit.fill),

                      // Overlay Layer: The Grid of Tiles covering the image
                      if (!isWon)
                        Positioned.fill(
                          child: Column(
                            children: List.generate(rows, (r) {
                              return Expanded(
                                child: Row(
                                  children: List.generate(cols, (c) {
                                    final index = r * cols + c;
                                    if (index >= tileCount) {
                                      return const Expanded(child: SizedBox.shrink());
                                    }
                                    final isRevealed = revealedTiles.contains(index);

                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.all(1.5),
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 350),
                                          transitionBuilder: (child, anim) => FadeTransition(
                                            opacity: anim,
                                            child: ScaleTransition(scale: anim, child: child),
                                          ),
                                          child: isRevealed
                                              ? const SizedBox.shrink()
                                              : _buildTile(context, index, activeColor),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTile(BuildContext context, int index, Color accentColor) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? () => onTileTap(index) : null,
        borderRadius: BorderRadius.circular(10),
        hoverColor: isInteractive ? Colors.amberAccent.withValues(alpha: 0.15) : Colors.transparent,
        splashColor: isInteractive ? Colors.amberAccent.withValues(alpha: 0.3) : Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            // 100% Solid, completely opaque colors so image is NEVER visible through covered tiles
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isInteractive
                  ? const [
                      Color(0xFF2D3754), // 100% solid slate blue
                      Color(0xFF1A1F30), // 100% solid dark slate
                    ]
                  : const [
                      Color(0xFF252C3E), // 100% solid muted slate
                      Color(0xFF171924), // 100% solid muted dark
                    ],
            ),
            border: Border.all(
              color: isInteractive
                  ? accentColor.withValues(alpha: 0.55)
                  : Colors.white24,
              width: isInteractive ? 1.5 : 1.0,
            ),
            boxShadow: isInteractive
                ? const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isInteractive
                        ? accentColor.withValues(alpha: 0.15)
                        : Colors.white10,
                    border: Border.all(
                      color: isInteractive ? accentColor.withValues(alpha: 0.7) : Colors.white24,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isInteractive ? accentColor : Colors.white54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Icon(
                  Icons.help_outline_rounded,
                  size: 13,
                  color: isInteractive ? Colors.white54 : Colors.white24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
