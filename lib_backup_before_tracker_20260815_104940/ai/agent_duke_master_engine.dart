import 'agent_duke_adaptive_weights.dart';
import 'agent_duke_multitimeframe.dart';
import 'agent_duke_signal_memory.dart';
import 'agent_duke_trade_gate.dart';

class DukeMasterInput {
  final String symbol;
  final double currentPrice;

  final DukeTimeframeInput oneMinute;
  final DukeTimeframeInput fiveMinute;
  final DukeTimeframeInput fifteenMinute;

  final double spreadQuality;
  final double structureQuality;
  final double trendStrength;
  final double volatility;

  const DukeMasterInput({
    required this.symbol,
    required this.currentPrice,
    required this.oneMinute,
    required this.fiveMinute,
    required this.fifteenMinute,
    required this.spreadQuality,
    required this.structureQuality,
    required this.trendStrength,
    required this.volatility,
  });
}

class DukeMasterResult {
  final String symbol;
  final String decision;
  final double confidence;
  final double qualityScore;
  final bool tradeApproved;
  final String explanation;
  final DukeSignalRecord? signalRecord;

  const DukeMasterResult({
    required this.symbol,
    required this.decision,
    required this.confidence,
    required this.qualityScore,
    required this.tradeApproved,
    required this.explanation,
    required this.signalRecord,
  });
}

class AgentDukeMasterEngine {
  final AgentDukeMultiTimeframe multiTimeframe;
  final AgentDukeTradeGate tradeGate;
  final AgentDukeSignalMemory signalMemory;
  final DukeAdaptiveWeights adaptiveWeights;

  AgentDukeMasterEngine({
    AgentDukeMultiTimeframe? multiTimeframe,
    AgentDukeTradeGate? tradeGate,
    AgentDukeSignalMemory? signalMemory,
    DukeAdaptiveWeights? adaptiveWeights,
  })  : multiTimeframe = multiTimeframe ?? const AgentDukeMultiTimeframe(),
        tradeGate = tradeGate ?? const AgentDukeTradeGate(),
        signalMemory = signalMemory ?? AgentDukeSignalMemory(),
        adaptiveWeights = adaptiveWeights ?? DukeAdaptiveWeights();

  DukeMasterResult analyze(DukeMasterInput input) {
    final timeframeResult = multiTimeframe.analyze(
      symbol: input.symbol,
      oneMinute: input.oneMinute,
      fiveMinute: input.fiveMinute,
      fifteenMinute: input.fifteenMinute,
    );

    final aligned = timeframeResult.bullishTimeframes >= 2 ||
        timeframeResult.bearishTimeframes >= 2;

    final gateResult = tradeGate.evaluate(
      DukeTradeGateInput(
        symbol: input.symbol,
        proposedDecision: timeframeResult.decision,
        confidence: timeframeResult.confidence,
        trendStrength: input.trendStrength,
        volatility: input.volatility,
        spreadQuality: input.spreadQuality,
        structureQuality: input.structureQuality,
        multiTimeframeAligned: aligned,
      ),
    );

    DukeSignalRecord? record;

    if (gateResult.tradeApproved) {
      record = signalMemory.recordSignal(
        symbol: input.symbol,
        decision: gateResult.finalDecision,
        confidence: timeframeResult.confidence,
        entryPrice: input.currentPrice,
      );
    }

    final explanation = gateResult.tradeApproved
        ? 'Agent Duke Da Boss X approved ${gateResult.finalDecision} on '
            '${input.symbol}. Multi-timeframe confirmation passed with '
            '${timeframeResult.confidence.toStringAsFixed(1)}% confidence '
            'and ${gateResult.qualityScore.toStringAsFixed(1)} quality.'
        : 'Agent Duke Da Boss X rejected the trade on ${input.symbol}. '
            '${gateResult.reasons.join(' ')}';

    return DukeMasterResult(
      symbol: input.symbol,
      decision: gateResult.finalDecision,
      confidence: timeframeResult.confidence,
      qualityScore: gateResult.qualityScore,
      tradeApproved: gateResult.tradeApproved,
      explanation: explanation,
      signalRecord: record,
    );
  }

  DukeSignalRecord? closeSignal({
    required String id,
    required double exitPrice,
  }) {
    return signalMemory.closeSignal(
      id: id,
      exitPrice: exitPrice,
    );
  }

  DukePerformanceSummary performance() {
    return signalMemory.performance();
  }

  Map<String, double> learningWeights() {
    return adaptiveWeights.snapshot();
  }
}
