import 'dart:async';

import 'package:flutter/material.dart';

import 'models/scan_signal.dart';
import 'services/scanner_controller.dart';
import 'services/market_data_service.dart';

void main() {
  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '999 Signal Intelligence 2.0',
      theme: ThemeData.dark(),
      home: const NexusDashboard(),
    );
  }
}

class NexusDashboard extends StatefulWidget {
  const NexusDashboard({super.key});

  @override
  State<NexusDashboard> createState() => _NexusDashboardState();
}

class _NexusDashboardState extends State<NexusDashboard> {
  late final ScannerController scannerController;
  StreamSubscription<List<ScanSignal>>? signalSubscription;
  StreamSubscription? quoteSubscription;

  List<ScanSignal> liveSignals = [];
  final Map<String, double> latestPrices = {};
  bool scannerConnected = false;
  MarketMode marketMode = MarketMode.demo;

  String selectedModule = 'AI Opportunity Scan';
  String selectedPair = 'EURUSD';
  String selectedTimeframe = 'M1';
  bool strictMode = true;
  bool autoUpdate = true;
  bool watchlisted = false;

  double minProbability = 55;
  double minRiskReward = 1.0;

  List<ScanSignal> get filteredSignals {
    final threshold = strictMode
        ? (minProbability < 75 ? 75.0 : minProbability)
        : minProbability;

    return liveSignals
        .where((signal) => signal.confidence >= threshold)
        .toList()
      ..sort(
        (a, b) => b.confidence.compareTo(a.confidence),
      );
  }

  @override
  void initState() {
    super.initState();

    scannerController = ScannerController();

    signalSubscription = scannerController.signalStream.listen((signals) {
      if (!mounted) return;

      if (!autoUpdate) return;

      setState(() {
        liveSignals = signals;
        scannerConnected = true;
      });
    });

    quoteSubscription = scannerController.quoteStream.listen((quotes) {
      if (!mounted) return;

      setState(() {
        for (final quote in quotes) {
          latestPrices[quote.symbol.replaceAll('/', '')] = quote.price;
        }
      });
    });

    scannerController.start();
  }

  @override
  void dispose() {
    signalSubscription?.cancel();
    quoteSubscription?.cancel();
    scannerController.dispose();
    super.dispose();
  }

  void switchToLive() {
    scannerController.marketDataService.setTimeframe(selectedTimeframe);
    scannerController.setLiveMode();

    setState(() {
      marketMode = MarketMode.live;
      scannerConnected = false;
    });

    message('LIVE mode • Twelve Data • $selectedTimeframe');
  }

  void switchToDemo() {
    scannerController.setDemoMode();

    setState(() {
      marketMode = MarketMode.demo;
      scannerConnected = false;
    });

    message('DEMO mode • Simulator • $selectedTimeframe');
  }

  void message(String text) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(milliseconds: 900),
        ),
      );
  }

  Future<void> openTimeframeSelector() async {
    const timeframes = [
      'M1',
      'M5',
      'M15',
      'M30',
      'M45',
      'H1',
      'H2',
      'H4',
      'H8',
      'D1',
      'W1',
      'MN1',
    ];

    final choice = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        backgroundColor: const Color(0xFF081525),
        title: Text(
          'Analysis Timeframe • Current: $selectedTimeframe',
        ),
        children: [
          for (final timeframe in timeframes)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, timeframe),
              child: Row(
                children: [
                  SizedBox(
                    width: 55,
                    child: Text(
                      timeframe,
                      style: TextStyle(
                        color: timeframe == selectedTimeframe
                            ? Colors.cyanAccent
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (timeframe == 'M1')
                    const Text(
                      'PRIMARY',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );

    if (choice != null) {
      setState(() {
        selectedTimeframe = choice;
      });

      scannerController.marketDataService.setTimeframe(choice);

      message('Scanner timeframe changed to $choice');
    }
  }

  void openPanel(String title) {
    setState(() => selectedModule = title);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF081525),
        title: Text(title),
        content: Text(
          '$title module activated.\n\n'
          'This control is now connected to the Flutter interface.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget hit({
    required double left,
    required double top,
    required double width,
    required double height,
    required VoidCallback onTap,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.cyanAccent.withOpacity(.18),
          hoverColor: Colors.cyanAccent.withOpacity(.06),
        ),
      ),
    );
  }

  double? currentPriceFor(String symbol) {
    final normalized = symbol.replaceAll('/', '');
    return latestPrices[normalized];
  }

  String currentPriceText() {
    final price = currentPriceFor(selectedPair);

    if (price == null) {
      return '--';
    }

    final decimals = selectedPair.contains('JPY') ? 3 : 5;
    return price.toStringAsFixed(decimals);
  }

  ScanSignal? signalFor(String symbol) {
    final normalized = symbol.replaceAll('/', '');

    for (final signal in liveSignals) {
      if (signal.symbol.replaceAll('/', '') == normalized) {
        return signal;
      }
    }

    return null;
  }

  void showSignalDetails(String symbol) {
    final signal = signalFor(symbol);

    if (signal == null) {
      message('$symbol signal is still loading');
      return;
    }

    final decimals = symbol.contains('JPY') ? 3 : 5;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF07131F),
        title: Text(
          '$symbol  •  ${signal.directionText}',
          style: TextStyle(
            color: signal.direction == TradeDirection.buy
                ? Colors.greenAccent
                : signal.direction == TradeDirection.sell
                    ? Colors.redAccent
                    : Colors.orangeAccent,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Setup Score: ${signal.confidence.toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 8),
              Text('Trend: ${signal.trend}'),
              Text('Momentum: ${signal.momentum}'),
              Text('Setup: ${signal.setup}'),
              const Divider(),
              Text(
                'Entry: ${signal.entry.toStringAsFixed(decimals)}',
              ),
              Text(
                'Stop Loss: ${signal.stopLoss.toStringAsFixed(decimals)}',
              ),
              Text(
                'TP1: ${signal.takeProfit1.toStringAsFixed(decimals)}',
              ),
              Text(
                'TP2: ${signal.takeProfit2.toStringAsFixed(decimals)}',
              ),
              Text(
                'TP3: ${signal.takeProfit3.toStringAsFixed(decimals)}',
              ),
              const SizedBox(height: 10),
              Text(
                scannerConnected
                    ? 'Scanner engine: CONNECTED'
                    : 'Scanner engine: CONNECTING...',
                style: TextStyle(
                  color: scannerConnected
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const designWidth = 1536.0;
    const designHeight = 1024.0;

    return Scaffold(
      backgroundColor: const Color(0xFF020811),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / designWidth;
          final scaleY = constraints.maxHeight / designHeight;
          final scale = scaleX < scaleY ? scaleX : scaleY;

          return Center(
            child: SizedBox(
              width: designWidth * scale,
              height: designHeight * scale,
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: designWidth,
                  height: designHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/nexus_fx_scanner_reference.png',
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                      ),

                      // 999 SIGNAL INTELLIGENCE 2.0 BRANDING
                      Positioned(
                        left: 18,
                        top: 10,
                        width: 325,
                        height: 42,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF07131F),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '999 SIGNAL INTELLIGENCE 2.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .7,
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 560,
                        bottom: 6,
                        width: 420,
                        height: 28,
                        child: Container(
                          alignment: Alignment.center,
                          color: const Color(0xFF07131F),
                          child: const Text(
                            '999 SIGNAL INTELLIGENCE 2.0',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ),

                      // TOP AI MODULES
                      hit(
                        left: 65,
                        top: 52,
                        width: 185,
                        height: 50,
                        onTap: () => openPanel('AI Opportunity Scan'),
                      ),
                      hit(
                        left: 262,
                        top: 52,
                        width: 196,
                        height: 50,
                        onTap: () => openPanel('Multi-Timeframe Alignment'),
                      ),
                      hit(
                        left: 470,
                        top: 52,
                        width: 195,
                        height: 50,
                        onTap: () => openPanel('Order Flow & Liquidity'),
                      ),
                      hit(
                        left: 680,
                        top: 52,
                        width: 184,
                        height: 50,
                        onTap: () => openPanel('Sentiment Engine'),
                      ),
                      hit(
                        left: 877,
                        top: 52,
                        width: 190,
                        height: 50,
                        onTap: () => openPanel('Macro & Fundamental'),
                      ),
                      hit(
                        left: 1078,
                        top: 52,
                        width: 190,
                        height: 50,
                        onTap: () => openPanel('Volatility & Risk'),
                      ),
                      hit(
                        left: 1280,
                        top: 52,
                        width: 185,
                        height: 50,
                        onTap: () => openPanel('Trade Automation'),
                      ),

                      // MARKET HEATMAP TIMEFRAME SELECTOR
                      Positioned(
                        left: 145,
                        top: 166,
                        width: 164,
                        height: 27,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFF081727).withOpacity(.94),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(.55),
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'TIMEFRAME  $selectedTimeframe  ▼',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      hit(
                        left: 145,
                        top: 166,
                        width: 164,
                        height: 27,
                        onTap: openTimeframeSelector,
                      ),

                      // SCANNER ASSET TABS
                      hit(
                        left: 301,
                        top: 214,
                        width: 69,
                        height: 30,
                        onTap: () => message('All Pairs selected'),
                      ),
                      hit(
                        left: 374,
                        top: 214,
                        width: 65,
                        height: 30,
                        onTap: () => message('Majors selected'),
                      ),
                      hit(
                        left: 442,
                        top: 214,
                        width: 60,
                        height: 30,
                        onTap: () => message('Minors selected'),
                      ),
                      hit(
                        left: 505,
                        top: 214,
                        width: 63,
                        height: 30,
                        onTap: () => message('Exotics selected'),
                      ),
                      hit(
                        left: 571,
                        top: 214,
                        width: 80,
                        height: 30,
                        onTap: () => message('XAU/XAG selected'),
                      ),
                      hit(
                        left: 654,
                        top: 214,
                        width: 65,
                        height: 30,
                        onTap: () => message('Custom selected'),
                      ),

                      // MIN PROBABILITY
                      hit(
                        left: 801,
                        top: 214,
                        width: 111,
                        height: 30,
                        onTap: () async {
                          final choice = await showDialog<double>(
                            context: context,
                            builder: (_) => SimpleDialog(
                              backgroundColor: const Color(0xFF081525),
                              title: const Text(
                                'Minimum Technical Score',
                              ),
                              children: [
                                for (final value in [
                                  50.0,
                                  55.0,
                                  60.0,
                                  65.0,
                                  70.0,
                                  75.0,
                                  80.0,
                                  85.0,
                                  90.0,
                                  95.0,
                                ])
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, value),
                                    child: Text(
                                      '${value.toStringAsFixed(0)}%',
                                    ),
                                  ),
                              ],
                            ),
                          );

                          if (choice != null) {
                            setState(() {
                              minProbability = choice;
                            });

                            message(
                              'Minimum probability set to '
                              '${minProbability.toStringAsFixed(0)}% '
                              '(${filteredSignals.length} setups)',
                            );
                          }
                        },
                      ),

                      // R:R FILTER
                      hit(
                        left: 919,
                        top: 214,
                        width: 92,
                        height: 30,
                        onTap: () async {
                          final choice = await showDialog<double>(
                            context: context,
                            builder: (_) => SimpleDialog(
                              backgroundColor: const Color(0xFF081525),
                              title: const Text('Minimum Risk / Reward'),
                              children: [
                                for (final value in [
                                  1.0,
                                  1.25,
                                  1.5,
                                  1.75,
                                  2.0,
                                  2.5,
                                  3.0,
                                ])
                                  SimpleDialogOption(
                                    onPressed: () =>
                                        Navigator.pop(context, value),
                                    child: Text(
                                      '1 : ${value.toStringAsFixed(2)}',
                                    ),
                                  ),
                              ],
                            ),
                          );

                          if (choice != null) {
                            setState(() {
                              minRiskReward = choice;
                            });

                            message(
                              'Minimum R:R set to '
                              '1:${minRiskReward.toStringAsFixed(2)}',
                            );
                          }
                        },
                      ),

                      // STRICT MODE
                      hit(
                        left: 1019,
                        top: 214,
                        width: 93,
                        height: 30,
                        onTap: () {
                          setState(() => strictMode = !strictMode);
                          message(
                            'AI Strict Mode ${strictMode ? "ON" : "OFF"}',
                          );
                        },
                      ),

                      // LIVE STRICT MODE INDICATOR
                      Positioned(
                        left: 1080,
                        top: 220,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: strictMode
                                ? const Color(0xFF00C878)
                                : const Color(0xFF7A2632),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            strictMode ? 'ON' : 'OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // AUTO UPDATE
                      hit(
                        left: 1122,
                        top: 214,
                        width: 121,
                        height: 30,
                        onTap: () {
                          setState(() => autoUpdate = !autoUpdate);
                          message(
                            'Auto Update ${autoUpdate ? "ON" : "OFF"}',
                          );
                        },
                      ),

                      // LIVE AUTO UPDATE INDICATOR
                      Positioned(
                        left: 1204,
                        top: 220,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: autoUpdate
                                ? const Color(0xFF00C878)
                                : const Color(0xFF7A2632),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            autoUpdate ? 'ON' : 'OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // PAIR DEEP SCANNER
                      hit(
                        left: 1318,
                        top: 151,
                        width: 100,
                        height: 34,
                        onTap: () {
                          message('Pair selector opened');
                        },
                      ),

                      hit(
                        left: 1420,
                        top: 151,
                        width: 43,
                        height: 34,
                        onTap: () {
                          setState(() {
                            selectedTimeframe =
                                selectedTimeframe == 'H1' ? 'H4' : 'H1';
                          });
                          message(
                            'Deep Scanner: $selectedTimeframe',
                          );
                        },
                      ),

                      // WATCHLIST
                      hit(
                        left: 1326,
                        top: 783,
                        width: 170,
                        height: 34,
                        onTap: () {
                          setState(() => watchlisted = !watchlisted);
                          message(
                            watchlisted
                                ? '$selectedPair added to watchlist'
                                : '$selectedPair removed from watchlist',
                          );
                        },
                      ),

                      // SCANNER ROWS
                      for (int i = 0; i < 8; i++)
                        hit(
                          left: 297,
                          top: 294 + (i * 47),
                          width: 998,
                          height: 44,
                          onTap: () {
                            const pairs = [
                              'XAUUSD',
                              'EURUSD',
                              'GBPJPY',
                              'AUDUSD',
                              'USDCHF',
                              'USDCAD',
                              'NZDUSD',
                              'EURGBP',
                            ];

                            setState(() => selectedPair = pairs[i]);
                            showSignalDetails(pairs[i]);
                          },
                        ),

                      // LIVE / DEMO CONTROL
                      Positioned(
                        right: 18,
                        top: 14,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF07131F).withOpacity(.96),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(.45),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: switchToLive,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: marketMode == MarketMode.live
                                        ? const Color(0xFF00C878)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: switchToDemo,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: marketMode == MarketMode.demo
                                        ? const Color(0xFF3B4A5A)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    'DEMO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // CURRENT PRICE DISPLAY
                      Positioned(
                        right: 18,
                        top: 54,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF07131F).withOpacity(.96),
                            border: Border.all(
                              color: marketMode == MarketMode.live
                                  ? Colors.greenAccent.withOpacity(.55)
                                  : Colors.orangeAccent.withOpacity(.55),
                            ),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${marketMode == MarketMode.live ? "TWELVE DATA" : "DEMO"}  '
                            '$selectedPair  '
                            '${currentPriceText()}  '
                            '$selectedTimeframe',
                            style: TextStyle(
                              color: marketMode == MarketMode.live
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // LEFT SIDE PANELS
                      // MARKET HEATMAP HEADER
                      hit(
                        left: 8,
                        top: 118,
                        width: 282,
                        height: 42,
                        onTap: () => openPanel('Market Heatmap'),
                      ),

                      // MARKET HEATMAP BODY
                      // Leaves the timeframe selector uncovered.
                      hit(
                        left: 8,
                        top: 198,
                        width: 282,
                        height: 255,
                        onTap: () => openPanel('Market Heatmap'),
                      ),
                      hit(
                        left: 8,
                        top: 457,
                        width: 282,
                        height: 150,
                        onTap: () => openPanel('Global Sessions'),
                      ),
                      hit(
                        left: 8,
                        top: 611,
                        width: 282,
                        height: 185,
                        onTap: () => openPanel('News & Macro Impact'),
                      ),

                      // RIGHT SIDE PANELS
                      hit(
                        left: 1304,
                        top: 118,
                        width: 220,
                        height: 555,
                        onTap: () => openPanel('Pair Deep Scanner'),
                      ),
                      hit(
                        left: 1304,
                        top: 680,
                        width: 220,
                        height: 135,
                        onTap: () => openPanel('Trade Plan AI'),
                      ),

                      // SMART MONEY
                      hit(
                        left: 10,
                        top: 810,
                        width: 280,
                        height: 185,
                        onTap: () => openPanel('Smart Money Tracker'),
                      ),

                      // AI PREDICTION
                      hit(
                        left: 301,
                        top: 807,
                        width: 548,
                        height: 188,
                        onTap: () => openPanel('AI Prediction Engine'),
                      ),

                      // MARKET REGIME
                      hit(
                        left: 859,
                        top: 807,
                        width: 225,
                        height: 188,
                        onTap: () => openPanel('Market Regime Detection'),
                      ),

                      // RISK POSITION SIZING
                      hit(
                        left: 1090,
                        top: 807,
                        width: 208,
                        height: 188,
                        onTap: () => openPanel('Risk & Position Sizing'),
                      ),

                      // ALERTS
                      hit(
                        left: 1305,
                        top: 825,
                        width: 218,
                        height: 167,
                        onTap: () => openPanel('Alerts & Automation'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
