class DukeTimeframeInput {
  final String timeframe;
  final double trend;
  final double momentum;
  final double structure;
  final double volatility;

  const DukeTimeframeInput({
    required this.timeframe,
    required this.trend,
    required this.momentum,
    required this.structure,
    required this.volatility,
  });

  double get score =>
      (trend * 0.35) +
      (momentum * 0.30) +
      (structure * 0.25) +
      (volatility * 0.10);
}

class DukeMultiTimeframeResult {
  final String symbol;
  final String decision;
  final double confidence;
  final double oneMinuteScore;
  final double fiveMinuteScore;
  final double fifteenMinuteScore;
  final int bullishTimeframes;
  final int bearishTimeframes;
  final String explanation;

  const DukeMultiTimeframeResult({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.oneMinuteScore,
    required this.fiveMinuteScore,
    required this.fifteenMinuteScore,
    required this.bullishTimeframes,
    required this.bearishTimeframes,
    required this.explanation,
  });
}

class AgentDukeMultiTimeframe {
  const AgentDukeMultiTimeframe();

  DukeMultiTimeframeResult analyze({
    required String symbol,
    required DukeTimeframeInput oneMinute,
    required DukeTimeframeInput fiveMinute,
    required DukeTimeframeInput fifteenMinute,
  }) {
    final s1 = oneMinute.score;
    final s5 = fiveMinute.score;
    final s15 = fifteenMinute.score;

    final scores = [s1, s5, s15];

    final bullish = scores.where((score) => score >= 35).length;
    final bearish = scores.where((score) => score <= -35).length;

    final weightedScore = (s1 * 0.25) + (s5 * 0.35) + (s15 * 0.40);

    String decision = 'WAIT';

    if (bullish >= 2 && weightedScore >= 45) {
      decision = 'BUY';
    } else if (bearish >= 2 && weightedScore <= -45) {
      decision = 'SELL';
    }

    double alignmentBonus = 0;

    if (bullish == 3 || bearish == 3) {
      alignmentBonus = 12;
    } else if (bullish == 2 || bearish == 2) {
      alignmentBonus = 6;
    }

    final confidence = (weightedScore.abs() + alignmentBonus).clamp(0.0, 100.0);

    return DukeMultiTimeframeResult(
      symbol: symbol,
      decision: decision,
      confidence: confidence,
      oneMinuteScore: s1,
      fiveMinuteScore: s5,
      fifteenMinuteScore: s15,
      bullishTimeframes: bullish,
      bearishTimeframes: bearish,
      explanation: 'Agent Duke Da Boss X checked 1M, 5M, and 15M alignment. '
          '$bullish bullish timeframe(s), $bearish bearish timeframe(s). '
          'Weighted score: ${weightedScore.toStringAsFixed(1)}. '
          'Decision: $decision.',
    );
  }
}
