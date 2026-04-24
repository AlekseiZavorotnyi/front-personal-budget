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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      date: DateTime.parse(json['date']),
      comment: json['comment'],
      syncStatus: json['syncStatus'],
    );
  }
}
