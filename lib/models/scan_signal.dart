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

  String get directionText {
    switch (direction) {
      case TradeDirection.buy:
        return 'BUY';
      case TradeDirection.sell:
        return 'SELL';
      case TradeDirection.wait:
        return 'WAIT';
    }
  }
}
