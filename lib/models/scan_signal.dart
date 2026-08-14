enum TradeDirection {
  buy,
  sell,
  wait,
}

class ScanSignal {
  final String symbol;
  final TradeDirection direction;
  final double confidence;
  final double score;
  final double entry;
  final double stopLoss;
  final double takeProfit1;
  final double takeProfit2;
  final double takeProfit3;
  final String trend;
  final String momentum;
  final String setup;
  final DateTime timestamp;

  const ScanSignal({
    required this.symbol,
    required this.direction,
    required this.confidence,
    required this.score,
    required this.entry,
    required this.stopLoss,
    required this.takeProfit1,
    required this.takeProfit2,
    required this.takeProfit3,
    required this.trend,
    required this.momentum,
    required this.setup,
    required this.timestamp,
  });

  /// Age of this signal using the live market timestamp.
  Duration get age => DateTime.now().difference(timestamp);

  /// 1-minute trade signals must not remain actionable indefinitely.
  bool get isExpired => age.inSeconds >= 60;

  /// Entry timing for the current 1-minute setup.
  ///
  /// 0-20 sec  = ideal entry window
  /// 21-45 sec = wait for a fresh confirmation
  /// 46-59 sec = skip because the setup is too late
  /// 60+ sec   = expired
  String get entryTimingText {
    if (direction == TradeDirection.wait) return 'WAIT';

    final seconds = age.inSeconds;

    if (seconds < 0) return 'WAIT';
    if (seconds <= 20) return 'ENTER NOW';
    if (seconds <= 45) return 'WAIT';
    if (seconds < 60) return 'SKIP';

    return 'EXPIRED';
  }

  bool get canEnterNow =>
      !isExpired &&
      direction != TradeDirection.wait &&
      entryTimingText == 'ENTER NOW';

  String get directionText {
    if (isExpired && direction != TradeDirection.wait) {
      return 'SKIP • EXPIRED';
    }

    switch (direction) {
      case TradeDirection.buy:
        return 'BUY • $entryTimingText';
      case TradeDirection.sell:
        return 'SELL • $entryTimingText';
      case TradeDirection.wait:
        return 'WAIT';
    }
  }
}
