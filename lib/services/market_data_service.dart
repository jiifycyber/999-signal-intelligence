import 'dart:async';
import 'dart:math' show max, min;

import '../models/forex_quote.dart';
import 'twelve_data_stream_service.dart';

enum MarketMode { demo, live }

class MarketDataService {
  MarketMode mode = MarketMode.demo;
  final TwelveDataStreamService _streamService = TwelveDataStreamService();

  StreamSubscription<TwelveDataStreamTick>? _streamSubscription;

  final Map<String, double> _livePrices = {};

  String timeframe = 'M1';

  final List<String> _symbols = const [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'AUD/USD',
    'USD/CHF',
    'USD/CAD',
    'NZD/USD',
    'EUR/GBP',
  ];

  final StreamController<List<ForexQuote>> _controller =
      StreamController<List<ForexQuote>>.broadcast();

  Timer? _timer;

  Stream<List<ForexQuote>> get quoteStream => _controller.stream;

  void start() {
    _timer?.cancel();
    _livePrices.clear();
    _startLiveStream();
  }

  void setMode(MarketMode newMode) {
    mode = newMode;
    _livePrices.clear();
    _startLiveStream();
  }

  void setTimeframe(String newTimeframe) {
    timeframe = newTimeframe;
    _refresh();
  }

  Future<void> _startLiveStream() async {
    await _streamSubscription?.cancel();

    _streamSubscription = _streamService.tickStream.listen((tick) {
      // PURE LIVE DATA:
      // Current and previous LIVE prices come only from Twelve Data.
      final oldPrice = _livePrices[tick.symbol] ?? tick.price;
      _livePrices[tick.symbol] = tick.price;

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
      await _streamService.connect(_symbols);
    } catch (_) {}
  }

  Future<void> _stopLiveStream() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    await _streamService.disconnect();
  }

  Future<void> _refresh() async {
    // LIVE and DEMO both use genuine Twelve Data ticks only.
  }

  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    _streamService.dispose();
    _controller.close();
  }
}
