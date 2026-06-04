import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/stats_model.dart';
import '../../core/providers/api_providers.dart';

final statsSummaryProvider = FutureProvider.family((ref, ({DateTime? from, DateTime? to}) params) async {
  final api = ref.watch(apiClientProvider);

  final qp = buildQueryParams(from: params.from, to: params.to);

  final response = await api.dio.get('/api/stats/summary', queryParameters: qp);
  return StatsSummaryResponse.fromJson(response.data);
});


final statsByCategoryProvider = FutureProvider.family((ref, ({DateTime? from, DateTime? to, String? type}) params) async {
  final api = ref.watch(apiClientProvider);

  final qp = buildQueryParams(from: params.from, to: params.to, type: params.type);

  final response = await api.dio.get('/api/stats/by-category', queryParameters: qp);
  return CategoryStatsResponse.fromJson(response.data);
});


final statsMonthlyProvider = FutureProvider.family((ref, int year) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.dio.get('/api/stats/monthly', queryParameters: {
    "year": year,
  });
  return MonthlyStatsResponse.fromJson(response.data);
});

final statsFromProvider = StateProvider<DateTime?>((ref) => null);
final statsToProvider = StateProvider<DateTime?>((ref) => null);
final statsYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});


Map<String, dynamic> buildQueryParams({
  DateTime? from,
  DateTime? to,
  String? type,
}) {
  final qp = <String, dynamic>{};

  String formatDate(DateTime d) => d.toIso8601String().split("T").first;

  if (from != null) qp["from"] = formatDate(from);
  if (to != null) qp["to"] = formatDate(to);
  if (type != null) qp["type"] = type;

  return qp;
}
