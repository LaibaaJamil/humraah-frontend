// ignore: uri_does_not_exist
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constants.dart';

class SocketService {
  static IO.Socket? socket;

  static void connect(String userId) {
    try {
      socket = IO.io(
        ApiConstants.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      socket!.connect();
      socket!.onConnect((_) => socket!.emit('join', userId));
    } catch (_) {
      // Socket not critical - app works without it
    }
  }

  static void listenNotifications(Function(dynamic data) onData) {
    socket?.on('notification', (data) => onData(data));
  }

  static void disconnect() {
    socket?.disconnect();
  }
}
