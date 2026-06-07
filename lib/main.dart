import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/services/local_budget_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  try {
    await LocalBudgetCache.initialize();
  } catch (e) {
    print('Error initializing cache: $e');
  }

  runApp(const ProviderScope(child: App()));
}
