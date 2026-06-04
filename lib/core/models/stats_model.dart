class StatsSummaryResponse {
  final StatsPeriod period;
  final double totalIncome;
  final double totalExpenses;
  final double balance;
  final int transactionCount;

  StatsSummaryResponse({
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
    required this.transactionCount,
  });

  factory StatsSummaryResponse.fromJson(Map<String, dynamic> json) {
    return StatsSummaryResponse(
      period: StatsPeriod.fromJson(json['period']),
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      transactionCount: json['transactionCount'],
    );
  }
}

class StatsPeriod {
  final String? from;
  final String? to;

  StatsPeriod({this.from, this.to});

  factory StatsPeriod.fromJson(Map<String, dynamic> json) {
    return StatsPeriod(
      from: json['from'],
      to: json['to'],
    );
  }
}

class CategoryStatsResponse {
  final StatsPeriod period;
  final String? type;
  final double total;
  final List<CategoryStatsItem> items;

  CategoryStatsResponse({
    required this.period,
    required this.type,
    required this.total,
    required this.items,
  });

  factory CategoryStatsResponse.fromJson(Map<String, dynamic> json) {
    return CategoryStatsResponse(
      period: StatsPeriod.fromJson(json['period']),
      type: json['type'],
      total: (json['total'] as num).toDouble(),
      items: (json['items'] as List)
          .map((e) => CategoryStatsItem.fromJson(e))
          .toList(),
    );
  }
}

class CategoryStatsItem {
  final String? categoryId;
  final String? categoryName;
  final double total;
  final int transactionCount;
  final double percentage;

  CategoryStatsItem({
    required this.categoryId,
    required this.categoryName,
    required this.total,
    required this.transactionCount,
    required this.percentage,
  });

  factory CategoryStatsItem.fromJson(Map<String, dynamic> json) {
    return CategoryStatsItem(
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      total: (json['total'] as num).toDouble(),
      transactionCount: json['transactionCount'],
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class MonthlyStatsResponse {
  final int year;
  final List<MonthlyStatsItem> months;

  MonthlyStatsResponse({
    required this.year,
    required this.months,
  });

  factory MonthlyStatsResponse.fromJson(Map<String, dynamic> json) {
    return MonthlyStatsResponse(
      year: json['year'],
      months: (json['months'] as List)
          .map((e) => MonthlyStatsItem.fromJson(e))
          .toList(),
    );
  }
}

class MonthlyStatsItem {
  final int month;
  final String label;
  final double totalIncome;
  final double totalExpenses;
  final double balance;

  MonthlyStatsItem({
    required this.month,
    required this.label,
    required this.totalIncome,
    required this.totalExpenses,
    required this.balance,
  });

  factory MonthlyStatsItem.fromJson(Map<String, dynamic> json) {
    return MonthlyStatsItem(
      month: json['month'],
      label: json['label'],
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpenses: (json['totalExpenses'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
    );
  }
}
