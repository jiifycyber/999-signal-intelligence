import 'dart:async';

import 'package:flutter/material.dart';

import 'models/scan_signal.dart';
import 'services/scanner_controller.dart';

void main() {
  runApp(const NexusApp());
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXUS FX Scanner Pro',
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

  List<ScanSignal> liveSignals = [];
  bool scannerConnected = false;

  String selectedModule = 'AI Opportunity Scan';
  String selectedPair = 'EURUSD';
  String selectedTimeframe = 'H1';
  bool strictMode = true;
  bool autoUpdate = true;
  bool watchlisted = false;

  @override
  void initState() {
    super.initState();

    scannerController = ScannerController();

    signalSubscription = scannerController.signalStream.listen((signals) {
      if (!mounted) return;

      setState(() {
        liveSignals = signals;
        scannerConnected = true;
      });
    });

    scannerController.start();
  }

  @override
  void dispose() {
    signalSubscription?.cancel();
    scannerController.dispose();
    super.dispose();
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
                'Confidence: ${signal.confidence.toStringAsFixed(0)}%',
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

                      // MARKET HEATMAP TIMEFRAMES
                      hit(
                        left: 145,
                        top: 166,
                        width: 38,
                        height: 26,
                        onTap: () {
                          setState(() => selectedTimeframe = 'M15');
                          message('Timeframe: M15');
                        },
                      ),
                      hit(
                        left: 187,
                        top: 166,
                        width: 38,
                        height: 26,
                        onTap: () {
                          setState(() => selectedTimeframe = 'H1');
                          message('Timeframe: H1');
                        },
                      ),
                      hit(
                        left: 229,
                        top: 166,
                        width: 38,
                        height: 26,
                        onTap: () {
                          setState(() => selectedTimeframe = 'H4');
                          message('Timeframe: H4');
                        },
                      ),
                      hit(
                        left: 271,
                        top: 166,
                        width: 38,
                        height: 26,
                        onTap: () {
                          setState(() => selectedTimeframe = 'D1');
                          message('Timeframe: D1');
                        },
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
                        onTap: () => message(
                          'Minimum probability filter opened',
                        ),
                      ),

                      // R:R FILTER
                      hit(
                        left: 919,
                        top: 214,
                        width: 92,
                        height: 30,
                        onTap: () => message('Risk/Reward filter opened'),
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

                      // LEFT SIDE PANELS
                      hit(
                        left: 8,
                        top: 118,
                        width: 282,
                        height: 335,
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
