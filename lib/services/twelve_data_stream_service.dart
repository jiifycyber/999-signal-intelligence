import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class TwelveDataStreamTick {
  final String symbol;
  final double price;
  final DateTime timestamp;

  const TwelveDataStreamTick({
    required this.symbol,
    required this.price,
    required this.timestamp,
  });
}

class TwelveDataStreamService {
  static const String _apiKey = String.fromEnvironment('TWELVE_DATA_API_KEY');

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final StreamController<TwelveDataStreamTick> _controller =
      StreamController<TwelveDataStreamTick>.broadcast();

  Stream<TwelveDataStreamTick> get tickStream => _controller.stream;

  bool get isConnected => _channel != null;

  Future<void> connect(List<String> symbols) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'TWELVE_DATA_API_KEY missing. '
        'Run Flutter with --dart-define=TWELVE_DATA_API_KEY=YOUR_KEY',
      );
    }

    await disconnect();

    final uri = Uri.parse(
      'wss://ws.twelvedata.com/v1/quotes/price?apikey=$_apiKey',
    );

    _channel = WebSocketChannel.connect(uri);

    await _channel!.ready;

    _channel!.sink.add(
      jsonEncode({
        'action': 'subscribe',
        'params': {
          'symbols': symbols.join(','),
        },
      }),
    );

    _subscription = _channel!.stream.listen(
      _handleMessage,
      onError: (_) {},
      onDone: () {
        _channel = null;
      },
    );
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);

      if (data is! Map<String, dynamic>) return;
      if (data['event'] != 'price') return;

      final symbol = '${data['symbol']}';
      final price = double.tryParse('${data['price']}');

      if (symbol.isEmpty || price == null) return;

      final timestampRaw = data['timestamp'];

      DateTime timestamp = DateTime.now();

      if (timestampRaw is num) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
          (timestampRaw.toDouble() * 1000).round(),
        );
      }

      if (!_controller.isClosed) {
        _controller.add(
          TwelveDataStreamTick(
            symbol: symbol,
            price: price,
            timestamp: timestamp,
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;

    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }
}
