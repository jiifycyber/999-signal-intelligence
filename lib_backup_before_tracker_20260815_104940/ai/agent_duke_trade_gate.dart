class DukeTradeGateInput {
  final String symbol;
  final String proposedDecision;
  final double confidence;
  final double trendStrength;
  final double volatility;
  final double spreadQuality;
  final double structureQuality;
  final bool multiTimeframeAligned;

  const DukeTradeGateInput({
    required this.symbol,
    required this.proposedDecision,
    required this.confidence,
    required this.trendStrength,
    required this.volatility,
    required this.spreadQuality,
    required this.structureQuality,
    required this.multiTimeframeAligned,
  });
}

class DukeTradeGateResult {
  final String symbol;
  final String finalDecision;
  final bool tradeApproved;
  final double qualityScore;
  final List<String> reasons;

  const DukeTradeGateResult({
    required this.symbol,
    required this.finalDecision,
    required this.tradeApproved,
    required this.qualityScore,
    required this.reasons,
  });
}

class AgentDukeTradeGate {
  const AgentDukeTradeGate();

  DukeTradeGateResult evaluate(DukeTradeGateInput input) {
    final reasons = <String>[];

    final qualityScore = (input.confidence * 0.35) +
        (input.trendStrength.abs() * 0.20) +
        (input.spreadQuality * 0.15) +
        (input.structureQuality * 0.20) +
        ((input.multiTimeframeAligned ? 100.0 : 0.0) * 0.10);

    if (input.proposedDecision == 'WAIT') {
      reasons.add('No directional setup passed the decision threshold.');
    }

    if (input.confidence < 60) {
      reasons.add('Confidence below minimum trade threshold.');
    }

    if (!input.multiTimeframeAligned) {
      reasons.add('Timeframes are not sufficiently aligned.');
    }

    if (input.trendStrength.abs() < 35) {
      reasons.add('Trend strength is weak.');
    }

    if (input.structureQuality < 55) {
      reasons.add('Market structure quality is weak.');
    }

    if (input.spreadQuality < 50) {
      reasons.add('Execution/spread quality is unfavorable.');
    }

    if (input.volatility > 90) {
      reasons.add('Volatility is excessively high.');
    }

    final approved = input.proposedDecision != 'WAIT' &&
        input.confidence >= 60 &&
        input.multiTimeframeAligned &&
        input.trendStrength.abs() >= 35 &&
        input.structureQuality >= 55 &&
        input.spreadQuality >= 50 &&
        input.volatility <= 90 &&
        qualityScore >= 60;

    return DukeTradeGateResult(
      symbol: input.symbol,
      finalDecision: approved ? input.proposedDecision : 'WAIT',
      tradeApproved: approved,
      qualityScore: qualityScore.clamp(0.0, 100.0),
      reasons: reasons,
    );
  }
}
