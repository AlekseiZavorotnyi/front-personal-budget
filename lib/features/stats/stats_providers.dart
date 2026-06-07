import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/stats_model.dart';
import '../../core/models/transaction_model.dart';
import '../../core/providers/api_providers.dart';
import '../../core/services/local_budget_cache.dart';

final statsSummaryProvider =
    FutureProvider.family((ref, ({DateTime? from, DateTime? to}) params) async {
      final isLoggedIn = ref.watch(isLoggedInProvider);

      if (!isLoggedIn) {
        return StatsSummaryResponse(
          period: StatsPeriod(from: null, to: null),
          totalIncome: 0,
          totalExpenses: 0,
          balance: 0,
          transactionCount: 0,
        );
      }
  final api = ref.watch(apiClientProvider);

  final qp = buildQueryParams(from: params.from, to: params.to);

  try {
    final response = await api.dio.get(
      '/api/stats/summary',
      queryParameters: qp,
    );
    return StatsSummaryResponse.fromJson(response.data);
  } on DioException catch (error) {
    if (error.response != null) {
      rethrow;
    }

    return _buildLocalSummary(params.from, params.to);
  }
});

final statsByCategoryProvider = FutureProvider.family((
  ref,
  ({DateTime? from, DateTime? to, String? type}) params,
) async {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  if (!isLoggedIn) {
    return CategoryStatsResponse(
      period: StatsPeriod(from: null, to: null),
      type: params.type,
      total: 0,
      items: [],
    );
  }
  final api = ref.watch(apiClientProvider);

  final qp = buildQueryParams(
    from: params.from,
    to: params.to,
    type: params.type,
  );

  try {
    final response = await api.dio.get(
      '/api/stats/by-category',
      queryParameters: qp,
    );
    return CategoryStatsResponse.fromJson(response.data);
  } on DioException catch (error) {
    if (error.response != null) {
      rethrow;
    }

    return _buildLocalCategoryStats(params.from, params.to, params.type);
  }
});

final statsMonthlyProvider = FutureProvider.family((ref, int year) async {
  final isLoggedIn = ref.watch(isLoggedInProvider);

  if (!isLoggedIn) {
    return MonthlyStatsResponse(
      year: year,
      months: [],
    );
  }
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('/api/stats/monthly', queryParameters: {
      "year": year,
    });
    return MonthlyStatsResponse.fromJson(response.data);
  } on DioException catch (error) {
    if (error.response != null) {
      rethrow;
    }

    return _buildLocalMonthlyStats(year);
  }
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

Future<StatsSummaryResponse> _buildLocalSummary(
  DateTime? from,
  DateTime? to,
) async {
  final transactions = _filterByPeriod(
    await LocalBudgetCache.readAllTransactions(),
    from,
    to,
  );

  final totalIncome = transactions
      .where((transaction) => transaction.type == 'income')
      .fold<double>(0, (sum, transaction) => sum + transaction.amount);
  final totalExpenses = transactions
      .where((transaction) => transaction.type == 'expense')
      .fold<double>(0, (sum, transaction) => sum + transaction.amount);

  return StatsSummaryResponse(
    period: StatsPeriod(
      from: from == null ? null : _formatDate(from),
      to: to == null ? null : _formatDate(to),
    ),
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    balance: totalIncome - totalExpenses,
    transactionCount: transactions.length,
  );
}

Future<CategoryStatsResponse> _buildLocalCategoryStats(
  DateTime? from,
  DateTime? to,
  String? type,
) async {
  final categories = await LocalBudgetCache.readCachedCategories();
  final categoryNames = {
    for (final category in categories) category.id: category.name,
  };
  final transactions = _filterByPeriod(
    await LocalBudgetCache.readAllTransactions(),
    from,
    to,
  ).where((transaction) {
    return type == null || transaction.type == type;
  }).toList();

  final byCategory = <String?, _CategoryAccumulator>{};

  for (final transaction in transactions) {
    final categoryId = transaction.categoryId;
    final accumulator = byCategory.putIfAbsent(
      categoryId,
      () => _CategoryAccumulator(
        transaction.categoryName ?? categoryNames[categoryId],
      ),
    );

    accumulator.total += transaction.amount;
    accumulator.transactionCount++;
  }

  final total = byCategory.values.fold<double>(
    0,
    (sum, item) => sum + item.total,
  );

  final items = byCategory.entries.map((entry) {
    final accumulator = entry.value;
    return CategoryStatsItem(
      categoryId: entry.key,
      categoryName: accumulator.categoryName,
      total: accumulator.total,
      transactionCount: accumulator.transactionCount,
      percentage: total > 0 ? accumulator.total / total * 100 : 0,
    );
  }).toList()
    ..sort((a, b) => b.total.compareTo(a.total));

  return CategoryStatsResponse(
    period: StatsPeriod(
      from: from == null ? null : _formatDate(from),
      to: to == null ? null : _formatDate(to),
    ),
    type: type,
    total: total,
    items: items,
  );
}

Future<MonthlyStatsResponse> _buildLocalMonthlyStats(int year) async {
  final totals = List.generate(12, (_) => [0.0, 0.0]);
  final transactions = await LocalBudgetCache.readAllTransactions();

  for (final transaction in transactions) {
    if (transaction.date.year != year) {
      continue;
    }

    final monthIndex = transaction.date.month - 1;
    if (transaction.type == 'income') {
      totals[monthIndex][0] += transaction.amount;
    } else {
      totals[monthIndex][1] += transaction.amount;
    }
  }

  final monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return MonthlyStatsResponse(
    year: year,
    months: List.generate(12, (index) {
      final totalIncome = totals[index][0];
      final totalExpenses = totals[index][1];

      return MonthlyStatsItem(
        month: index + 1,
        label: monthNames[index],
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        balance: totalIncome - totalExpenses,
      );
    }),
  );
}

List<TransactionModel> _filterByPeriod(
  List<TransactionModel> transactions,
  DateTime? from,
  DateTime? to,
) {
  final fromDate = from == null ? null : _dateOnly(from);
  final toDate = to == null ? null : _dateOnly(to);

  return transactions.where((transaction) {
    final date = _dateOnly(transaction.date);

    if (fromDate != null && date.isBefore(fromDate)) {
      return false;
    }

    if (toDate != null && date.isAfter(toDate)) {
      return false;
    }

    return true;
  }).toList();
}

String _formatDate(DateTime value) {
  return value.toIso8601String().split('T').first;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

class _CategoryAccumulator {
  _CategoryAccumulator(this.categoryName);

  final String? categoryName;
  double total = 0;
  int transactionCount = 0;
}
