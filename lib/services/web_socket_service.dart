import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final String url;

  WebSocketService({String? url}) : url = url ?? AppConfig.serverUrl;

  Stream<dynamic> get stream => _channel?.stream ?? const Stream.empty();

  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(url));
  }

  void send(Map<String, dynamic> message) {
    _channel?.sink.add(jsonEncode(message));
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
