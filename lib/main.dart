import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/injection.dart' as di;
import 'core/storage/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  await di.initDependencies();

  runApp(const ETrackApp());
}
