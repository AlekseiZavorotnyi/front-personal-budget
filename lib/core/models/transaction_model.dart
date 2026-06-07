class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String? categoryId;
  final String? categoryName;
  final DateTime date;
  final String? comment;
  final String syncStatus;

  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.comment,
    required this.syncStatus,
  });

  factory TransactionModel.fromJson(Map<dynamic, dynamic> json) {
    return TransactionModel(
      id: (json['id'] ?? json['localId']).toString(),
      type: json['type']?.toString() == 'income' ? 'income' : 'expense',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      date: DateTime.parse(json['date']),
      comment: (json['comment'] ?? json['description'] ?? json['title'])
          ?.toString(),
      syncStatus: json['syncStatus']?.toString() ??
          (json['localId'] == null ? 'synced' : 'pending'),
    );
  }
}
