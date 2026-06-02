import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/signalr_service.dart';
import '../../../../router/app_router.dart';
import '../../../../router/app_router.gr.dart';
import '../../../../injection/injection_container.dart';

class GlobalFinderListener extends StatefulWidget {
  const GlobalFinderListener({
    super.key,
    required this.router,
    required this.child,
  });

  final AppRouter router;
  final Widget child;

  @override
  State<GlobalFinderListener> createState() => _GlobalFinderListenerState();
}

class _GlobalFinderListenerState extends State<GlobalFinderListener>
    with WidgetsBindingObserver {
  StreamSubscription<Map<String, dynamic>>? _subscription;
  String? _lastOpenedRequestId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = sl<SignalRService>().dataChangeStream.listen(_handleEvent);
  }

  void _handleEvent(Map<String, dynamic> payload) {
    final type = payload['_type']?.toString().toLowerCase();
    if (type != 'finder') return;

    final event = payload['_event']?.toString().toLowerCase() ?? '';
    final isIncomingRequest =
        event == 'finder.requested' || event == 'onfinderrequested';
    if (!isIncomingRequest) return;

    final requestId = _readString(payload, const [
      'requestId',
      'RequestId',
      'id',
      'Id',
    ]);
    if (requestId == null || requestId == _lastOpenedRequestId) return;

    _lastOpenedRequestId = requestId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.router.push(FinderIncomingRequestRoute(requestId: requestId));
    });
  }

  String? _readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<SignalRService>().init();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
