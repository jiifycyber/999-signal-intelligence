import 'dart:math';

import '../models/forex_quote.dart';
import '../models/scan_signal.dart';

class ScannerEngine {
  final Map<String, List<double>> _history = {};

  List<ScanSignal> analyze(List<ForexQuote> quotes) {
    final results = <ScanSignal>[];

    for (final quote in quotes) {
      final prices = _history.putIfAbsent(
        quote.symbol,
        () => <double>[],
      );

      prices.add(quote.price);

      if (prices.length > 200) {
        prices.removeAt(0);
      }

      results.add(_analyzePair(quote, prices));
    }

    results.sort(
      (a, b) => b.confidence.compareTo(a.confidence),
    );

    return results;
  }

  ScanSignal _analyzePair(
    ForexQuote quote,
    List<double> prices,
  ) {
    final fast = _ema(prices, 9);
    final slow = _ema(prices, 21);
    final longTrend = _ema(prices, 50);
    final rsi = _rsi(prices, 14);

    double bullishScore = 0;
    double bearishScore = 0;

    if (fast > slow) {
      bullishScore += 25;
    } else if (fast < slow) {
      bearishScore += 25;
    }

    if (slow > longTrend) {
      bullishScore += 20;
    } else if (slow < longTrend) {
      bearishScore += 20;
    }

    if (quote.price > fast) {
      bullishScore += 15;
    } else {
      bearishScore += 15;
    }

    if (rsi >= 52 && rsi <= 70) {
      bullishScore += 20;
    }

    if (rsi <= 48 && rsi >= 30) {
      bearishScore += 20;
    }

    if (quote.price > quote.open) {
      bullishScore += 10;
    } else if (quote.price < quote.open) {
      bearishScore += 10;
    }

    final winningScore = max(
      bullishScore,
      bearishScore,
    );

    final scoreGap = (bullishScore - bearishScore).abs();

    TradeDirection direction;

    // 999 Signal Intelligence confirmation gate:
    // Require both a strong score and clear separation between BUY and SELL.
    // 999 Intelligence V3 confirmation gate.
    //
    // A trade requires:
    // 1. Strong absolute setup score.
    // 2. Clear directional separation.
    // 3. Extra separation for marginal setups.
    //
    // Mixed markets automatically remain WAIT.
    final requiredGap = winningScore >= 80
        ? 15.0
        : winningScore >= 70
            ? 20.0
            : 25.0;

    if (winningScore < 68 || scoreGap < requiredGap) {
      direction = TradeDirection.wait;
    } else if (bullishScore > bearishScore) {
      direction = TradeDirection.buy;
    } else if (bearishScore > bullishScore) {
      direction = TradeDirection.sell;
    } else {
      direction = TradeDirection.wait;
    }

    // Confidence reflects both setup strength and directional agreement.
    // V3 confidence combines absolute strength and directional agreement.
    // This remains a setup-strength score until historical calibration
    // converts it into a measured win probability.
    final agreementBonus = min(scoreGap * 0.15, 8.0);

    final conflictPenalty = scoreGap < 15
        ? 12.0
        : scoreGap < 25
            ? 5.0
            : 0.0;

    final confidence = (winningScore + agreementBonus - conflictPenalty)
        .clamp(0.0, 100.0)
        .toDouble();

    final isJpy = quote.symbol.contains('JPY');
    final riskDistance = isJpy ? 0.150 : 0.00150;

    final buy = direction == TradeDirection.buy;

    final stopLoss =
        buy ? quote.price - riskDistance : quote.price + riskDistance;

    final takeProfit1 =
        buy ? quote.price + riskDistance : quote.price - riskDistance;

    final takeProfit2 = buy
        ? quote.price + (riskDistance * 2)
        : quote.price - (riskDistance * 2);

    final takeProfit3 = buy
        ? quote.price + (riskDistance * 3)
        : quote.price - (riskDistance * 3);

    String trend;

    if (fast > slow && slow > longTrend) {
      trend = 'STRONG BULLISH';
    } else if (fast < slow && slow < longTrend) {
      trend = 'STRONG BEARISH';
    } else {
      trend = 'MIXED';
    }

    String momentum;

    if (rsi >= 60) {
      momentum = 'STRONG';
    } else if (rsi <= 40) {
      momentum = 'WEAK';
    } else {
      momentum = 'NEUTRAL';
    }

    String setup;

    if (direction == TradeDirection.buy) {
      setup = 'Trend Continuation';
    } else if (direction == TradeDirection.sell) {
      setup = 'Bearish Reversal';
    } else {
      setup = 'No Confirmed Setup';
    }

    return ScanSignal(
      symbol: quote.symbol,
      direction: direction,
      confidence: confidence,
      score: winningScore / 10,
      entry: quote.price,
      stopLoss: stopLoss,
      takeProfit1: takeProfit1,
      takeProfit2: takeProfit2,
      takeProfit3: takeProfit3,
      trend: trend,
      momentum: momentum,
      setup: setup,
      timestamp: quote.timestamp,
    );
  }

  double _ema(List<double> prices, int period) {
    if (prices.isEmpty) return 0;

    if (prices.length < period) {
      return prices.reduce((a, b) => a + b) / prices.length;
    }

    final multiplier = 2 / (period + 1);

    double ema = prices[prices.length - period];

    for (int i = prices.length - period + 1; i < prices.length; i++) {
      ema = ((prices[i] - ema) * multiplier) + ema;
    }

    return ema;
  }

  double _rsi(List<double> prices, int period) {
    if (prices.length < 2) return 50;

    final start = max(1, prices.length - period);

    double gains = 0;
    double losses = 0;

    for (int i = start; i < prices.length; i++) {
      final change = prices[i] - prices[i - 1];

      if (change > 0) {
        gains += change;
      } else {
        losses += change.abs();
      }
    }

    if (gains == 0 && losses == 0) return 50;
    if (losses == 0) return 100;

    final rs = gains / losses;

    return 100 - (100 / (1 + rs));
  }
}
