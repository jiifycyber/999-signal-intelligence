import 'dart:async';
import 'dart:math';

import '../models/forex_quote.dart';

enum MarketMode { demo, live }

class MarketDataService {
  MarketMode mode = MarketMode.demo;

  final Random _random = Random();

  final Map<String, double> _prices = {
    'EUR/USD': 1.16852,
    'GBP/USD': 1.26845,
    'USD/JPY': 155.342,
    'AUD/USD': 0.66435,
    'USD/CHF': 0.91045,
    'USD/CAD': 1.36023,
    'NZD/USD': 0.61025,
    'EUR/GBP': 0.85360,
  };

  final StreamController<List<ForexQuote>> _controller =
      StreamController<List<ForexQuote>>.broadcast();

  Timer? _timer;

  Stream<List<ForexQuote>> get quoteStream => _controller.stream;

  void start() {
    _timer?.cancel();

    _emitQuotes();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _emitQuotes(),
    );
  }

  void setMode(MarketMode newMode) {
    mode = newMode;
    _emitQuotes();
  }

  void _emitQuotes() {
    final now = DateTime.now();

    final quotes = _prices.entries.map((entry) {
      final symbol = entry.key;
      final oldPrice = entry.value;

      final isJpy = symbol.contains('JPY');
      final movement = (_random.nextDouble() - 0.5) * (isJpy ? 0.030 : 0.00030);

      final newPrice = oldPrice + movement;
      _prices[symbol] = newPrice;

      final range = isJpy ? 0.060 : 0.00060;

      return ForexQuote(
        symbol: symbol,
        price: newPrice,
        open: oldPrice,
        high: max(oldPrice, newPrice) + (_random.nextDouble() * range),
        low: min(oldPrice, newPrice) - (_random.nextDouble() * range),
        timestamp: now,
      );
    }).toList();

    if (!_controller.isClosed) {
      _controller.add(quotes);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
