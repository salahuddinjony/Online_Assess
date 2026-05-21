import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initHive();
  await initDependencies();
  runApp(const SpendArcApp());
}

Future<void> _initHive() async {
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
}
