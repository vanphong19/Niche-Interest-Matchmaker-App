import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:signalr_netcore/signalr_client.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

@lazySingleton
class SignalRService {
  final FlutterSecureStorage _storage;
  HubConnection? _hubConnection;
  
  final _eventStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStatusStream => _eventStatusController.stream;

  SignalRService(this._storage);

  Future<void> init() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token == null) return;

    final url = '${ApiConstants.baseUrl}/hubs/event';

    _hubConnection = HubConnectionBuilder()
        .withUrl(url, options: HttpConnectionOptions(
          accessTokenFactory: () async => token,
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('OnEventStatusChanged', (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        final data = arguments[0] as Map<String, dynamic>;
        _eventStatusController.add(data);
      }
    });

    try {
      await _hubConnection?.start();
      print('SignalR: Connected');
    } catch (e) {
      print('SignalR: Connection failed: $e');
    }
  }

  Future<void> stop() async {
    await _hubConnection?.stop();
  }
}
