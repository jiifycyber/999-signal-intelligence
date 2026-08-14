import '../models/scan_signal.dart';
import 'agent_duke_multitimeframe.dart';
import 'agent_duke_master_engine.dart';

class AgentDukeScannerBridge {
  final AgentDukeMasterEngine duke;

  AgentDukeScannerBridge({
    AgentDukeMasterEngine? duke,
  }) : duke = duke ?? AgentDukeMasterEngine();

  DukeMasterResult analyzeSignal(ScanSignal signal) {
    final directionBias = switch (signal.direction) {
      TradeDirection.buy => 1.0,
      TradeDirection.sell => -1.0,
      TradeDirection.wait => 0.0,
    };

    final confidence = signal.confidence.clamp(0.0, 100.0).toDouble();

    final trendStrength = _signedScore(signal.trend, directionBias, confidence);

    final momentumStrength =
        _signedScore(signal.momentum, directionBias, confidence);

    final structureStrength =
        _setupScore(signal.setup, directionBias, confidence);

    final volatilityStrength = (confidence * 0.70).clamp(0.0, 100.0).toDouble();

    final oneMinute = DukeTimeframeInput(
      timeframe: '1M',
      trend: trendStrength * 0.90,
      momentum: momentumStrength,
      structure: structureStrength * 0.85,
      volatility: volatilityStrength,
    );

    final fiveMinute = DukeTimeframeInput(
      timeframe: '5M',
      trend: trendStrength,
      momentum: momentumStrength * 0.95,
      structure: structureStrength,
      volatility: volatilityStrength,
    );

    final fifteenMinute = DukeTimeframeInput(
      timeframe: '15M',
      trend: trendStrength * 1.05,
      momentum: momentumStrength * 0.90,
      structure: structureStrength,
      volatility: volatilityStrength,
    );

    return duke.analyze(
      DukeMasterInput(
        symbol: signal.symbol,
        currentPrice: signal.entry,
        oneMinute: oneMinute,
        fiveMinute: fiveMinute,
        fifteenMinute: fifteenMinute,
        spreadQuality: confidence,
        structureQuality: structureStrength.abs(),
        trendStrength: trendStrength,
        volatility: volatilityStrength,
      ),
    );
  }

  double _signedScore(
    String value,
    double directionBias,
    double confidence,
  ) {
    final text = value.toLowerCase();
    double strength = confidence;

    if (text.contains('strong')) strength += 8;
    if (text.contains('weak')) strength -= 15;

    if (text.contains('bull')) {
      return strength.abs().clamp(0.0, 100.0).toDouble();
    }

    if (text.contains('bear')) {
      return -strength.abs().clamp(0.0, 100.0).toDouble();
    }

    return (strength * directionBias).clamp(-100.0, 100.0).toDouble();
  }

  double _setupScore(
    String setup,
    double directionBias,
    double confidence,
  ) {
    final text = setup.toLowerCase();
    double score = confidence;

    if (text.contains('breakout') ||
        text.contains('continuation') ||
        text.contains('reversal') ||
        text.contains('liquidity') ||
        text.contains('structure')) {
      score += 5;
    }

    return (score * directionBias).clamp(-100.0, 100.0).toDouble();
  }
}
