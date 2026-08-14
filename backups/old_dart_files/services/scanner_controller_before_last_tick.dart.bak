import 'dart:async';

import '../models/forex_quote.dart';
import '../models/scan_signal.dart';
import 'market_data_service.dart';
import 'scanner_engine.dart';

class ScannerController {
  final MarketDataService marketDataService;
  final ScannerEngine scannerEngine;

  ScannerController({
    MarketDataService? marketDataService,
    ScannerEngine? scannerEngine,
  })  : marketDataService = marketDataService ?? MarketDataService(),
        scannerEngine = scannerEngine ?? ScannerEngine();

  final StreamController<List<ScanSignal>> _signalController =
      StreamController<List<ScanSignal>>.broadcast();

  StreamSubscription<List<ForexQuote>>? _quoteSubscription;

  Stream<List<ScanSignal>> get signalStream => _signalController.stream;

  void start() {
    _quoteSubscription?.cancel();

    _quoteSubscription = marketDataService.quoteStream.listen(
      (quotes) {
        final signals = scannerEngine.analyze(quotes);

        if (!_signalController.isClosed) {
          _signalController.add(signals);
        }
      },
    );

    marketDataService.start();
  }

  void setDemoMode() {
    marketDataService.setMode(MarketMode.demo);
  }

  void setLiveMode() {
    marketDataService.setMode(MarketMode.live);
  }

  void dispose() {
    _quoteSubscription?.cancel();
    marketDataService.dispose();
    _signalController.close();
  }
}
