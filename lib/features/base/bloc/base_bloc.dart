import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import 'base_bloc_event.dart';
import 'base_bloc_state.dart';

abstract class BaseBloc<E extends BaseBlocEvent, S extends BaseBlocState>
    extends Bloc<E, S> {
  BaseBloc(super.initialState);

  @override
  void add(E event) {
    if (!isClosed) {
      super.add(event);
    } else {
      debugPrint(
        'Cannot add new event $event because $runtimeType is already closed.',
      );
    }
  }

  Future<void> runBlocCatching({
    required Future<void> Function() action,
    Future<void> Function()? doOnSubscribe,
    Future<void> Function()? doOnSuccess,
    Future<void> Function(Object error, StackTrace stackTrace)? doOnError,
    Future<void> Function()? doOnRetry,
    Future<void> Function()? doOnCompleted,
    int maxRetries = 0,
    bool rethrowError = false,
  }) async {
    assert(maxRetries >= 0, 'maxRetries must be >= 0');

    var remainingRetries = maxRetries;

    await doOnSubscribe?.call();

    try {
      while (true) {
        try {
          await action();
          await doOnSuccess?.call();
          return;
        } catch (error, stackTrace) {
          if (remainingRetries > 0) {
            remainingRetries--;
            await doOnRetry?.call();
            continue;
          }

          await doOnError?.call(error, stackTrace);

          if (rethrowError) {
            Error.throwWithStackTrace(error, stackTrace);
          }

          return;
        }
      }
    } finally {
      await doOnCompleted?.call();
    }
  }
}
