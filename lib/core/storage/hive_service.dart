import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Central access point for Hive. Custom object adapters (Expense, TaskItem,
/// Category) will be registered here when Hive generator is introduced.
abstract final class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map<String, dynamic>>(AppConstants.expensesBox);
    await Hive.openBox<Map<String, dynamic>>(AppConstants.tasksBox);
    await Hive.openBox<Map<String, dynamic>>(AppConstants.pendingSyncBox);
    await Hive.openBox<String>(AppConstants.settingsBox);
  }

  static Box<Map<String, dynamic>> get expensesBox =>
      Hive.box<Map<String, dynamic>>(AppConstants.expensesBox);

  static Box<Map<String, dynamic>> get tasksBox =>
      Hive.box<Map<String, dynamic>>(AppConstants.tasksBox);

  /// Outbox for expenses/tasks created while offline; drained by sync service.
  static Box<Map<String, dynamic>> get pendingSyncBox =>
      Hive.box<Map<String, dynamic>>(AppConstants.pendingSyncBox);

  static Box<String> get settingsBox =>
      Hive.box<String>(AppConstants.settingsBox);

  static Future<void> close() => Hive.close();
}
