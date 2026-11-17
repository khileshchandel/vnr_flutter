import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Central access point for Hive. Custom object adapters (Expense, TaskItem,
/// Category) will be registered here when Hive generator is introduced.
abstract final class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();
    // Hive deserializes every stored map as `Map<dynamic, dynamic>`. Opening a
    // box as `Box<Map<String, dynamic>>` makes BoxImpl.get cast on read and
    // throw, so map boxes are opened untyped and converted via [stringMap].
    await Hive.openBox(AppConstants.expensesBox);
    await Hive.openBox(AppConstants.tasksBox);
    await Hive.openBox(AppConstants.pendingSyncBox);
    await Hive.openBox<String>(AppConstants.settingsBox);
  }

  static Box get expensesBox => Hive.box(AppConstants.expensesBox);

  static Box get tasksBox => Hive.box(AppConstants.tasksBox);

  /// Outbox for expenses/tasks created while offline; drained by sync service.
  static Box get pendingSyncBox => Hive.box(AppConstants.pendingSyncBox);

  static Box<String> get settingsBox =>
      Hive.box<String>(AppConstants.settingsBox);

  /// Converts a value read from an untyped Hive box into a typed JSON map.
  static Map<String, dynamic> stringMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  static Future<void> close() => Hive.close();
}
