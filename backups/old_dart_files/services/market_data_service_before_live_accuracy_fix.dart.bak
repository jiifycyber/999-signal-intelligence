import 'dart:async';
import 'dart:math';

import '../models/forex_quote.dart';
import 'twelve_data_service.dart';
import 'twelve_data_stream_service.dart';

enum MarketMode { demo, live }

class MarketDataService {
  MarketMode mode = MarketMode.demo;

  final Random _random = Random();
  final TwelveDataService _twelveData = TwelveDataService();
  final TwelveDataStreamService _streamService = TwelveDataStreamService();

  StreamSubscription<TwelveDataStreamTick>? _streamSubscription;

  final Map<String, double> _livePrices = {};

  String timeframe = 'M1';

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

    _refresh();

    _timer = Timer.periodic(
      Duration(seconds: mode == MarketMode.demo ? 1 : 15),
      (_) => _refresh(),
    );
  }

  void setMode(MarketMode newMode) {
    mode = newMode;

    if (mode == MarketMode.live) {
      _startLiveStream();
    } else {
      _stopLiveStream();
    }

    start();
  }

  void setTimeframe(String newTimeframe) {
    timeframe = newTimeframe;
    _refresh();
  }

  Future<void> _startLiveStream() async {
    await _streamSubscription?.cancel();

    _streamSubscription = _streamService.tickStream.listen((tick) {
      _livePrices[tick.symbol] = tick.price;

      final oldPrice = _prices[tick.symbol] ?? tick.price;

      _prices[tick.symbol] = tick.price;

      final quote = ForexQuote(
        symbol: tick.symbol,
        price: tick.price,
        open: oldPrice,
        high: max(oldPrice, tick.price),
        low: min(oldPrice, tick.price),
        timestamp: tick.timestamp,
      );

      if (!_controller.isClosed) {
        _controller.add([quote]);
      }
    });

    try {
      await _streamService.connect(_prices.keys.toList());
    } catch (_) {}
  }

  Future<void> _stopLiveStream() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _streamService.disconnect();
  }

  Future<void> _refresh() async {
    if (mode == MarketMode.demo) {
      _emitDemoQuotes();
    } else {
      await _emitLiveQuotes();
    }
  }

  void _emitDemoQuotes() {
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

  Future<void> _emitLiveQuotes() async {
    final quotes = <ForexQuote>[];

    for (final symbol in _prices.keys) {
      try {
        final quote = await _twelveData.fetchLatest(
          symbol,
          timeframe,
        );

        if (quote != null) {
          quotes.add(quote);
          _prices[symbol] = quote.price;
        }
      } catch (e) {
        // Keep other symbols loading even if one request fails.
      }
    }

    if (quotes.isNotEmpty && !_controller.isClosed) {
      _controller.add(quotes);
    }
  }

  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    _streamService.dispose();
    _controller.close();
  }
}
