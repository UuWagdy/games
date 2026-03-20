import 'package:flutter/material.dart';
import '../../domain/entities/penalty_shootout_state.dart';

class PenaltyScoreboard extends StatelessWidget {
  final PenaltyShootoutState gameState;

  const PenaltyScoreboard({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    bool isSmall = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: isSmall ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: _buildTeamInfo(
              context,
              gameState.teamA?.name ?? 'الفريق أ', 
              gameState.teamAScore, 
              gameState.teamAAttempts, 
              Colors.blueAccent,
              gameState.currentTurn == PenaltyTurn.teamA,
              gameState.teamA?.score ?? 0,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('VS', style: TextStyle(color: Colors.amber, fontSize: isSmall ? 14 : 18, fontWeight: FontWeight.w900)),
            ),
          ),
          Expanded(
            child: _buildTeamInfo(
              context,
              gameState.teamB?.name ?? 'الفريق ب', 
              gameState.teamBScore, 
              gameState.teamBAttempts, 
              Colors.redAccent,
              gameState.currentTurn == PenaltyTurn.teamB,
              gameState.teamB?.score ?? 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(BuildContext context, String name, int score, List<bool?> attempts, Color color, bool isCurrent, int totalScore) {
    bool isSmall = MediaQuery.of(context).size.width < 600;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name, 
          style: TextStyle(
            color: color, 
            fontSize: isSmall ? 14 : 18, 
            fontWeight: FontWeight.w900,
            shadows: isCurrent ? [Shadow(color: color.withOpacity(0.5), blurRadius: 10)] : [],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          'الإجمالي: $totalScore',
          style: TextStyle(color: Colors.white70, fontSize: isSmall ? 10 : 12, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: isSmall ? 2 : 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 20, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '$score', 
            style: TextStyle(color: Colors.white, fontSize: isSmall ? 24 : 36, fontWeight: FontWeight.w900)
          ),
        ),
        SizedBox(height: isSmall ? 4 : 8),
        Wrap(
          spacing: 4,
          alignment: WrapAlignment.center,
          children: attempts.take(5).map((a) => _buildIndicator(a, isSmall)).toList(),
        ),
        if (attempts.length > 5) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            alignment: WrapAlignment.center,
            children: attempts.skip(5).map((a) => _buildIndicator(a, isSmall)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildIndicator(bool? result, bool isSmall) {
    IconData icon = Icons.circle;
    Color color = Colors.white10;
    if (result == true) {
      icon = Icons.sports_soccer;
      color = Colors.greenAccent;
    } else if (result == false) {
      icon = Icons.close;
      color = Colors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: result != null ? color.withOpacity(0.1) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: isSmall ? 14 : 18),
    );
  }
}
