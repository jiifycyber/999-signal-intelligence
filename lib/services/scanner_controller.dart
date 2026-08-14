import 'dart:async';

import '../models/forex_quote.dart';
import '../models/scan_signal.dart';
import '../ai/agent_duke_scanner_bridge.dart';
import '../ai/agent_duke_master_engine.dart';
import 'market_data_service.dart';
import 'scanner_engine.dart';
import '../intelligence/intelligence_models.dart';
import '../intelligence/intelligence_store.dart';
import '../intelligence/duke_learning_engine.dart';
import '../intelligence/alert_engine.dart';

class ScannerController {
  final IntelligenceStore intelligenceStore = IntelligenceStore();
  late final DukeLearningEngine dukeLearningEngine =
      DukeLearningEngine(intelligenceStore);
  late final AlertEngine alertEngine = AlertEngine(intelligenceStore);

  final MarketDataService marketDataService;
  final ScannerEngine scannerEngine;
  final AgentDukeScannerBridge dukeBridge = AgentDukeScannerBridge();

  ScannerController({
    MarketDataService? marketDataService,
    ScannerEngine? scannerEngine,
  })  : marketDataService = marketDataService ?? MarketDataService(),
        scannerEngine = scannerEngine ?? ScannerEngine();

  final StreamController<List<ScanSignal>> _signalController =
      StreamController<List<ScanSignal>>.broadcast();

  final StreamController<List<ForexQuote>> _quoteController =
      StreamController<List<ForexQuote>>.broadcast();

  StreamSubscription<List<ForexQuote>>? _quoteSubscription;

  final Map<String, ForexQuote> _latestQuotes = {};
  final Map<String, ScanSignal> _latestSignals = {};
  final Map<String, DukeMasterResult> _latestDukeResults = {};

  Stream<List<ScanSignal>> get signalStream => _signalController.stream;
  Map<String, DukeMasterResult> get dukeResults =>
      Map.unmodifiable(_latestDukeResults);
  Stream<List<ForexQuote>> get quoteStream => _quoteController.stream;

  void start() {
    _quoteSubscription?.cancel();

    _quoteSubscription = marketDataService.quoteStream.listen(
      (quotes) {
        for (final quote in quotes) {
          _latestQuotes[quote.symbol] = quote;
        }

        if (!_quoteController.isClosed) {
          _quoteController.add(_latestQuotes.values.toList());
        }

        final updatedSignals = scannerEngine.analyze(quotes);

        for (final signal in updatedSignals) {
          _latestSignals[signal.symbol] = signal;

          final dukeResult = dukeBridge.analyzeSignal(signal);
          _latestDukeResults[signal.symbol] = dukeResult;

          // Persist signal into intelligence memory.
          intelligenceStore.addSignal(
            SignalHistoryRecord(
              symbol: signal.symbol,
              direction: signal.directionText,
              confidence: signal.confidence,
              entry: signal.entry,
              stopLoss: signal.stopLoss,
              tp1: signal.takeProfit1,
              tp2: signal.takeProfit2,
              tp3: signal.takeProfit3,
              timestamp: signal.timestamp,
              setup: signal.setup,
              trend: signal.trend,
              momentum: signal.momentum,
            ),
          );

          // Evaluate all active alert rules.
          alertEngine.evaluate(
            symbol: signal.symbol,
            direction: signal.directionText,
            confidence: signal.confidence,
            dukeApproved: dukeResult.tradeApproved,
          );

          // Keep Duke's learning model hot as new data arrives.
          dukeLearningEngine.analyze();
        }

        final mergedSignals = _latestSignals.values.toList()
          ..sort(
            (a, b) => b.confidence.compareTo(a.confidence),
          );

        if (!_signalController.isClosed) {
          _signalController.add(mergedSignals);
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
    _quoteController.close();
  }
}
