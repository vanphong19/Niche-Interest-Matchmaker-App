import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../core/network/network.dart';

@module
abstract class InjectionModule {
  @lazySingleton
  Dio dio() {
    return NetworkConfig.createDio();
  }
}
