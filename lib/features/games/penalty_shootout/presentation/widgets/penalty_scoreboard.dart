import 'package:flutter/material.dart';
import '../../domain/entities/penalty_shootout_state.dart';

class PenaltyScoreboard extends StatelessWidget {
  final PenaltyShootoutState gameState;

  const PenaltyScoreboard({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTeamInfo(
            gameState.teamA?.name ?? 'Team A', 
            gameState.teamAScore, 
            gameState.teamAAttempts, 
            Colors.blue,
            gameState.currentTurn == PenaltyTurn.teamA,
          ),
          const Text('VS', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          _buildTeamInfo(
            gameState.teamB?.name ?? 'Team B', 
            gameState.teamBScore, 
            gameState.teamBAttempts, 
            Colors.red,
            gameState.currentTurn == PenaltyTurn.teamB,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(String name, int score, List<bool?> attempts, Color color, bool isCurrent) {
    return Column(
      children: [
        Text(
          name, 
          style: TextStyle(
            color: color, 
            fontSize: 24, 
            fontWeight: FontWeight.bold,
            shadows: isCurrent ? [const Shadow(color: Colors.white, blurRadius: 10)] : [],
          )
        ),
        Text(
          '$score', 
          style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)
        ),
        Row(
          children: attempts.take(5).map((a) => _buildIndicator(a)).toList(),
        ),
        if (attempts.length > 5) // Sudden Death indicators
          Row(
            children: attempts.skip(5).map((a) => _buildIndicator(a)).toList(),
          ),
      ],
    );
  }

  Widget _buildIndicator(bool? result) {
    IconData icon = Icons.circle;
    Color color = Colors.grey;
    if (result == true) {
      icon = Icons.sports_soccer;
      color = Colors.green;
    } else if (result == false) {
      icon = Icons.close;
      color = Colors.red;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
