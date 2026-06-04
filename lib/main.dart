import 'package:flutter/material.dart';
import 'app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('offline_transactions');
  runApp(const ProviderScope(child: App()));
}