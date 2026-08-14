class DukeAnalysis {
  final String symbol;
  final String decision;
  final double confidence;
  final double trendScore;
  final double momentumScore;
  final double volatilityScore;
  final double structureScore;
  final String explanation;

  const DukeAnalysis({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.trendScore,
    required this.momentumScore,
    required this.volatilityScore,
    required this.structureScore,
    required this.explanation,
  });
}

class AgentDukeIntelligence {
  const AgentDukeIntelligence();

  DukeAnalysis analyze({
    required String symbol,
    required double trend,
    required double momentum,
    required double volatility,
    required double structure,
  }) {
    final score = (trend * 0.35) +
        (momentum * 0.30) +
        (structure * 0.25) +
        (volatility * 0.10);

    final confidence = score.abs().clamp(0.0, 100.0);

    String decision;

    if (score >= 60) {
      decision = 'BUY';
    } else if (score <= -60) {
      decision = 'SELL';
    } else {
      decision = 'WAIT';
    }

    return DukeAnalysis(
      symbol: symbol,
      decision: decision,
      confidence: confidence,
      trendScore: trend,
      momentumScore: momentum,
      volatilityScore: volatility,
      structureScore: structure,
      explanation: 'Agent Duke Da Boss X analyzed trend, momentum, volatility, '
          'and market structure. Composite intelligence score: '
          '${score.toStringAsFixed(1)}.',
    );
  }
}
