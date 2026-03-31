import 'package:flutter/material.dart';

import 'app.dart';
import 'injection/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  runApp(const App());
}
